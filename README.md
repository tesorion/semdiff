# Semdiff

Semantic differences for Ruby code changes.

Transforms Prism AST nodes to canonical forms whenever possible, for example: constant folding and reordering operands in expressions based on type signatures (YARD or RBS).

Uses GumTree/difftastic to generate the diff on canonical ASTs.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage
Invoke with 2 target files and the `semdiff` executable, for example: 
```
semdiff --yard --gumtree --diff-original test/assets/yard/before.rb test/assets/yard/after.rb
```
All options:
```
Usage: semdiff [options] BEFORE.rb AFTER.rb

Specific options:
    -h, --help                       Prints this help
    -o, --output-directory TARGET    Directory to output normalized unparsed files (default temporary)
        --ignore-comments            Don't process and preserve comments in the unparsed files
        --check-only                 Report whether there are any changes, but don't calculate them (much faster).
        --diff-original              Show a diff of the original files above the normalized files
        --yard [TARGET]              Use YARD (optional existing directory, default reparses input files)
        --yard-files FILE1,FILE2,... Reparse specific YARD files (choose --yard or this, not both)
        --rbs [TARGET]               Use RBS signatures (default ./sig/)
        --gumtree                    Use gumtree webdiff after default difftastic
        --skip-difftastic            Skip difftastic text diff
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/semdiff.
