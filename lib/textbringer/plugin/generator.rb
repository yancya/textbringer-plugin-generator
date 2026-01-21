# frozen_string_literal: true

require "fileutils"

module Textbringer
  module Plugin
    module Generator
      class Generator
        attr_reader :name, :gem_name, :module_name, :class_name, :options

        def initialize(name, options = {})
          @name = name
          @gem_name = "textbringer-#{name}"
          @module_name = camelize(name)
          @class_name = "#{camelize(name)}Mode"
          @options = options
        end

        def generate
          create_directory_structure
          puts "Created #{gem_name}/"
        end

        private

        def create_directory_structure
          FileUtils.mkdir_p(gem_name)
          FileUtils.mkdir_p("#{gem_name}/lib/textbringer/#{name}")
          FileUtils.mkdir_p("#{gem_name}/test")
          FileUtils.mkdir_p("#{gem_name}/.github/workflows")
        end

        def camelize(string)
          string.split(/[-_]/).map(&:capitalize).join
        end
      end
    end
  end
end
