# Textbringer Plugin Generator

A command-line tool to generate Textbringer plugin scaffolding with proper structure, tests, GitHub Actions, and documentation.

## Features

Generates a complete Textbringer plugin project with:

- ✅ Proper directory structure with `lib/textbringer_plugin.rb` for automatic loading
- ✅ Test::Unit test setup with Textbringer mocks
- ✅ GitHub Actions workflow for automated RubyGems release via OIDC (Trusted Publishing)
- ✅ Clean README template without TODOs
- ✅ CLAUDE.md for future AI assistance
- ✅ `.gitignore` with Gemfile.lock and .claude/ excluded
- ✅ Rakefile with test task
- ✅ Choice of license (MIT or WTFPL)

All based on best practices learned from developing real Textbringer plugins.

## Installation

Install the gem by executing:

```bash
gem install textbringer-plugin-generator
```

## Usage

Generate a new Textbringer plugin:

```bash
textbringer-plugin new my-plugin
```

This creates a new directory `textbringer-my-plugin` with all the necessary files.

### Options

- `--license=[wtfpl|mit|apache-2.0|bsd-3-clause|gpl-3.0]` - Choose license (default: wtfpl)
- `--test_framework=[test-unit|minitest|rspec]` - Choose test framework (default: test-unit)
- `--author=NAME` - Set author name (default: from git config)
- `--email=EMAIL` - Set author email (default: from git config)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yancya/textbringer-plugin-generator.

## License

The gem is available as open source under the terms of the [WTFPL](http://www.wtfpl.net/).
