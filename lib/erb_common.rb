
module Webrake
  module ErbCommon
    def erb_result(erb, data)
      data.each do |key, value|
        self.instance_variable_set("@#{key}", value)
      end
      erb.result(binding)
    end

    if ARGV[0] == 'test'
      require 'byebug'
      require "minitest/autorun"
      require "erb"
      class ErbCommonTest < Minitest::Unit::TestCase
        include Webrake::ErbCommon

        def test_erb_result
          assert_equal('10', erb_result(ERB.new('<%= @number * 5%>', nil, '>'), {:number => 2}))
        end
      end
    end
  end
end
