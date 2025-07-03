# frozen_string_literal: true

module Semdiff
  module CompilerUtils
    # NOTE: Uses `send` to access protected flags, seems
    # preferable over extending Node(s)
    def self.inherit_newline(parent, node)
      need_newline = parent.newline?
      if need_newline == node.newline?
        node
      else
        flags = node.send(:flags)
        new_flags = if need_newline
                      flags | Prism::NodeFlags::NEWLINE
                    else
                      flags & ~Prism::NodeFlags::NEWLINE
                    end
        node.copy(flags: new_flags)
      end
    end
  end
end
