# frozen_string_literal: true

require "erb"
require "fileutils"

module Textbringer
  module Plugin
    module Generator
      class Generator
        TEMPLATES_DIR = File.expand_path("../../../../templates", __FILE__)

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
          create_test_files
          create_readme
          create_license
          create_ci_workflow
          create_github_workflow
          create_claude_md
          puts "Created #{gem_name}/"
        end

        private

        def render_template(relative_path, template_binding)
          path = File.join(TEMPLATES_DIR, relative_path)
          ERB.new(File.read(path), trim_mode: "-").result(template_binding)
        end

        def create_directory_structure
          FileUtils.mkdir_p(gem_name)
          FileUtils.mkdir_p("#{gem_name}/lib/textbringer/#{name}")
          if test_framework == "rspec"
            FileUtils.mkdir_p("#{gem_name}/spec")
          else
            FileUtils.mkdir_p("#{gem_name}/test")
          end
          FileUtils.mkdir_p("#{gem_name}/.github/workflows")
        end

        def create_gemspec
          content = render_template("gemspec.erb", binding)
          File.write("#{gem_name}/#{gem_name}.gemspec", content)
        end

        def create_gemfile
          test_gem = case test_framework
                     when "rspec"
                       'gem "rspec", "~> 3.0"'
                     when "minitest"
                       'gem "minitest", "~> 5.0"'
                     else
                       'gem "test-unit"'
                     end

          content = render_template("Gemfile.erb", binding)
          File.write("#{gem_name}/Gemfile", content)
        end

        def create_rakefile
          template = test_framework == "rspec" ? "Rakefile.rspec.erb" : "Rakefile.test.erb"
          content = render_template(template, binding)
          File.write("#{gem_name}/Rakefile", content)
        end

        def create_gitignore
          content = render_template("gitignore.erb", binding)
          File.write("#{gem_name}/.gitignore", content)
        end

        def author
          options[:author] || `git config user.name`.strip
        end

        def github_user
          # Try to get GitHub username, fallback to sanitized author name
          github = `git config github.user`.strip
          return github unless github.empty?

          # Remove spaces and non-alphanumeric characters for URL safety
          author.gsub(/\s+/, '').gsub(/[^a-zA-Z0-9-]/, '')
        end

        def email
          options[:email] || `git config user.email`.strip
        end

        def license_type
          options[:license] || "wtfpl"
        end

        def test_framework
          options[:test_framework] || "test-unit"
        end

        def create_lib_files
          create_version_file
          create_main_file
          create_plugin_entry
        end

        def create_version_file
          content = render_template("version.rb.erb", binding)
          File.write("#{gem_name}/lib/textbringer/#{name}/version.rb", content)
        end

        def create_main_file
          content = render_template("main.rb.erb", binding)
          File.write("#{gem_name}/lib/textbringer/#{name}.rb", content)
        end

        def create_plugin_entry
          content = render_template("plugin_entry.rb.erb", binding)
          File.write("#{gem_name}/lib/textbringer_plugin.rb", content)
        end

        def create_test_files
          case test_framework
          when "rspec"
            create_rspec_helper
            create_rspec_file
          when "minitest"
            create_minitest_helper
            create_minitest_file
          else
            create_test_unit_helper
            create_test_unit_file
          end
        end

        def textbringer_mock_code
          render_template("_textbringer_mock.rb.erb", binding)
        end

        def create_rspec_helper
          mock_code = textbringer_mock_code.strip
          content = render_template("rspec/spec_helper.rb.erb", binding)
          File.write("#{gem_name}/spec/spec_helper.rb", content)
        end

        def create_rspec_file
          content = render_template("rspec/spec_file.rb.erb", binding)
          File.write("#{gem_name}/spec/textbringer_#{name.tr('-', '_')}_spec.rb", content)
        end

        def create_minitest_helper
          mock_code = textbringer_mock_code.strip
          content = render_template("minitest/test_helper.rb.erb", binding)
          File.write("#{gem_name}/test/test_helper.rb", content)
        end

        def create_minitest_file
          test_class = name.split(/[-_]/).map(&:capitalize).join
          content = render_template("minitest/test_file.rb.erb", binding)
          File.write("#{gem_name}/test/textbringer_#{name.tr('-', '_')}_test.rb", content)
        end

        def create_test_unit_helper
          mock_code = textbringer_mock_code.strip
          content = render_template("test_unit/test_helper.rb.erb", binding)
          File.write("#{gem_name}/test/test_helper.rb", content)
        end

        def create_test_unit_file
          test_class = name.split(/[-_]/).map(&:capitalize).join
          content = render_template("test_unit/test_file.rb.erb", binding)
          File.write("#{gem_name}/test/textbringer_#{name.tr('-', '_')}_test.rb", content)
        end

        def create_readme
          content = render_template("README.md.erb", binding)
          File.write("#{gem_name}/README.md", content)
        end

        def create_license
          template = case license_type
                     when "wtfpl" then "licenses/wtfpl.erb"
                     when "apache-2.0" then "licenses/apache-2.0.erb"
                     when "bsd-3-clause" then "licenses/bsd-3-clause.erb"
                     when "gpl-3.0" then "licenses/gpl-3.0.erb"
                     else "licenses/mit.erb"
                     end
          content = render_template(template, binding)
          File.write("#{gem_name}/LICENSE.txt", content)
        end

        def create_ci_workflow
          content = render_template("github/workflows/ci.yml.erb", binding)
          File.write("#{gem_name}/.github/workflows/ci.yml", content)
        end

        def create_github_workflow
          content = render_template("github/workflows/release.yml.erb", binding)
          File.write("#{gem_name}/.github/workflows/release.yml", content)
        end

        def create_claude_md
          content = render_template("CLAUDE.md.erb", binding)
          File.write("#{gem_name}/CLAUDE.md", content)
        end

        def license_name
          case license_type
          when "wtfpl" then "WTFPL"
          when "apache-2.0" then "Apache License 2.0"
          when "bsd-3-clause" then "BSD 3-Clause License"
          when "gpl-3.0" then "GNU GPL v3.0"
          else "MIT License"
          end
        end

        def license_url
          case license_type
          when "wtfpl" then "http://www.wtfpl.net/"
          when "apache-2.0" then "https://opensource.org/licenses/Apache-2.0"
          when "bsd-3-clause" then "https://opensource.org/licenses/BSD-3-Clause"
          when "gpl-3.0" then "https://www.gnu.org/licenses/gpl-3.0"
          else "https://opensource.org/licenses/MIT"
          end
        end

        def camelize(string)
          string.split(/[-_]/).map(&:capitalize).join
        end
      end
    end
  end
end
