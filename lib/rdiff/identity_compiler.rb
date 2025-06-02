# frozen_string_literal: true

module RDiff
  # IdentityCompiler is a compiler that simplifies arithmetic identities
  # for variables based on type information.
  #
  # @example
  #   ```ruby
  #   # Expression        Canonical Form
  #   x + 0               x       # zero addition
  #   x - 0               x       # zero subtraction
  #   0 - x               -x      # unary negation
  #   x * 1               x       # multiplicative identity
  #   0 * x               0       # zero multiplication
  #   x / 1               x       # division identity
  #   x ** 1              x       # exponent identity
  #   x ** 0              1       # zero exponent
  #   +x                  x       # unary plus is noop
  #   -(-x)               x       # double negation
  #   ---x                -x      # multiple negation
  #   ```
  class IdentityCompiler < ::Prism::MutationCompiler
    include Prism::DSL
    include CompilerUtils

    def initialize(node_types)
      @node_types = node_types
      super()
    end

    def visit_call_node(node)
      lhs         = visit(node.receiver)
      arguments   = visit(node.arguments)
      rhs         = arguments&.arguments&.first
      lhs_types   = lhs && @node_types[lhs.node_id]
      rhs_types   = rhs && @node_types[rhs.node_id]
      lhs_numeric = lhs_types&.anybits?(NodeTypeFlags::NUMERIC)
      rhs_numeric = rhs_types&.anybits?(NodeTypeFlags::NUMERIC)
      lhs_integer = lhs_numeric && lhs_types.anybits?(NodeTypeFlags::INTEGER)
      rhs_integer = rhs_numeric && rhs_types.anybits?(NodeTypeFlags::INTEGER)
      result      = nil

      case node.name
      when :+
        if lhs_numeric && zero_literal?(rhs)
          # x + 0 => x
          result = lhs
        elsif rhs_numeric && zero_literal?(lhs)
          # 0 + x => x
          result = rhs
        end
      when :+@
        # + x => x
        result = lhs if lhs_numeric
      when :-
        if lhs_numeric && zero_literal?(rhs)
          # x - 0 => x
          result = lhs
        elsif rhs_numeric && zero_literal?(lhs)
          # 0 - x => -x
          result = node.copy(
            receiver: rhs,
            name: :-@,
            arguments: nil
          )
        end
      when :-@
        inner_lhs = lhs
        neg_count = 1
        loop do
          if inner_lhs.type == :parentheses_node && !inner_lhs.multiple_statements?
            # -( - x ) => x
            inner_lhs = inner_lhs.body.body.first
            next
          end
          if inner_lhs.type == :call_node && inner_lhs.name == :-@
            # ---x => -x
            inner_lhs = inner_lhs.receiver
            neg_count += 1
            next
          end
          break
        end
        result = inner_lhs if neg_count.even?
      when :*
        if lhs_numeric && one_literal?(rhs)
          # x * 1 => x
          result = lhs
        elsif rhs_numeric && one_literal?(lhs)
          # 1 * x => x
          result = rhs
        elsif (lhs_integer && zero_literal?(rhs)) ||
              (rhs_integer && zero_literal?(lhs))
          # 0 * x or x * 0 => 0
          # TODO: explain how this is not safe for other Numeric
          # TODO: explain how this is not safe for Float because of INFINITY or NaN instead of 0
          result = rhs && zero_literal?(rhs) ? rhs : lhs
        end
      when :/
        # x / 1 => x
        result = lhs if lhs_numeric && one_literal?(rhs)
      when :**
        if lhs_numeric && one_literal?(rhs)
          # x ** 1 => x
          result = lhs
        elsif lhs_integer && zero_literal?(rhs)
          # x ** 0 => 1
          # TODO: explain how this is not safe for other Numeric
          flags = integer_base_flag(:decimal) | Prism::NodeFlags::STATIC_LITERAL
          result = integer_node(
            source: node.send(:source),
            location: node.location,
            flags: flags,
            value: 1
          )
        end
      end

      if result
        CompilerUtils.inherit_newline(node, result)
      else
        # finalized transformations
        node.copy(receiver: lhs, arguments: arguments, block: visit(node.block))
      end
    end

    private

    def zero_literal?(node)
      node.type == :integer_node && node.value.zero?
    end

    def one_literal?(node)
      node.type == :integer_node && node.value == 1
    end
  end
end
