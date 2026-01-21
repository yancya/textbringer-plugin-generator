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
        option :license, type: :string, default: "wtfpl", desc: "License (mit or wtfpl)"
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
