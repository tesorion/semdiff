# frozen_string_literal: true

module RDiff
  # AlgebraCompiler is a compiler that simplifies expressions with algebraic
  # relations based on type information.
  #
  # @example
  #   ```ruby
  #  # Expression              Canonical Form
  #  b + a                     a + b # commutativity
  #  c * a                     a * c # commutativity
  #  ( a + b ) + c             a + b + c # associativity
  #  ( x * b ) + ( x * c )     x * ( b + c ) # distributivity
  #  x - ( - y )               x + y # negation
  #  ( x ** m ) * ( x ** n )   x **( m + n ) # exponentials
  #  ( a - b ) - b             a - 2* b # optimization
  #  ```
  class AlgebraCompiler < ::Prism::MutationCompiler
    include Prism::DSL
    include CompilerUtils

    COMMUTATIVE_OPS = %i[+ *].freeze
    ASSOCIATIVE_OPS = %i[+ *].freeze

    def initialize(node_types)
      @node_types = node_types
      super()
    end

    def visit_call_node(node)
      receiver  = visit(node.receiver)
      arguments = visit(node.arguments)
      block     = visit(node.block)
      result    = nil

      if COMMUTATIVE_OPS.include?(node.name) &&
         receiver &&
         arguments&.arguments&.size == 1 &&
         block.nil?
        if ASSOCIATIVE_OPS.include?(node.name)
          operands = flatten_associative_operation(node.name, receiver, arguments.arguments.first)
          if operands.all? { |op| numeric?(op) }
            sorted_operands = operands.sort_by { |op| sort_key(op) }
            result = rebuild_associative_operation(node, node.name, sorted_operands)
          end
        else
          lhs = receiver
          rhs = arguments.arguments.first
          if numeric?(lhs) && numeric?(rhs) && should_swap?(lhs, rhs)
            result = node.copy(
              receiver: rhs,
              arguments: arguments_node(
                node_id: arguments.node_id,
                source: arguments.send(:source),
                location: arguments.location,
                flags: arguments.send(:flags),
                arguments: [lhs]
              )
            )
          end
        end
      end

      if result
        CompilerUtils.inherit_newline(node, result)
      else
        node.copy(receiver: receiver, arguments: arguments, block: block)
      end
    end

    def visit_parentheses_node(node)
      if node.multiple_statements?
        statements = visit_all(node.body.body)
        body = node.body.copy(body: statements)
        node.copy(body: body)
      else
        inner = visit(node.body.body.first)
        if inner.type == :call_node &&
           ASSOCIATIVE_OPS.include?(inner.name) &&
           inner.arguments&.arguments&.size == 1 &&
           numeric?(inner.receiver) &&
           numeric?(inner.arguments.arguments.first)
          inner
        else
          body = node.body.copy(body: [inner])
          node.copy(body: body)
        end
      end
    end

    private

    def numeric?(node)
      case node.type
      when :integer_node, :float_node
        true
      else
        types = @node_types[node.node_id]
        types&.anybits?(NodeTypeFlags::NUMERIC)
      end
    end

    def should_swap?(lhs, rhs)
      sort_key(lhs) > sort_key(rhs)
    end

    def sort_key(node)
      case node.type
      when :local_variable_read_node, :instance_variable_read_node,
           :class_variable_read_node, :global_variable_read_node,
           :constant_read_node
        node.name.to_s
      when :call_node
        node.name.to_s
      when :integer_node, :float_node
        "_#{node.value}"
      else
        "~#{node.type}"
      end
    end

    def flatten_associative_operation(operation, left, right)
      operands = []

      left = unwrap_parentheses(left)
      if left.type == :call_node &&
         left.name == operation &&
         left.arguments&.arguments&.size == 1 &&
         left.block.nil?
        operands.concat(flatten_associative_operation(operation, left.receiver, left.arguments.arguments.first))
      else
        operands << left
      end

      right = unwrap_parentheses(right)
      if right.type == :call_node &&
         right.name == operation &&
         right.arguments&.arguments&.size == 1 &&
         right.block.nil?
        operands.concat(flatten_associative_operation(operation, right.receiver, right.arguments.arguments.first))
      else
        operands << right
      end

      operands
    end

    def unwrap_parentheses(node)
      node = node.body.body.first while node.type == :parentheses_node && !node.multiple_statements?
      node
    end

    def rebuild_associative_operation(original_node, operation, operands)
      result = operands.first

      operands[1..].each do |operand|
        result = call_node(
          node_id: original_node.node_id,
          source: original_node.send(:source),
          location: original_node.location,
          flags: 0,
          receiver: result,
          call_operator_loc: nil,
          name: operation,
          message_loc: original_node.message_loc,
          opening_loc: nil,
          arguments: arguments_node(
            node_id: original_node.arguments.node_id,
            source: original_node.arguments.send(:source),
            location: original_node.arguments.location,
            flags: original_node.arguments.send(:flags),
            arguments: [operand]
          ),
          closing_loc: nil,
          block: nil
        )
      end

      result
    end
  end
end
