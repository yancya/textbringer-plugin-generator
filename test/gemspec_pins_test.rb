# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "textbringer/plugin/generator"

class GemspecPinsTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.remove_entry(@tmpdir)
  end

  test "generated gemspec pins textbringer >= 25 and ruby >= 3.3.0" do
    Textbringer::Plugin::Generator::Generator.new("foo").generate

    content = File.read("textbringer-foo/textbringer-foo.gemspec")

    assert(content.include?('spec.add_dependency "textbringer", ">= 25"'))
    assert(content.include?('spec.required_ruby_version = ">= 3.3.0"'))
  end
end
