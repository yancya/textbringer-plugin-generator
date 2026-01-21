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
          puts "Generating Textbringer plugin: #{name}"
          puts "  License: #{options[:license]}"
          puts "  Author: #{options[:author] || 'from git config'}"
          puts "  Email: #{options[:email] || 'from git config'}"
          # TODO: Implement actual generation logic
        end
      end
    end
  end
end
