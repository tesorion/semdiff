# frozen_string_literal: true

require 'tempfile'

module Semdiff
  module IOUtils
    include ::Typeguard::TypeModel::Builder

    FILE_PREFIX = 'source'
    FILE_SUFFIX = '.rb'
    DIR_PREFIX = 'yard_'
    DIR_SUFFIX = '_db'
    RUBY_VERSION_F = RUBY_VERSION.to_f

    def with_types_desugared(*content)
      with_temp_files(*content) do |files|
        with_temp_dir do |dir|
          system(*yardoc_cmd(files, dir))
          program_node = Prism.parse_file(files.first.path).value
          types = YardBuilder.new(dir, false).build
          node_types = TypeVisitor.new(types).visit(program_node)
          yield program_node, node_types
        end
      end
    end

    def with_prism_and_yard_types(*contents)
      with_temp_files(*contents) do |files|
        with_temp_dir do |dir|
          system(*yardoc_cmd(files, dir))
          parse_lex_results = files.map do |f|
            Prism.parse_lex_file(f.path)
          end
          types = YardBuilder.new(dir, false).build
          yield files, dir, parse_lex_results, types
        end
      end
    end

    def with_full_prism_desugared(*contents)
      with_temp_files(*contents) do |files|
        with_temp_dir do |dir|
          system(*yardoc_cmd(files, dir))
          program_nodes = files.map do |f|
            Prism.parse_file(f.path).value.accept(Prism::DesugarCompiler.new)
          end
          types = YardBuilder.new(dir, false).build
          yield files, dir, program_nodes, types
        end
      end
    end

    def with_prism_desugared(*contents)
      with_temp_files(*contents) do |files|
        program_node = files.map do |f|
          Prism.parse_file(f.path).value.accept(Prism::DesugarCompiler.new)
        end
        yield files, program_node
      end
    end

    def with_full_prism(*contents)
      with_temp_files(*contents) do |files|
        with_temp_dir do |dir|
          system(*yardoc_cmd(files, dir))
          program_node = Prism.parse_file(files.first.path).value
          types = YardBuilder.new(dir, false).build
          yield files, dir, program_node, types
        end
      end
    end

    def with_prism(*contents)
      with_temp_files(*contents) do |files|
        program_node = files.map do |f|
          Prism.parse_file(f.path).value
        end
        yield files, program_node
      end
    end

    def with_yard_types(*contents)
      with_temp_files(*contents) do |files|
        with_temp_dir do |dir|
          system(*yardoc_cmd(files, dir))
          types = YardBuilder.new(dir, false).build
          yield files, dir, types
        end
      end
    end

    def with_yardoc_and_prism(*contents)
      with_temp_files(*contents) do |files|
        with_temp_dir do |dir|
          system(*yardoc_cmd(files, dir))
          parse_lex_results = files.map do |f|
            Prism.parse_lex_file(f.path)
          end
          yield files, dir, parse_lex_results
        end
      end
    end

    def with_prism_parse_lex(*contents)
      with_temp_files(*contents) do |files|
        parse_lex_results = files.map do |f|
          Prism.parse_lex_file(f.path)
        end
        yield files, parse_lex_results
      end
    end

    def with_yardoc(*contents)
      with_temp_dir do |dir|
        with_temp_files(*contents) do |files|
          system(*yardoc_cmd(files, dir))
          yield files, dir
        end
      end
    end

    def with_rubocop_ast_and_yard_types(*contents)
      with_temp_files(*contents) do |files|
        with_temp_dir do |dir|
          system(*yardoc_cmd(files, dir))
          ast_results = files.map do |f|
            RuboCop::AST::ProcessedSource.from_file(
              f.path,
              RUBY_VERSION_F,
              parser_engine: :parser_prism
            )
          end
          types = YardBuilder.new(dir, false).build
          yield files, dir, ast_results, types
        end
      end
    end

    def with_rubocop_ast_bypass(*file_prism_pairs)
      ast_results = file_prism_pairs.map do |f, prism_result|
        source = File.read(f.path)
        RuboCop::AST::ProcessedSource.new(
          source,
          RUBY_VERSION_F,
          f.path,
          parser_engine: :parser_prism,
          prism_result: prism_result
        )
      end
      yield ast_results
    end

    def with_rubocop_ast(*contents)
      with_temp_files(*contents) do |files|
        ast_results = files.map do |f|
          RuboCop::AST::ProcessedSource.from_file(
            f.path,
            RUBY_VERSION_F,
            parser_engine: :parser_prism
          )
        end
        yield files, ast_results
      end
    end

    def with_diff_files(contents, names, output_directory: nil)
      prefix = 'unparsed_'
      if output_directory
        FileUtils.mkdir_p(output_directory)
        b, a = contents.zip(names).map do |c, n|
          path = File.join(output_directory, "#{prefix}#{n}")
          File.write(path, c)
          File.open(path, 'r')
        end
        begin
          yield b, a
        ensure
          b.close
          a.close
        end
      else
        b_temp, a_temp = contents.zip(names).map do |c, n|
          temp_file(c, prefix: '', suffix: "_#{prefix}#{n}")
        end
        begin
          yield b_temp, a_temp
        ensure
          File.unlink(b_temp.path)
          File.unlink(a_temp.path)
        end
      end
    end

    def with_temp_files(*contents, prefix: FILE_PREFIX, suffix: FILE_SUFFIX)
      files = contents.map.with_index do |content, i|
        temp_file(content, prefix: "#{prefix}#{i}_", suffix: suffix)
      end
      begin
        yield files
      ensure
        files.each { |f| File.unlink(f.path) }
      end
    end

    def with_temp_dir(prefix: DIR_PREFIX, suffix: DIR_SUFFIX)
      dir = temp_dir(prefix: prefix, suffix: suffix)
      begin
        yield dir
      ensure
        FileUtils.remove_entry_secure(dir)
      end
    end

    def temp_file(content, prefix: FILE_PREFIX, suffix: FILE_SUFFIX)
      f = Tempfile.create([prefix, suffix])
      f.write(content)
      f.close
      f
    end

    def temp_dir(prefix: DIR_PREFIX, suffix: DIR_SUFFIX)
      Dir.mktmpdir([prefix, suffix])
    end

    def yardoc_cmd(files, db_dir)
      [
        'bundle', 'exec', 'yardoc',
        *files.map(&:path),
        '--db', db_dir,
        '--quiet',
        '--no-output',
        '--no-cache',
        '--fail-on-warning',
        '--embed-mixins'
      ]
    end
  end
end
