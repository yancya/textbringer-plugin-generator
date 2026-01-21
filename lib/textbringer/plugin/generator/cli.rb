# frozen_string_literal: true

require "thor"

module Textbringer
  module Plugin
    module Generator
      class CLI < Thor
        def self.exit_on_failure?
          true
        end

        desc "version", "Show version"
        def version
          puts "textbringer-plugin-generator #{VERSION}"
        end

        desc "new NAME", "Generate a new Textbringer plugin"
        option :license, type: :string, default: "wtfpl",
               desc: "License (wtfpl, mit, apache-2.0, bsd-3-clause, gpl-3.0)"
        option :test_framework, type: :string, default: "test-unit",
               desc: "Test framework (test-unit, minitest, rspec)"
        option :author, type: :string, desc: "Author name"
        option :email, type: :string, desc: "Author email"
        def new(name)
          generator = ::Textbringer::Plugin::Generator::Generator.new(name, options)
          generator.generate
        end
      end
    end
  end
end
