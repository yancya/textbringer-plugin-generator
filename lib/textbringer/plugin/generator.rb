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
          create_test_files
          create_readme
          create_license
          puts "Created #{gem_name}/"
        end

        private

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
          content = <<~RUBY
            # frozen_string_literal: true

            require_relative "lib/textbringer/#{name}/version"

            Gem::Specification.new do |spec|
              spec.name = "#{gem_name}"
              spec.version = Textbringer::#{module_name}::VERSION
              spec.authors = [#{author.inspect}]
              spec.email = [#{email.inspect}]

              spec.summary = "#{module_name} mode for Textbringer"
              spec.description = "A Textbringer plugin that provides #{name} mode support with syntax highlighting."
              spec.homepage = "https://github.com/#{github_user}/#{gem_name}"
              spec.license = "#{license_type.upcase}"
              spec.required_ruby_version = ">= 3.2.0"

              spec.metadata["allowed_push_host"] = "https://rubygems.org"
              spec.metadata["homepage_uri"] = spec.homepage
              spec.metadata["source_code_uri"] = "https://github.com/#{github_user}/#{gem_name}"

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
          test_gem = case test_framework
                     when "rspec"
                       'gem "rspec", "~> 3.0"'
                     when "minitest"
                       'gem "minitest", "~> 5.0"'
                     else
                       'gem "test-unit"'
                     end

          content = <<~RUBY
            # frozen_string_literal: true

            source "https://rubygems.org"

            gemspec

            gem "irb"
            gem "rake", "~> 13.0"
            #{test_gem}
          RUBY
          File.write("#{gem_name}/Gemfile", content)
        end

        def create_rakefile
          content = case test_framework
                    when "rspec"
                      <<~RUBY
                        # frozen_string_literal: true

                        require "bundler/gem_tasks"
                        require "rspec/core/rake_task"

                        RSpec::Core::RakeTask.new(:spec)

                        task default: :spec
                      RUBY
                    when "minitest"
                      <<~RUBY
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
                    else
                      <<~RUBY
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
                    end

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
          <<~RUBY
            # Mock Textbringer for testing without the actual dependency
            module Textbringer
              class Face
                def self.define(name, **options)
                  # Mock Face.define
                end
              end

              class Mode
                attr_reader :buffer

                def initialize(buffer)
                  @buffer = buffer
                end

                def self.define_syntax(face, pattern)
                  # Mock define_syntax
                end

                def self.file_name_pattern
                  @file_name_pattern
                end

                def self.file_name_pattern=(pattern)
                  @file_name_pattern = pattern
                end
              end
            end
          RUBY
        end

        def create_rspec_helper
          content = <<~RUBY
            # frozen_string_literal: true

            $LOAD_PATH.unshift File.expand_path("../lib", __dir__)

            #{textbringer_mock_code.strip}

            require "textbringer/#{name}"
          RUBY
          File.write("#{gem_name}/spec/spec_helper.rb", content)
        end

        def create_rspec_file
          content = <<~RUBY
            # frozen_string_literal: true

            require "spec_helper"

            RSpec.describe Textbringer::#{module_name} do
              it "has a version number" do
                expect(Textbringer::#{module_name}::VERSION).not_to be_nil
              end
            end

            RSpec.describe Textbringer::#{class_name} do
              it "exists" do
                expect(defined?(Textbringer::#{class_name})).to be_truthy
              end

              it "matches .#{name} files" do
                expect(Textbringer::#{class_name}.file_name_pattern).to match("test.#{name}")
              end
            end
          RUBY
          File.write("#{gem_name}/spec/textbringer_#{name.tr('-', '_')}_spec.rb", content)
        end

        def create_minitest_helper
          content = <<~RUBY
            # frozen_string_literal: true

            $LOAD_PATH.unshift File.expand_path("../lib", __dir__)

            #{textbringer_mock_code.strip}

            require "textbringer/#{name}"

            require "minitest/autorun"
          RUBY
          File.write("#{gem_name}/test/test_helper.rb", content)
        end

        def create_minitest_file
          test_class = name.split(/[-_]/).map(&:capitalize).join
          content = <<~RUBY
            # frozen_string_literal: true

            require "test_helper"

            class Textbringer::#{test_class}Test < Minitest::Test
              def test_version_is_defined
                assert Textbringer::#{module_name}.const_defined?(:VERSION)
              end

              def test_#{class_name.downcase}_class_exists
                assert defined?(Textbringer::#{class_name})
              end

              def test_file_pattern_matches_#{name.tr('-', '_')}_files
                assert_match Textbringer::#{class_name}.file_name_pattern, "test.#{name}"
              end
            end
          RUBY
          File.write("#{gem_name}/test/textbringer_#{name.tr('-', '_')}_test.rb", content)
        end

        def create_test_unit_helper
          content = <<~RUBY
            # frozen_string_literal: true

            $LOAD_PATH.unshift File.expand_path("../lib", __dir__)

            #{textbringer_mock_code.strip}

            require "textbringer/#{name}"

            require "test/unit"
          RUBY
          File.write("#{gem_name}/test/test_helper.rb", content)
        end

        def create_test_unit_file
          test_class = name.split(/[-_]/).map(&:capitalize).join
          content = <<~RUBY
            # frozen_string_literal: true

            require "test_helper"

            class Textbringer::#{test_class}Test < Test::Unit::TestCase
              test "VERSION is defined" do
                assert do
                  ::Textbringer::#{module_name}.const_defined?(:VERSION)
                end
              end

              test "#{class_name} class exists" do
                assert do
                  defined?(Textbringer::#{class_name})
                end
              end

              test "#{class_name} file pattern matches .#{name} files" do
                assert do
                  Textbringer::#{class_name}.file_name_pattern =~ "test.#{name}"
                end
              end
            end
          RUBY
          File.write("#{gem_name}/test/textbringer_#{name.tr('-', '_')}_test.rb", content)
        end

        def create_readme
          content = <<~MARKDOWN
            # #{gem_name.split('-').map(&:capitalize).join(' ')}

            A Textbringer plugin that provides #{name} mode support.

            ## Installation

            Install the gem by executing:

            ```bash
            gem install #{gem_name}
            ```

            Or add it to your Gemfile:

            ```bash
            bundle add #{gem_name}
            ```

            ## Usage

            The plugin is automatically loaded when you start Textbringer. Simply open any `.#{name}` file and the mode will be applied automatically.

            No additional configuration is required.

            ## Development

            After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

            To install this gem onto your local machine, run `bundle exec rake install`.

            ## Contributing

            Bug reports and pull requests are welcome on GitHub at https://github.com/#{github_user}/#{gem_name}.

            ## License

            The gem is available as open source under the terms of the [#{license_name}](#{license_url}).
          MARKDOWN
          File.write("#{gem_name}/README.md", content)
        end

        def create_license
          case license_type
          when "wtfpl"
            create_wtfpl_license
          when "apache-2.0"
            create_apache_license
          when "bsd-3-clause"
            create_bsd_license
          when "gpl-3.0"
            create_gpl_license
          else
            create_mit_license
          end
        end

        def create_wtfpl_license
          content = <<~LICENSE
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
            Version 2, December 2004

            Copyright (C) #{Time.now.year} #{author} <#{email}>

            Everyone is permitted to copy and distribute verbatim or modified
            copies of this license document, and changing it is allowed as long
            as the name is changed.

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
            TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

            0. You just DO WHAT THE FUCK YOU WANT TO.
          LICENSE
          File.write("#{gem_name}/LICENSE.txt", content)
        end

        def create_mit_license
          content = <<~LICENSE
            The MIT License (MIT)

            Copyright (c) #{Time.now.year} #{author}

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in
            all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
            THE SOFTWARE.
          LICENSE
          File.write("#{gem_name}/LICENSE.txt", content)
        end

        def create_apache_license
          content = <<~LICENSE
                                             Apache License
                                       Version 2.0, January 2004
                                    http://www.apache.org/licenses/

            TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

            1. Definitions.

               "License" shall mean the terms and conditions for use, reproduction,
               and distribution as defined by Sections 1 through 9 of this document.

               "Licensor" shall mean the copyright owner or entity authorized by
               the copyright owner that is granting the License.

               "Legal Entity" shall mean the union of the acting entity and all
               other entities that control, are controlled by, or are under common
               control with that entity. For the purposes of this definition,
               "control" means (i) the power, direct or indirect, to cause the
               direction or management of such entity, whether by contract or
               otherwise, or (ii) ownership of fifty percent (50%) or more of the
               outstanding shares, or (iii) beneficial ownership of such entity.

               "You" (or "Your") shall mean an individual or Legal Entity
               exercising permissions granted by this License.

               "Source" form shall mean the preferred form for making modifications,
               including but not limited to software source code, documentation
               source, and configuration files.

               "Object" form shall mean any form resulting from mechanical
               transformation or translation of a Source form, including but
               not limited to compiled object code, generated documentation,
               and conversions to other media types.

               "Work" shall mean the work of authorship, whether in Source or
               Object form, made available under the License, as indicated by a
               copyright notice that is included in or attached to the work.

               "Derivative Works" shall mean any work, whether in Source or Object
               form, that is based on (or derived from) the Work and for which the
               editorial revisions, annotations, elaborations, or other modifications
               represent, as a whole, an original work of authorship.

               "Contribution" shall mean any work of authorship, including
               the original version of the Work and any modifications or additions
               to that Work or Derivative Works thereof, that is intentionally
               submitted to the Licensor for inclusion in the Work by the copyright owner.

               "Contributor" shall mean Licensor and any individual or Legal Entity
               on behalf of whom a Contribution has been received by Licensor and
               subsequently incorporated within the Work.

            2. Grant of Copyright License. Subject to the terms and conditions of
               this License, each Contributor hereby grants to You a perpetual,
               worldwide, non-exclusive, no-charge, royalty-free, irrevocable
               copyright license to reproduce, prepare Derivative Works of,
               publicly display, publicly perform, sublicense, and distribute the
               Work and such Derivative Works in Source or Object form.

            3. Grant of Patent License. Subject to the terms and conditions of
               this License, each Contributor hereby grants to You a perpetual,
               worldwide, non-exclusive, no-charge, royalty-free, irrevocable
               (except as stated in this section) patent license to make, have made,
               use, offer to sell, sell, import, and otherwise transfer the Work.

            4. Redistribution. You may reproduce and distribute copies of the
               Work or Derivative Works thereof in any medium, with or without
               modifications, and in Source or Object form, provided that You
               meet the following conditions:

               (a) You must give any other recipients of the Work or
                   Derivative Works a copy of this License; and

               (b) You must cause any modified files to carry prominent notices
                   stating that You changed the files; and

               (c) You must retain, in the Source form of any Derivative Works
                   that You distribute, all copyright, patent, trademark, and
                   attribution notices from the Source form of the Work; and

               (d) If the Work includes a "NOTICE" text file as part of its
                   distribution, then any Derivative Works that You distribute must
                   include a readable copy of the attribution notices contained
                   within such NOTICE file.

            5. Submission of Contributions. Unless You explicitly state otherwise,
               any Contribution intentionally submitted for inclusion in the Work
               by You to the Licensor shall be under the terms and conditions of
               this License, without any additional terms or conditions.

            6. Trademarks. This License does not grant permission to use the trade
               names, trademarks, service marks, or product names of the Licensor.

            7. Disclaimer of Warranty. Unless required by applicable law or
               agreed to in writing, Licensor provides the Work on an "AS IS" BASIS,
               WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND.

            8. Limitation of Liability. In no event and under no legal theory,
               whether in tort (including negligence), contract, or otherwise,
               shall any Contributor be liable to You for damages, including any
               direct, indirect, special, incidental, or consequential damages.

            9. Accepting Warranty or Additional Liability. While redistributing
               the Work or Derivative Works thereof, You may choose to offer,
               and charge a fee for, acceptance of support, warranty, indemnity,
               or other liability obligations and/or rights consistent with this
               License.

            END OF TERMS AND CONDITIONS

            Copyright #{Time.now.year} #{author}

            Licensed under the Apache License, Version 2.0 (the "License");
            you may not use this file except in compliance with the License.
            You may obtain a copy of the License at

                http://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software
            distributed under the License is distributed on an "AS IS" BASIS,
            WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            See the License for the specific language governing permissions and
            limitations under the License.
          LICENSE
          File.write("#{gem_name}/LICENSE.txt", content)
        end

        def create_bsd_license
          content = <<~LICENSE
            BSD 3-Clause License

            Copyright (c) #{Time.now.year}, #{author}
            All rights reserved.

            Redistribution and use in source and binary forms, with or without
            modification, are permitted provided that the following conditions are met:

            1. Redistributions of source code must retain the above copyright notice, this
               list of conditions and the following disclaimer.

            2. Redistributions in binary form must reproduce the above copyright notice,
               this list of conditions and the following disclaimer in the documentation
               and/or other materials provided with the distribution.

            3. Neither the name of the copyright holder nor the names of its
               contributors may be used to endorse or promote products derived from
               this software without specific prior written permission.

            THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
            AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
            IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
            DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
            FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
            DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
            SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
            CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
            OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
            OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
          LICENSE
          File.write("#{gem_name}/LICENSE.txt", content)
        end

        def create_gpl_license
          content = <<~LICENSE
                                GNU GENERAL PUBLIC LICENSE
                                   Version 3, 29 June 2007

            Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
            Everyone is permitted to copy and distribute verbatim copies
            of this license document, but changing it is not allowed.

                                        Preamble

            The GNU General Public License is a free, copyleft license for
            software and other kinds of works.

            The licenses for most software and other practical works are designed
            to take away your freedom to share and change the works.  By contrast,
            the GNU General Public License is intended to guarantee your freedom to
            share and change all versions of a program--to make sure it remains free
            software for all its users.

            For the full license text, see <https://www.gnu.org/licenses/gpl-3.0.txt>

            Copyright #{Time.now.year} #{author}

            This program is free software: you can redistribute it and/or modify
            it under the terms of the GNU General Public License as published by
            the Free Software Foundation, either version 3 of the License, or
            (at your option) any later version.

            This program is distributed in the hope that it will be useful,
            but WITHOUT ANY WARRANTY; without even the implied warranty of
            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
            GNU General Public License for more details.

            You should have received a copy of the GNU General Public License
            along with this program.  If not, see <https://www.gnu.org/licenses/>.
          LICENSE
          File.write("#{gem_name}/LICENSE.txt", content)
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
