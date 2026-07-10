# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "rubygems"
require "textbringer/plugin/generator"
require "textbringer/plugin/generator/cli"

class CoreGenerationTest < Test::Unit::TestCase
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

  test "default invocation creates the expected file set" do
    generate

    expected_files = %w[
      textbringer-foo.gemspec
      Gemfile
      Rakefile
      .gitignore
      lib/textbringer_plugin.rb
      lib/textbringer/foo.rb
      lib/textbringer/foo/version.rb
      test/test_helper.rb
      test/textbringer_foo_test.rb
      README.md
      LICENSE.txt
    ]

    expected_files.each do |path|
      assert(File.exist?("textbringer-foo/#{path}"), "expected textbringer-foo/#{path} to exist")
    end
  end

  test "generated gemspec is valid and named textbringer-<name>" do
    generate

    spec = Dir.chdir("textbringer-foo") { Gem::Specification.load("textbringer-foo.gemspec") }

    assert_not_nil(spec)
    assert_equal("textbringer-foo", spec.name)
  end

  test "name normalization: underscored name constantizes correctly" do
    generate("my_plugin")

    content = File.read("textbringer-my_plugin/lib/textbringer/my_plugin.rb")
    assert do
      content.include?("class MyPluginMode < Mode")
    end

    version_content = File.read("textbringer-my_plugin/lib/textbringer/my_plugin/version.rb")
    assert do
      version_content.include?("module MyPlugin")
    end
  end

  test "name normalization: hyphenated name constantizes correctly" do
    generate("my-plugin")

    content = File.read("textbringer-my-plugin/lib/textbringer/my-plugin.rb")
    assert do
      content.include?("class MyPluginMode < Mode")
    end

    version_content = File.read("textbringer-my-plugin/lib/textbringer/my-plugin/version.rb")
    assert do
      version_content.include?("module MyPlugin")
    end
  end

  test "CLI new invocation generates a plugin" do
    Textbringer::Plugin::Generator::CLI.start(["new", "clitest"])

    assert(File.exist?("textbringer-clitest/textbringer-clitest.gemspec"))
  end
end
