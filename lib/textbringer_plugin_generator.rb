# frozen_string_literal: true

require_relative "textbringer/plugin/generator/version"
require_relative "textbringer/plugin/generator/cli"
require_relative "textbringer/plugin/generator"

module Textbringer
  module Plugin
    module Generator
      class Error < StandardError; end
    end
  end
end
