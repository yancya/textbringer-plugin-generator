# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "textbringer/plugin/generator"

class MockProvenanceTest < Test::Unit::TestCase
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

  [
    ["test-unit", "textbringer-foo/test/test_helper.rb"],
    ["minitest", "textbringer-foo/test/test_helper.rb"],
    ["rspec", "textbringer-foo/spec/spec_helper.rb"],
  ].each do |framework, helper_path|
    test "--test-framework=#{framework} helper carries the mock's provenance comment" do
      generate("foo", test_framework: framework)

      content = File.read(helper_path)
      assert(content.include?("shugo/textbringer"))
      assert(content =~ /synced against Textbringer v\d+/)
    end
  end
end
