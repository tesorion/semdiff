# frozen_string_literal: true

module Semdiff
  # typeguard gem for type specifications
  require 'typeguard'

  # external
  require 'prism'
  # suppress warning (re: https://github.com/glebm/i18n-tasks/pull/613):
  #   warning: parser/current is loading parser/ruby34, which recognizes 3.4.0-dev-compliant syntax, but you are running 3.4.1.
  #   Please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.
  prev = $VERBOSE
  $VERBOSE = nil
  require 'unparser'
  $VERBOSE = prev

  # utils
  require_relative 'semdiff/utils/compiler_utils'
  require_relative 'semdiff/utils/io_utils'

  # prism compilers and visitors
  require_relative 'semdiff/aliasing_compiler'
  require_relative 'semdiff/constants_compiler'
  require_relative 'semdiff/identity_compiler'
  require_relative 'semdiff/structures_compiler'
  require_relative 'semdiff/algebra_compiler'
  require_relative 'semdiff/type_visitor'

  # command line module
  require_relative 'semdiff/cli/cli'
end
