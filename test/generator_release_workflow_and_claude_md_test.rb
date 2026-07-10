# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "textbringer/plugin/generator"

class GeneratorReleaseWorkflowAndClaudeMdTest < Test::Unit::TestCase
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

  test "generates .github/workflows/release.yml" do
    generate

    assert do
      File.exist?("textbringer-foo/.github/workflows/release.yml")
    end
  end

  test "release.yml grants id-token: write for Trusted Publishing" do
    generate

    content = File.read("textbringer-foo/.github/workflows/release.yml")
    assert do
      content.include?("id-token: write")
    end
  end

  test "release.yml is parameterized with the generated gem name" do
    generate("bar")

    content = File.read("textbringer-bar/.github/workflows/release.yml")
    assert do
      content.include?("textbringer-bar")
    end
  end

  test "generates CLAUDE.md" do
    generate

    assert do
      File.exist?("textbringer-foo/CLAUDE.md")
    end
  end

  test "CLAUDE.md mentions the dev commands and plugin entry point" do
    generate

    content = File.read("textbringer-foo/CLAUDE.md")
    assert do
      content.include?("bundle exec rake test") &&
        content.include?("lib/textbringer_plugin.rb")
    end
  end

  test "README notes that the Trusted Publisher must be registered before release" do
    generate

    content = File.read("textbringer-foo/README.md")
    assert do
      content.include?("Trusted Publisher")
    end
  end
end
