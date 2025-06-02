# frozen_string_literal: true

require 'test_helper'

module RDiff
  class AliasingCompilerTest < TestCase
    def untyped_compilers
      [AliasingCompiler]
    end

    def typed_compilers
      []
    end

    def test_untyped
      assert_equivalent 'foo.map',      'foo.collect'
      assert_equivalent 'foo.find',     'foo.detect'
      assert_equivalent 'foo.select',   'foo.find_all'
      assert_equivalent 'foo.reduce',   'foo.inject'
      assert_equivalent 'foo.include?', 'foo.member?'
      assert_equivalent 'foo.size',     'foo.length'
    end

    def test_untyped_surroundings
      assert_equivalent '[].map', '[].collect'
      assert_equivalent '[].map {}', '[].collect {}'
      assert_equivalent '[].map {|e| -e}', '[].collect {|e| - e}'
      assert_equivalent '[].map do |e| -e end;', '[].collect do |e| -e end'
      assert_equivalent '[2, 4].map(&:to_s)', '[2, 4].collect(&:to_s)'
    end
  end
end
