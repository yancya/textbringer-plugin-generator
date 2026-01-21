# frozen_string_literal: true

require_relative "lib/textbringer/plugin/generator/version"

Gem::Specification.new do |spec|
  spec.name = "textbringer-plugin-generator"
  spec.version = Textbringer::Plugin::Generator::VERSION
  spec.authors = ["yancya"]
  spec.email = ["yancya@upec.jp"]

  spec.summary = "Generate Textbringer plugin boilerplate with best practices"
  spec.description = "A command-line tool to generate Textbringer plugin scaffolding with proper structure, tests, GitHub Actions, and documentation."
  spec.homepage = "https://github.com/yancya/textbringer-plugin-generator"
  spec.license = "WTFPL"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yancya/textbringer-plugin-generator"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
end
