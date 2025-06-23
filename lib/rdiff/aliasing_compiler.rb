# frozen_string_literal: true

module RDiff
  # AliasingCompiler is a compiler that unifies method aliases
  # according to the Ruby style guide (https://rubystyle.guide/)
  # based on type information.
  #
  # @example
  #   ```ruby
  #   # Original        Canonical Form
  #   [].collect        [].map
  #   {}.detect         {}.find
  #   (1..5).find_all   (1..5).select
  #   [1, 2].inject(:+) [1, 2].reduce(:+)
  #   [1].member?(1)    [1].include?(1)
  #   "abc".length      "abc".size
  #   [1,2,3].length    [1,2,3].size
  #   ```
  class AliasingCompiler < ::Prism::MutationCompiler
    include Prism::DSL
    include CompilerUtils

    # NOTE: `Enumerables` (and others for `length`/`size`) typically
    # respond to both the key and value method names in this map.
    # We therefore assume that any Ruby object does (and should)
    # have both methods for every pair, if they have at least one.
    # This greatly simplifies the process of accounting for every
    # (standard library) object and also allows us to map custom
    # subclass (e.g., `Foo < Array`) methods automatically.
    UNTYPED_ALIASES = {
      collect: :map,
      detect: :find,
      find_all: :select,
      inject: :reduce,
      member?: :include?,
      length: :size
    }.freeze

    def visit_call_node(node)
      receiver  = visit(node.receiver)
      arguments = visit(node.arguments)
      block     = visit(node.block)
      result    = nil

      if UNTYPED_ALIASES.key?(node.name)
        canonical_name = UNTYPED_ALIASES[node.name]
        # It might be worth updating the message_loc to reflect
        # the new size. However, the underlying message buffer
        # would still point to the original name.
        result = node.copy(
          name: canonical_name,
          receiver: receiver,
          arguments: arguments,
          block: block
        )
      end

      if result
        CompilerUtils.inherit_newline(node, result)
      else
        node.copy(receiver: receiver, arguments: arguments, block: block)
      end
    end
  end
end
