# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "open3"
require "textbringer/plugin/generator"

class PerOptionGenerationTest < Test::Unit::TestCase
  LICENSE_FIRST_LINES = {
    "wtfpl" => "DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE",
    "mit" => "The MIT License (MIT)",
    "apache-2.0" => "Apache License",
    "bsd-3-clause" => "BSD 3-Clause License",
    "gpl-3.0" => "GNU GENERAL PUBLIC LICENSE",
  }.freeze

  def setup
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.remove_entry(@tmpdir)
  end

  def generate(name = "foo", options = {})
    Textbringer::Plugin::Generator::Generator.new(name, options).generate
  end

  LICENSE_FIRST_LINES.each do |license, expected_snippet|
    test "--license=#{license} produces the right LICENSE.txt" do
      generate("foo", license: license)

      first_line = File.foreach("textbringer-foo/LICENSE.txt").first
      assert do
        first_line.include?(expected_snippet)
      end
    end
  end

  test "--test-framework=rspec generates spec/ with matching Rakefile and helper" do
    generate("foo", test_framework: "rspec")

    assert(File.exist?("textbringer-foo/spec/spec_helper.rb"))
    assert(File.exist?("textbringer-foo/spec/textbringer_foo_spec.rb"))

    rakefile = File.read("textbringer-foo/Rakefile")
    assert(rakefile.include?("RSpec::Core::RakeTask"))

    spec_file = File.read("textbringer-foo/spec/textbringer_foo_spec.rb")
    assert(spec_file.include?("RSpec.describe"))
  end

  test "--test-framework=minitest generates test/ with matching Rakefile and helper" do
    generate("foo", test_framework: "minitest")

    assert(File.exist?("textbringer-foo/test/test_helper.rb"))
    assert(File.exist?("textbringer-foo/test/textbringer_foo_test.rb"))

    helper = File.read("textbringer-foo/test/test_helper.rb")
    assert(helper.include?("minitest/autorun"))

    test_file = File.read("textbringer-foo/test/textbringer_foo_test.rb")
    assert(test_file.include?("Minitest::Test"))
  end

  test "--test-framework=test-unit (default) generates test/ with matching Rakefile and helper" do
    generate("foo", test_framework: "test-unit")

    assert(File.exist?("textbringer-foo/test/test_helper.rb"))
    assert(File.exist?("textbringer-foo/test/textbringer_foo_test.rb"))

    helper = File.read("textbringer-foo/test/test_helper.rb")
    assert(helper.include?('require "test/unit"'))

    test_file = File.read("textbringer-foo/test/textbringer_foo_test.rb")
    assert(test_file.include?("Test::Unit::TestCase"))
  end

  test "smoke test: a freshly generated default project's own tests pass" do
    generate("smoke")

    out, status = Dir.chdir("textbringer-smoke") do
      Open3.capture2e("ruby", "-Ilib:test", "test/textbringer_smoke_test.rb")
    end

    assert(status.success?, "expected generated project's tests to pass, got:\n#{out}")
  end
end
