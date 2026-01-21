# frozen_string_literal: true

require "test_helper"

class TextbringerPluginGeneratorTest < Test::Unit::TestCase
  test "VERSION is defined" do
    assert do
      ::Textbringer::Plugin::Generator.const_defined?(:VERSION)
    end
  end
end
