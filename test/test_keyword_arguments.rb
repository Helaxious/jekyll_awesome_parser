require "minitest/autorun"
require_relative "../lib/jekyll-awesome-parser.rb"

class TestKeywordArguments < Minitest::Test
  @@display_errors = false
  @@parser = JekyllAwesomeParser.new

  def setup
    @@display_errors = false
  end

  def _test(tests, title=nil, convert_types=true)
    # Shortening the name a bit
    parse = @@parser.method(:parse_arguments)
    for test, i in tests.each_with_index
      args, input, result, exception = test.values

      if exception == nil
        assert_equal(result, parse.call(args, input, convert_types))
      else
        assert_raises(exception) { parse.call(args, input, convert_types)}
        if @@display_errors == true
          begin
            parse.call(method_args=args, user_input=input, convert_types)
          rescue StandardError => func_exception
            puts "[#{title}]\n#{'='*25}\n[Test #{i} - Good Exception]"
            puts "#{'-'*15}\n#{func_exception}\n#{'-'*15}"
          end
        end
      end
    end
  end
  def test_keyword_arguments_and_star_args()
    tests = [
      {"args" => ["arg1"], "input" => "arg1: \"jokes\"",
      "result" => {"arg1" => ["jokes"]}, "exception" => nil},

      {"args" => ["*arg1", "arg2"], "input" => "arg1: \"jokes\" \"fun_facts\" \"games\" arg2: \"web_dev\"",
      "result" => {"arg1" => ["jokes", "fun_facts", "games"], "arg2" => ["web_dev"]}, "exception" => nil},

      {"args" => ["arg1", "arg2"], "input" => "arg2: \"jokes\" arg1: \"fun_facts\"",
      "result" => {"arg1" => ["fun_facts"], "arg2" => ["jokes"]}, "exception" => nil},

      {"args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\"",
      "result" => {"arg1" => ["fun_facts", "web_dev"], "arg2" => ["jokes", "games"]}, "exception" => nil}
      ]
    _test(tests, "test_keyword_arguments_and_star_args")
  end

  def test_keyword_arguments_and_star_args_exceptions()
    tests = [
      {"args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3:",
      "result" => nil, "exception" => ParserErrors::EmptyKeywordError},

      {"args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3:",
      "result" => nil, "exception" => ParserErrors::EmptyKeywordError},

      {"args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3: \"aaa\"", "result" => nil, "exception" => ParserErrors::UnexpectedKeywordError},

      {"args" => ["arg1"], "input" => "\"jokes\" include:",
      "result" => nil, "exception" => ParserErrors::EmptyKeywordError}]

    _test(tests, "test_keyword_arguments_and_star_args_exceptions")
  end
  def test_mix_double_single_no_quotes_keywords()
    tests = [
    {"args" => ["arg1", "arg2"], "input" => "arg1: potato arg2: \"milk\"",
    "result" => {"arg1" => ["potato"], "arg2" => ["milk"]}, "exception" => nil},

    {"args" => ["arg1", "arg2", "arg3"], "input" => "potato arg2: \"milk\" arg3: \'vinegar\'",
    "result" => {"arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["vinegar"]}, "exception" => nil},

    {"args" => ["arg1", "arg2", "arg3"], "input" => "potato arg3: \"milk\" arg2: \'vinegar\'",
    "result" => {"arg1" => ["potato"], "arg2" => ["vinegar"], "arg3" => ["milk"]}, "exception" => nil},

    {"args" => ["breakfast", "lunch", "dinner"], "input" => "\"orange_juice\",lunch:\'spaghetti\',dinner:\"fruit_salad\",",
    "result" => {"breakfast" => ["orange_juice"], "lunch" => ["spaghetti"], "dinner" => ["fruit_salad"]},
    "exception" => nil}
    ]

    _test(tests, "test_mix_double_single_no_quotes_keywords")
  end
end
