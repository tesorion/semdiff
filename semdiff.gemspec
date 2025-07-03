# frozen_string_literal: true

require_relative 'lib/semdiff/version'

Gem::Specification.new do |spec|
  spec.name = 'semdiff'
  spec.version = Semdiff::VERSION
  spec.authors = ['Tesorion']
  spec.email = ['QmanageDevelopment@tesorion.nl']

  spec.summary = 'Semantic differences for Ruby code changes'
  spec.homepage = 'https://github.com/tesorion/semdiff'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.licenses = ['MIT']
  spec.metadata['source_code_uri'] = 'https://github.com/tesorion/semdiff'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.executables << 'semdiff'
  spec.require_paths = ['lib']

  spec.add_dependency 'optparse'
  spec.add_dependency 'prism'
  spec.add_dependency 'rbs'
  spec.add_dependency 'typeguard'
  spec.add_dependency 'unparser'
  spec.add_dependency 'yard'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
