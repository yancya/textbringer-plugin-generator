# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "textbringer/plugin/generator"

class GeneratedCiWorkflowTest < Test::Unit::TestCase
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

  test "generates .github/workflows/ci.yml" do
    generate

    assert(File.exist?("textbringer-foo/.github/workflows/ci.yml"))
  end

  test "ci.yml triggers on push and pull_request" do
    generate

    content = File.read("textbringer-foo/.github/workflows/ci.yml")
    assert(content.include?("push:"))
    assert(content.include?("pull_request:"))
  end

  test "ci.yml matrix matches the generated gemspec's required_ruby_version floor" do
    generate

    content = File.read("textbringer-foo/.github/workflows/ci.yml")
    assert(content.include?("'3.3'"))

    gemspec = File.read("textbringer-foo/textbringer-foo.gemspec")
    assert(gemspec.include?('spec.required_ruby_version = ">= 3.3.0"'))
  end

  %w[test-unit minitest rspec].each do |framework|
    test "ci.yml runs the test suite for --test-framework=#{framework}" do
      generate("foo", test_framework: framework)

      content = File.read("textbringer-foo/.github/workflows/ci.yml")
      assert(content.include?("bundle exec rake"))
    end
  end
end
