# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/jekyll_awesome_parser"
require_relative "test_cases/keyword_arguments"
require_relative "test_cases/keyword_defaults"
require_relative "test_cases/peek"
require_relative "test_cases/positional_arguments"
require_relative "test_cases/strings_and_etc"
require_relative "test_cases/types_and_parameters"
require_relative "test_cases/types_and_keyword_defaults"

class TestParser < Minitest::Test
  @@parser = JekyllAwesomeParser.new
  @@parser.deactivate_print_errors
  @@display_errors = false
  @@parser_errors = JekyllAwesomeParser::ParserErrors

  def get_parser_error(error)
    return JekyllAwesomeParser::ParserErrors.const_get(error)
  end

  def _test(tests, title=nil, convert_types=true)
    parse = @@parser.method(:parse_input)
    for test, i in tests.each_with_index
      args, input, result, exception = test.values

      if exception.nil?
        assert_equal(result, parse.call(args, input, convert_types, false))
      else
        assert_raises(exception) { parse.call(args, input, convert_types, print_errors=false) }
        if @@display_errors == true
          begin
            parse.call(args, input, convert_types, print_errors=false)
          rescue StandardError => func_exception
            puts "[#{title}]\n#{'='*25}\n[Test #{i} - Good Exception]"
            puts "#{'-'*15}\n#{func_exception}\n#{'-'*15}"
          end
        end
      end
    end
  end

  def _test_validate_parameters(tests)
    for test, i in tests.each_with_index
      if test.size == 1
        @@parser.validate_parameters(test[0])
        next
      end

      input, error_name = test
      func_message = assert_raises(TypeError) { @@parser.validate_parameters(input) }
      assert(func_message.to_s.start_with?(error_name), "'#{func_message}' should start with '#{error_name}'")

      if @@display_errors == true
        begin
          @@parser.validate_parameters(input)
        rescue TypeError => func_exception
          puts "#{'='*25}\n[Test #{i} - Good Exception]"
          puts "#{'-'*15}\n#{func_exception}\n#{'-'*15}"
        end
      end
    end
  end

  def _test_wrong_type_errors(tests)
    for test, i in tests.each_with_index
      methods, input = test
      func_message = assert_raises(TypeError) { @@parser.parse_input(methods, input, print_errors=false) }
      assert(func_message.to_s.start_with?("[Wrong Type]"), "'#{func_message}' should start with [Wrong Type]")

      if @@display_errors == true
        begin
          @@parser.parse_input(methods, input, print_errors=false)
        rescue TypeError => func_exception
          puts "#{'='*25}\n[Test #{i} - Good Exception]"
          puts "#{'-'*15}\n#{func_exception}\n#{'-'*15}"
        end
      end
    end
  end
end
