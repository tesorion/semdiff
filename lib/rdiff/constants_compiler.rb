# frozen_string_literal: true

module RDiff
  # ConstantsCompiler is a compiler that folds constant literal
  # expressions into single constants.
  #
  # @example
  #   ```ruby
  #   # Expression        Canonical Form
  #   (2 + 3)             5
  #   (4 * 2 - 1)         7
  #   (8 / 4) + 3         5
  #   (1 + 2**3)          9
  #   ```
  class ConstantsCompiler < ::Prism::MutationCompiler
    include Prism::DSL
    include CompilerUtils

    SUPPORTED_OPS = %i[+ - * / % ** & | ^ << >>].freeze

    def visit_call_node(node)
      receiver  = visit(node.receiver)
      arguments = visit(node.arguments)
      result    = nil

      result = fold_constants(node, receiver, arguments) if constant_foldable?(node, receiver, arguments)

      if result
        CompilerUtils.inherit_newline(node, result)
      else
        # finalized transformations
        node.copy(receiver: receiver, arguments: arguments, block: visit(node.block))
      end
    end

    def visit_parentheses_node(node)
      if node.multiple_statements?
        statements = visit_all(node.body.body)
        body = node.body.copy(body: statements)
        return node.copy(body: body)
      end

      single_child = node.body.body.first
      visited = visit(single_child)

      return visited if visited.is_a?(Prism::IntegerNode)

      new_body = node.body.copy(body: [visited])
      node.copy(body: new_body)
    end

    private

    def constant_foldable?(node, receiver, arguments)
      receiver.is_a?(Prism::IntegerNode) &&
        arguments&.arguments&.size == 1 &&
        arguments.arguments.first.is_a?(Prism::IntegerNode) &&
        SUPPORTED_OPS.include?(node.name)
    end

    def fold_constants(node, receiver, arguments)
      lhs = receiver.value
      rhs = arguments.arguments.first.value
      op  = node.name

      case op
      when :/, :%
        return nil if rhs.zero?
      when :**
        return nil if rhs.negative?
      end

      result = begin
        lhs.send(op, rhs)
      rescue StandardError
        nil
      end

      return nil unless result.is_a?(Integer)

      flags = integer_base_flag(:decimal) | Prism::NodeFlags::STATIC_LITERAL
      integer_node(
        node_id: node.node_id,
        source: node.send(:source),
        location: node.location,
        flags: flags,
        value: result
      )
    end
  end
end
