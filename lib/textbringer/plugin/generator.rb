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
          create_gemspec
          create_gemfile
          create_rakefile
          create_gitignore
          create_lib_files
          puts "Created #{gem_name}/"
        end

        private

        def create_directory_structure
          FileUtils.mkdir_p(gem_name)
          FileUtils.mkdir_p("#{gem_name}/lib/textbringer/#{name}")
          FileUtils.mkdir_p("#{gem_name}/test")
          FileUtils.mkdir_p("#{gem_name}/.github/workflows")
        end

        def create_gemspec
          content = <<~RUBY
            # frozen_string_literal: true

            require_relative "lib/textbringer/#{name}/version"

            Gem::Specification.new do |spec|
              spec.name = "#{gem_name}"
              spec.version = Textbringer::#{module_name}::VERSION
              spec.authors = [#{author.inspect}]
              spec.email = [#{email.inspect}]

              spec.summary = "TODO: Write a short summary"
              spec.description = "TODO: Write a longer description"
              spec.homepage = "https://github.com/#{author}/#{gem_name}"
              spec.license = "#{license_type.upcase}"
              spec.required_ruby_version = ">= 3.2.0"

              spec.metadata["allowed_push_host"] = "https://rubygems.org"
              spec.metadata["homepage_uri"] = spec.homepage
              spec.metadata["source_code_uri"] = "https://github.com/#{author}/#{gem_name}"

              gemspec = File.basename(__FILE__)
              spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
                ls.readlines("\\x0", chomp: true).reject do |f|
                  (f == gemspec) ||
                    f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
                end
              end
              spec.bindir = "exe"
              spec.executables = spec.files.grep(%r{\\Aexe/}) { |f| File.basename(f) }
              spec.require_paths = ["lib"]

              spec.add_dependency "textbringer", ">= 1.0"
            end
          RUBY
          File.write("#{gem_name}/#{gem_name}.gemspec", content)
        end

        def create_gemfile
          content = <<~RUBY
            # frozen_string_literal: true

            source "https://rubygems.org"

            gemspec

            gem "irb"
            gem "rake", "~> 13.0"
            gem "test-unit"
          RUBY
          File.write("#{gem_name}/Gemfile", content)
        end

        def create_rakefile
          content = <<~RUBY
            # frozen_string_literal: true

            require "bundler/gem_tasks"
            require "rake/testtask"

            Rake::TestTask.new(:test) do |t|
              t.libs << "test"
              t.libs << "lib"
              t.test_files = FileList["test/**/*_test.rb"]
            end

            task default: :test
          RUBY
          File.write("#{gem_name}/Rakefile", content)
        end

        def create_gitignore
          content = <<~TEXT
            /.bundle/
            /.yardoc
            /_yardoc/
            /coverage/
            /doc/
            /pkg/
            /spec/reports/
            /tmp/

            # Bundler lockfile for gems
            Gemfile.lock

            # Claude Code settings
            .claude/
          TEXT
          File.write("#{gem_name}/.gitignore", content)
        end

        def author
          options[:author] || `git config user.name`.strip
        end

        def email
          options[:email] || `git config user.email`.strip
        end

        def license_type
          options[:license] || "wtfpl"
        end

        def create_lib_files
          create_version_file
          create_main_file
          create_plugin_entry
        end

        def create_version_file
          content = <<~RUBY
            # frozen_string_literal: true

            module Textbringer
              module #{module_name}
                VERSION = "0.1.0"
              end
            end
          RUBY
          File.write("#{gem_name}/lib/textbringer/#{name}/version.rb", content)
        end

        def create_main_file
          content = <<~RUBY
            # frozen_string_literal: true

            require_relative "#{name}/version"

            module Textbringer
              # Define faces for syntax elements
              # Face.define :#{name}_keyword, foreground: "cyan", bold: true

              class #{class_name} < Mode
                self.file_name_pattern = /\\.#{name}\\z/i

                # Define your syntax highlighting here
                # define_syntax :#{name}_keyword, /your_pattern/

                def initialize(buffer)
                  super(buffer)
                  @buffer[:indent_tabs_mode] = false
                  @buffer[:tab_width] = 2
                end
              end
            end
          RUBY
          File.write("#{gem_name}/lib/textbringer/#{name}.rb", content)
        end

        def create_plugin_entry
          content = <<~RUBY
            # frozen_string_literal: true

            require "textbringer/#{name}"
          RUBY
          File.write("#{gem_name}/lib/textbringer_plugin.rb", content)
        end

        def camelize(string)
          string.split(/[-_]/).map(&:capitalize).join
        end
      end
    end
  end
end
