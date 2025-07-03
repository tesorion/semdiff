# frozen_string_literal: true

module Semdiff
  # StructuresCompiler is a compiler that normalizes common
  # data structure operations.
  #
  # @example
  #   ```ruby
  #   # Expression              Canonical Form
  #   Array.new                 []
  #   Array.new(0)              []
  #   Hash.new                  {}
  #   Hash[]                    {}
  #   array.push(e)             array << e
  #   "a".concat("b")           "a" << "b"
  #   hash.store(key, value)    hash[key] = value
  #   ''                        ""
  #   ```
  class StructuresCompiler < ::Prism::MutationCompiler
    include Prism::DSL
    include CompilerUtils

    def visit_call_node(node)
      receiver  = visit(node.receiver)
      arguments = visit(node.arguments)
      block     = visit(node.block)

      result = case node.name
               when :new
                 transform_constructor(node, receiver, arguments, block)
               when :[]
                 transform_class_bracket_method(node, receiver, arguments)
               when :push
                 transform_push_to_shovel(node, receiver, arguments)
               when :concat
                 transform_concat_to_shovel(node, receiver, arguments)
               when :store
                 transform_store_to_bracket_assign(node, receiver, arguments)
               end

      if result
        CompilerUtils.inherit_newline(node, result)
      else
        node.copy(receiver: receiver, arguments: arguments, block: block)
      end
    end

    private

    def transform_constructor(node, receiver, arguments, block)
      return nil unless receiver.is_a?(Prism::ConstantReadNode)
      return nil if block

      case receiver.name
      when :Array
        transform_array_new(node, arguments)
      when :Hash
        transform_hash_new(node, arguments)
      end
    end

    def transform_array_new(node, arguments)
      # Array.new -> []
      if arguments.nil? || arguments.arguments.empty?
        return array_node(
          node_id: node.node_id,
          source: node.send(:source),
          location: node.location,
          flags: Prism::NodeFlags::STATIC_LITERAL,
          elements: [],
          opening_loc: node.receiver.location,
          closing_loc: node.message_loc
        )
      end

      # Array.new(0) -> []
      if arguments.arguments.size == 1 &&
         arguments.arguments.first.is_a?(Prism::IntegerNode) &&
         arguments.arguments.first.value.zero?
        return array_node(
          node_id: node.node_id,
          source: node.send(:source),
          location: node.location,
          flags: Prism::NodeFlags::STATIC_LITERAL,
          elements: [],
          opening_loc: node.receiver.location,
          closing_loc: node.closing_loc
        )
      end

      nil
    end

    def transform_hash_new(node, arguments)
      # Hash.new -> {} (only without arguments)
      if arguments.nil? || arguments.arguments.empty?
        return hash_node(
          node_id: node.node_id,
          source: node.send(:source),
          location: node.location,
          flags: Prism::NodeFlags::STATIC_LITERAL,
          elements: [],
          opening_loc: node.receiver.location,
          closing_loc: node.message_loc
        )
      end

      nil
    end

    def transform_class_bracket_method(node, receiver, arguments)
      return nil unless receiver.is_a?(Prism::ConstantReadNode)

      # Hash[] -> {}
      if receiver.name == :Hash && (arguments.nil? || arguments.arguments.empty?)
        return hash_node(
          node_id: node.node_id,
          source: node.send(:source),
          location: node.location,
          flags: Prism::NodeFlags::STATIC_LITERAL,
          elements: [],
          opening_loc: node.opening_loc,
          closing_loc: node.closing_loc
        )
      end

      nil
    end

    def transform_push_to_shovel(node, receiver, arguments)
      # array.push(e) -> array << e
      return nil unless arguments&.arguments&.size == 1

      call_node(
        node_id: node.node_id,
        source: node.send(:source),
        location: node.location,
        flags: 0,
        receiver: receiver,
        call_operator_loc: nil,
        name: :<<,
        message_loc: node.message_loc,
        opening_loc: nil,
        arguments: arguments,
        closing_loc: nil,
        block: nil
      )
    end

    def transform_concat_to_shovel(node, receiver, arguments)
      # "a".concat("b") -> "a" << "b"
      return nil unless arguments&.arguments&.size == 1
      return nil unless receiver.is_a?(Prism::StringNode)

      call_node(
        node_id: node.node_id,
        source: node.send(:source),
        location: node.location,
        flags: 0,
        receiver: receiver,
        call_operator_loc: nil,
        name: :<<,
        message_loc: node.message_loc,
        opening_loc: nil,
        arguments: arguments,
        closing_loc: nil,
        block: nil
      )
    end

    def transform_store_to_bracket_assign(node, receiver, arguments)
      # hash.store(key, value) -> hash[key] = value
      return nil unless arguments&.arguments&.size == 2

      # NOTE: there seems to be a bug here where flags for the
      # hash[key] = value callnode has 256 (1 << 8) set, we
      # copy it here to pass === check
      call_node(
        node_id: node.node_id,
        source: node.send(:source),
        location: node.location,
        flags: call_node_flag(:attribute_write) | (1 << 8),
        receiver: receiver,
        call_operator_loc: nil,
        name: :[]=,
        message_loc: node.message_loc,
        opening_loc: node.opening_loc,
        arguments: arguments,
        closing_loc: node.closing_loc,
        block: nil
      )
    end
  end
end
