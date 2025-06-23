# frozen_string_literal: true

module RDiff
  class CLI
    include IOUtils

    def initialize
      @options = {}
    end

    def parse(args)
      require 'optionparser'

      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: rdiff [options] BEFORE.rb AFTER.rb'
        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit 0
        end

        opts.on('-o TARGET', '--output-directory', 'Directory to output normalized unparsed files (default temporary)', String) do |dir|
          @options[:output_directory] = dir
        end

        opts.on('--ignore-comments', "Don't process and preserve comments in the unparsed files") do |p|
          @options[:ignore_comments] = p
        end

        opts.on('--check-only', "Report whether there are any changes, but don't calculate them (much faster).") do |c|
          @options[:check_only] = c
        end

        opts.on('--diff-original', 'Show a diff of the original files above the normalized files') do |d|
          @options[:diff_original] = d
        end

        opts.on('--yard [TARGET]', 'Use YARD (optional existing directory, default reparses input files)') do |target|
          @options[:annotation_type] = :yard
          @options[:annotation_target] = target
          @options[:override] = true if target.nil?
        end

        opts.on('--yard-files FILE1,FILE2,...', 'Reparse specific YARD files (choose --yard or this, not both)', Array) do |files|
          @options[:annotation_type] = :yard
          @options[:annotation_target] = files
        end

        opts.on('--rbs [TARGET]', 'Use RBS signatures (default ./sig/)') do |target|
          @options[:annotation_type] = :rbs
          @options[:annotation_target] = target || 'sig'
        end

        opts.on('--gumtree', 'Use gumtree webdiff after default difftastic') do |g|
          @options[:gumtree] = g
        end

        opts.on('--skip-difftastic', 'Skip difftastic text diff') do |d|
          @options[:skip_difftastic] = d
        end
      end

      begin
        files = parser.parse!(args)
        raise ArgumentError, "Expected 2 files but received #{files.size}" if files.size != 2

        types = case @options[:annotation_type]
                when :yard
                  Yard::TypeModel::Builder.yard
                  @options[:annotation_target] ||= files
                  Yard::TypeModel::Builder::IMPLEMENTATION.new(
                    @options[:annotation_target],
                    @options[:annotation_target].is_a?(Array)
                  ).build
                when :rbs
                  Yard::TypeModel::Builder.rbs
                  Yard::TypeModel::Builder::IMPLEMENTATION.new(
                    @options[:annotation_target],
                    false
                  ).build
                end

        processed_asts = files.map do |file|
          contents = File.read(file)
          original_result = Prism.parse(contents)
          ast = original_result.value
          ast = ast.accept(Prism::DesugarCompiler.new)
          ast = ast.accept(AliasingCompiler.new)
          ast = ast.accept(StructuresCompiler.new)
          node_types = TypeVisitor.new(types).visit(ast) unless types.nil?
          ast = ast.accept(ConstantsCompiler.new)
          ast = ast.accept(AlgebraCompiler.new(node_types)) unless types.nil?
          ast = ast.accept(IdentityCompiler.new(node_types)) unless types.nil?
          ast = ast.accept(ConstantsCompiler.new)

          # NOTE: This should be changed once more tooling catches up
          # with Prism. Basically, all structural Ruby diff tools work with
          # whitequark/parser (none with Prism at least), so we have to
          # translate the ASTs we modified using the Prism API. Similarly,
          # there is no rewriter (unparser) for Prism natively. Prism
          # offers translation to parser, but this API seems restricted to
          # the parsing step (i.e., parse with Prism then translate in
          # one go). All this results in the hack below to provide parser
          # ASTs post Prism normalizations and unparsed code to feed to
          # difftastic (or other diff tools). There might be a better way
          # to do this now, but there definitely will be in the near future.
          translator = Prism::Translation::Parser.new(
            parser: Struct.new(:prism_ast, :original_result) do
              def parse(source, **options)
                Struct.new(:value, :comments, :magic_comments, :data_loc, :errors, :warnings, :source).new(
                  prism_ast,
                  original_result.comments,
                  original_result.magic_comments,
                  original_result.data_loc,
                  original_result.errors,
                  original_result.warnings,
                  original_result.source
                )
              end
            end.new(ast, original_result)
          )
          source_buffer = Parser::Source::Buffer.new('(string)', 1)
          source_buffer.source = contents
          translator.send(@options[:ignore_comments] ? 'parse' : 'parse_with_comments', source_buffer)
        end

        unparsed = processed_asts.map do |r|
          r.is_a?(Array) ? Unparser.unparse(r.first, comments: r.last) : Unparser.unparse(r)
        end
        file_names = files.map { |f| File.basename(f) }
        if !@options[:skip_difftastic] && @options[:diff_original]
          system <<~CMD
            difft #{files.first} #{files.last} \
            #{'--check-only --exit-code' if @options[:check_only]} \
            #{'--ignore-comments' if @options[:ignore_comments]}
          CMD
        end
        return if @options[:skip_difftastic] && !@options[:gumtree]

        with_diff_files(unparsed, file_names, output_directory: @options[:output_directory]) do |b, a|
          unless @options[:skip_difftastic]
            system <<~CMD
              difft #{b.path} #{a.path} \
              #{'--check-only --exit-code' if @options[:check_only]} \
              #{'--ignore-comments' if @options[:ignore_comments]}
            CMD
          end
          if @options[:gumtree]
            system <<~CMD
              gumtree webdiff #{b.path} #{a.path} \
              -g ruby-treesitter-ng
            CMD
          end
        end
      rescue OptionParser::InvalidOption => e
        puts e.message
        puts parser
        puts "Invalid argument (use rdiff --help): #{e}"
        exit 1
      end

      @options
    end
  end
end
