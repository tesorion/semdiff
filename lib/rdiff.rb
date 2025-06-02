# frozen_string_literal: true

module RDiff
  # git submodule for type specifications
  require_relative '../yard-validator/lib/yard/type_model/definitions'
  require_relative '../yard-validator/lib/yard/type_model/builder'
  require_relative '../yard-validator/lib/yard/type_model/builder/rbs_builder'
  require_relative '../yard-validator/lib/yard/type_model/builder/yard_builder'
  require_relative '../yard-validator/lib/yard/type_model/mapper/rbs_mapper'
  require_relative '../yard-validator/lib/yard/type_model/mapper/yard_mapper'

  # external
  require 'prism'
  # suppress warning (re: https://github.com/glebm/i18n-tasks/pull/613):
  # warning: parser/current is loading parser/ruby34, which recognizes 3.4.0-dev-compliant syntax, but you are running 3.4.1.
  # Please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.
  prev = $VERBOSE
  $VERBOSE = nil
  require 'unparser'
  $VERBOSE = prev

  # utils
  require_relative 'rdiff/utils/compiler_utils'
  require_relative 'rdiff/utils/io_utils'

  # prism compilers and visitors
  require_relative 'rdiff/aliasing_compiler'
  require_relative 'rdiff/constants_compiler'
  require_relative 'rdiff/identity_compiler'
  require_relative 'rdiff/structures_compiler'
  require_relative 'rdiff/algebra_compiler'
  require_relative 'rdiff/type_visitor'

  # command line module
  require_relative 'rdiff/cli/cli'
end
