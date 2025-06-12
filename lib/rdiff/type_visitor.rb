# frozen_string_literal: true

# require 'prism'

module RDiff
  # This visitor is responsible for mapping AST nodes to type information.
  # Returns a Hash of `node_id => flags` : `{10 => 7, 11 => 7}`
  class TypeVisitor < ::Prism::Visitor
    include Yard::TypeModel::Definitions

    UNSAFE_NUMERIC_CLASSES = %i[Date::Infinity].freeze
    NUMERIC_CLASSES = %i[Numeric Integer Float Rational Complex].freeze
    ENUMERABLE_CLASSES = %i[
      Enumerable ARGF Array Dir Enumerator ENV Hash
      IO Range Struct CSV CSV::Table CSV::Row Set
    ].freeze

    def initialize(types)
      @types = types
      @mods = map_mods(@types)
      @scope = []
      @mod = nil
      @method = nil
      @node_types = {}
      super()
    end

    def visit_program_node(node)
      super
      @node_types
    end

    def visit_module_node(node)
      process_mod_node(node)
    end

    def visit_class_node(node)
      process_mod_node(node)
    end

    def visit_def_node(node)
      # Either look in the current mod or root
      haystack = @mod&.children || (@types if @scope.empty?)
      # NOTE: If an explicit receiver is provided, we look
      # for singleton methods on the current mod,
      # assuming that the receiver is self. Could be
      # expanded by resolving the receiver if not self.
      scope = node.receiver ? :class : :instance
      needle = node.name
      method = haystack.find do |e|
        e.is_a?(MethodDefinition) && e.name == needle && e.scope == scope
      end
      @method = method
      super
      @method = nil
    end

    def visit_class_variable_read_node(node)
      types = find_var_types(:class, node.name)
      store_node_types(node, types)
      super
    end

    def visit_constant_read_node(node)
      types = find_var_types(:constant, node.name)
      store_node_types(node, types)
      super
    end

    def visit_instance_variable_read_node(node)
      types = find_var_types(:instance, node.name)
      store_node_types(node, types)
      super
    end

    def visit_local_variable_read_node(node)
      unless @method.nil? || @method.parameters.empty?
        params = @method.parameters.find { |p| p.name == node.name }
        types = params&.types
        store_node_types(node, types)
      end
      super
    end

    def visit_call_node(node)
      if node.variable_call? || node.receiver&.type == :self_node
        # In the case where a singleton method is defined on the
        # current mod: `class << self; attr_reader :a; end` we
        # might have type information (a var) on the mod.
        types = find_var_types(:self, node.name)
        store_node_types(node, types)
      end
      super
    end

    private

    def map_mods(types)
      mods = {}
      return mods if types.nil?

      queue = Array(types).select { |o| o.respond_to?(:vars) }
      visited = Set.new
      while (mod = queue.shift)
        next unless mod && visited.add?(mod.object_id)

        mods[mod.name] = mod
        queue.concat(mod.children.select { |c| c.respond_to?(:vars) })
      end
      mods
    end

    def compute_fqn(path_node, scope)
      fqn = scope.join('::')

      case path_node.type
      when :constant_read_node
        name_s = path_node.name.to_s
        fqn.empty? ? name_s : "#{fqn}::#{name_s}"
      when :constant_path_node
        path = path_node.full_name
        return path[2..] if path.start_with?('::')

        candidate = fqn.empty? ? path : "#{fqn}::#{path}"
        if @mods.include?(candidate) || !@mods.include?(path)
          candidate
        else
          path
        end
      else
        raise "Unsupported path node type for #{path_node.type}"
      end
    end

    def process_mod_node(node)
      fqn = compute_fqn(node.constant_path, @scope)
      prev_scope = @scope
      @scope = fqn.split('::')
      prev_mod = @mod
      @mod = @mods[fqn]
      visit_child_nodes(node)
      @scope = prev_scope
      @mod = prev_mod
    end

    def find_var_types(scope, name)
      return nil if @mod.nil? || @mod.vars.empty?

      var = @mod.vars.find { |v| v.scope == scope && v.name == name }
      var&.types
    end

    def store_node_types(node, types)
      return if types.nil?

      flags = 0
      if types.one?
        flags |= NodeTypeFlags::ONE
        t = types.first
        if t.shape == :basic
          flags |= NodeTypeFlags::BASIC
          case t.kind
          when :Integer
            flags |= NodeTypeFlags::INTEGER
          when :Float
            flags |= NodeTypeFlags::FLOAT
          when :boolean
            flags |= NodeTypeFlags::BOOLEAN
          when :String
            flags |= NodeTypeFlags::STRING
          end
        end
      end
      is_numeric = types.all? { |e| NUMERIC_CLASSES.include?(e.kind) }
      flags |= NodeTypeFlags::NUMERIC if is_numeric
      is_enumerable = types.all? { |e| ENUMERABLE_CLASSES.include?(e.kind) }
      flags |= NodeTypeFlags::ENUMERABLE if is_enumerable
      @node_types[node.node_id] = flags
    end
  end

  module NodeTypeFlags
    # a node with a single type [a] instead of a union [a, b]
    ONE = 1 << 0

    # a node with a basic shape, single constant, no children
    BASIC = 1 << 1

    # an Integer node
    INTEGER = 1 << 2

    # a Float node
    FLOAT = 1 << 3

    # a Booolean node
    BOOLEAN = 1 << 4

    # a String node
    STRING = 1 << 5

    # a Numeric subclass node
    NUMERIC = 1 << 6

    # a node that includes (or extends) Enumerable
    ENUMERABLE = 1 << 7
  end
end
