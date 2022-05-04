require "minitest/autorun"
require_relative "../lib/jekyll-awesome-parser.rb"

class TestParser < Minitest::Test
  @@display_errors = false
  @@parser = JekyllAwesomeParser.new

  def toggle_display_errors
    @@display_errors = true
  end

  def setup
    @@display_errors = true
  end

  def _test(tests, title=nil)
    # Shortening the name a bit
    parse = @@parser.method(:parse_arguments)
    for test, i in tests.each_with_index
      args, input, result, exception = test.values

      if exception == nil
        assert_equal(result, parse.call(args, input))
      else
        assert_raises(exception) { parse.call(args, input )}
        if @@display_errors == true
          begin
            parse.call(method_args=args, user_input=input)
          rescue StandardError => func_exception
            puts "[#{title}]\n#{'='*25}\n[Test #{i} - Good Exception]"
            puts "#{'-'*15}\n#{func_exception}\n#{'-'*15}"
          end
        end
      end
    end
  end

  def test_basic_positional_arguments_and_star_args
    tests = [
      {"args":["arg1",], "input": "\"jokes\"",
      "result": {'arg1': ['jokes',]}, "exception": nil},

      {"args":["arg1", "arg2"], "input": "\"jokes\" \"fun_facts\"",
      "result": {'arg1': ['jokes',], 'arg2': ['fun_facts',]}, "exception": nil},

      {"args":["*arg1",], "input": "\"jokes\" \"fun_facts\"",
      "result": {'arg1': ['jokes', 'fun_facts']}, "exception": nil},

      {"args":["arg1", "*arg2"], "input": "\"jokes\" \"fun_facts\"",
      "result": {'arg1': ['jokes',], 'arg2': ['fun_facts',]}, "exception": nil},

      {"args":["arg1", "*arg2"], "input": "\"jokes\" \"fun_facts\" \"games\"",
      "result": {'arg1': ['jokes',], 'arg2': ['fun_facts', 'games']}, "exception": nil}
    ]
    _test(tests)
  end
end
