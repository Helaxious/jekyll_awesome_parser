require "minitest/autorun"
require_relative "../lib/jekyll-awesome-parser.rb"

class TestPositionalArguments < Minitest::Test
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

  def test_basic_positional_arguments_and_star_args()
    tests = [
      {"args" => ["arg1"], "input" => "\"jokes\"",
      "result" => {"arg1" => ["jokes"]}, "exception" => nil},

      {"args" => ["arg1", "arg2"], "input" => "\"jokes\" \"fun_facts\"",
      "result" => {"arg1" => ["jokes"], "arg2" => ["fun_facts"]}, "exception" => nil},

      {"args" => ["*arg1"], "input" => "\"jokes\" \"fun_facts\"",
      "result" => {"arg1" => ["jokes", "fun_facts"]}, "exception" => nil},

      {"args" => ["arg1", "*arg2"], "input" => "\"jokes\" \"fun_facts\"",
      "result" => {"arg1" => ["jokes"], "arg2" => ["fun_facts"]}, "exception" => nil},

      {"args" => ["arg1", "*arg2"], "input" => "\"jokes\" \"fun_facts\" \"games\"",
      "result" => {"arg1" => ["jokes"], "arg2" => ["fun_facts", "games"]}, "exception" => nil}
      ]
    _test(tests, "test_basic_positional_arguments_and_star_args")
  end

  def test_positional_arguments_and_star_args_exceptions()
    tests = [
      {"args" => ["arg1", "arg2", "arg3"], "input" => "\"jokes\" \"fun_facts\" \"games\"\"",
      "result" => nil, "exception" => ParserErrors::StringNotClosedError},

      {"args" => ["arg1", "*arg2", "arg3"], "input" => "\"jokes\" \"fun_facts\" \"games\"",
      "result" => nil, "exception" => ParserErrors::MissingKeywordArgumentError},

      {"args" => ["arg1"], "input" => "\\\"jokes\"",
      "result" => nil, "exception" => ParserErrors::InvalidCharacterError},

      {"args" => ["*arg1"], "input" => ": \"jokes\"",
      "result" => nil, "exception" => ParserErrors::InvalidKeywordError},

      {"args" => ["*arg1"], "input" => "aaa\\aaa: \"jokes\"",
      "result" => nil, "exception" => ParserErrors::InvalidKeywordError},

      {"args" => ["arg1"], "input" => "\"jokes\" \"fun_facts\"",
      "result" => nil, "exception" => ParserErrors::TooMuchArgumentsError},

      {"args" => ["arg1", "arg2"], "input" => "\"jokes\"",
      "result" => nil, "exception" => ParserErrors::NotEnoughArgumentsError},

      {"args" => ["arg1", "arg2"], "input" => "\"jokes\" \"something else",
      "result" => nil, "exception" => ParserErrors::StringNotClosedError}]
    _test(tests, "test_positional_arguments_and_star_args_exceptions")
  end
  def test_mix_double_single_no_quotes_positional()
    tests = [
      {"args" => ["*recipe"], "input" => "\"potato\" \'milk\'",
      "result" => {"recipe" => ["potato", "milk"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "'potato' 'onion' 'milk'",
      "result" => {"arg1" => ["potato"], "arg2" => ["onion"], "arg3" => ["milk"]}, "exception" => nil},

      {"args" => ["arg1", "*arg2", "arg3"], "input" => "arg1: \'potato\' \"onion\" \'tomato\' arg3: \"garlic\"",
      "result" => {"arg1" => ["potato"], "arg2" => ["onion", "tomato"], "arg3" => ["garlic"]}, "exception" => nil},

      {"args" => ["*recipe"], "input" => "potato \"milk\"",
      "result" => {"recipe" => ["potato", "milk"]}, "exception" => nil},

      {"args" => ["*recipe"], "input" => "potato \"milk\" tomato \'onion\' \"garlic\"",
      "result" => {"recipe" => ["potato", "milk", "tomato", "onion", "garlic"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "potato \"milk\" tomato",
      "result" => {"arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["tomato"]}, "exception" => nil}]
    _test(tests, "test_mix_double_single_no_quotes_positional")
  end
end
