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

  def test_peek()
    tests = [
    [["abcdcba", 2, "right", "d", ""],  [true, "match", 3]],
    [["abcdcba", 4, "left", "d", ""],   [true, "match", 3]],
    [["abcdcba", 2, "right", "", "d"],  [false, "stop", 3]],
    [["abcdcba", 4, "left", "", "d"],   [false, "stop", 3]],
    [["abcdcba", 2, "right", "c", ""],  [false, "no_match", 3]],
    [["abcdcba", 4, "left", "c", ""],   [false, "no_match", 3]],
    [["abcdcba", 10, "right", "c", ""], [false, "end_of_string", 6]],
    [["abcdcba", -1, "right", "c", ""], [false, "no_match", 0]],
    [["abcdcba", 10, "left", "c", ""],  [false, "end_of_string", 6]],
    [["abcdcba", 2, "right", ["c", "d", "a"], ""],     [true, "match", 3]],
    [["abcdcba", 2, "right", "", ["c", "d", "a"], ""], [false, "stop", 3]]
    ]
    for (input, result) in tests
      string, pointer, direction, target, stop = input
      assert_equal(@@parser.peek(string, pointer, direction, target, stop), result)
    end
  end

  def test_peek_until()
    tests = [
    [["abcdcba", 0, "right", "d", ""], [true, "match", 3]],
    [["abcdcba", 0, "right", "", ""], [false, "end_of_string", 6]],
    [["abcdcba", 0, "right", "", "d"], [false, "stop", 3]],
    [["abcdcba", 6, "right", "", "d"], [false, "end_of_string", 6]],
    [["abcdcba", 6, "left", "", "d"], [false, "stop", 3]],
    [["abcdcba", 6, "left", "d", ""], [true, "match", 3]],
    [["abc  d  cba", 10, "left", "d", ""], [true, "match", 5]],
    [["abc  d  cba", 10, "left", "d", " "], [false, "stop", 7]]
    ]
    for (input, result) in tests
      string, pointer, direction, target, stop = input
      self.assert_equal(@@parser.peek_until(*input), result)
    end
  end

  def test_peek_until_not()
    tests = [
    [["       potato", 0, "right", " "], [true, "match", 7]],
    [[" a      ", 1, "right", " "], [false, "no_match", 8]],
    [[" a      ", 1, "left", " "], [false, "no_match", -1]],
    [[" a      ", 5, "left", " "], [true, "match", 1]],
    [[" a     a ", 5, "right", " "], [true, "match", 7]],
    [[" aaaaaaa ", 5, "right", "a"], [true, "match", 8]],
    [[" aaaaaaa ", 5, "left", "a"], [true, "match", 0]],
    ]
    for (input, result) in tests
      string, pointer, direction, target, stop = input
      assert_equal(@@parser.peek_until_not(*input), result)
    end
  end

  def test_peek_after()
    tests = [
    [[" aaaaaaa ", 0, "right", " ", "a"],  [false, "no_match", 0]],
    [["  aaaaaaa ", 0, "right", " ", "a"], [true, "match", 2]],
    [["aaaaaaa ", 0, "right", "a", " "],   [true, "match", 7]],
    [["  aaaaaaa", 5, "left", "a", " "],   [true, "match", 1]],
    [["aa     ", 5, "left", " ", "a"],     [true, "match", 1]]
    ]
    for (input, result) in tests
      string, pointer, direction, target, target_after = input
      assert_equal(@@parser.peek_after(string, pointer, direction, target, target_after), result)
    end
  end

  def test_clean_args()
    tests = [
    [{"arg1" => 1, "arg2" => 3}, {"arg1" => 1, "arg2" => 3}],
    [{"arg1=None" => 1, "*arg2" => 3}, {"arg1" => 1, "arg2" => 3}]
    ]
    for (input, result) in tests
      assert_equal(@@parser.clean_args(input), result)
    end
  end

  def test_init_variables()
    method_args,input = [["*arg1", "arg2=None", "arg3"], "potato"]
    test_parser = JekyllAwesomeParser.new
    test_parser.init_variables(method_args, input)

    clean_lookup = test_parser.instance_variable_get(:@clean_lookup)
    dirty_lookup = test_parser.instance_variable_get(:@dirty_lookup)
    parsed_result = test_parser.instance_variable_get(:@parsed_result)

    assert_equal(clean_lookup, {"arg1" => "*arg1", "arg2" => "arg2=None", "arg3" => "arg3"})
    assert_equal(dirty_lookup, {"*arg1" => "arg1", "arg2=None" => "arg2", "arg3" => "arg3"})
    assert_equal(parsed_result, {"*arg1" => [], "arg2=None" => [], "arg3" => []})
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
    skip "lol"
    tests = [
      {"args" => ["arg1", "arg2", "arg3"], "input" => "\"jokes\" \"fun_facts\" \"games\"\"",
      "result" => nil, "exception" => ParserErrors.StringNotClosed},

      {"args" => ["arg1", "*arg2", "arg3"], "input" => "\"jokes\" \"fun_facts\" \"games\"",
      "result" => nil, "exception" => ParserErrors.MissingKeywordArgument},

      {"args" => ["arg1"], "input" => "\\\"jokes\"",
      "result" => nil, "exception" => ParserErrors.InvalidCharacter},

      {"args" => ["*arg1"], "input" => ": \"jokes\"",
      "result" => nil, "exception" => ParserErrors.InvalidKeyword},

      {"args" => ["*arg1"], "input" => "aaa\\aaa: \"jokes\"",
      "result" => nil, "exception" => ParserErrors.InvalidKeyword},

      {"args" => ["arg1"], "input" => "\"jokes\" \"fun_facts\"",
      "result" => nil, "exception" => ParserErrors.TooMuchArguments},

      {"args" => ["arg1", "arg2"], "input" => "\"jokes\"",
      "result" => nil, "exception" => ParserErrors.NotEnoughArguments},

      {"args" => ["arg1", "arg2"], "input" => "\"jokes\" \"something else",
      "result" => nil, "exception" => ParserErrors.StringNotClosed}]
    _test(tests, "test_positional_arguments_and_star_args_exceptions")
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
    skip "lol"
    tests = [
      {"args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3:",
      "result" => nil, "exception" => ParserErrors.EmptyKeyword},

      {"args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3:",
      "result" => nil, "exception" => ParserErrors.EmptyKeyword},

      {"args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3: \"aaa\"", "result" => nil, "exception" => ParserErrors.UnexpectedKeyword},

      {"args" => ["arg1"], "input" => "\"jokes\" include:",
      "result" => nil, "exception" => ParserErrors.EmptyKeyword}]

    _test(tests, "test_keyword_arguments_and_star_args_exceptions")
  end

  def test_commas()
    tests = [
      {"args" => ["*arg1"], "input" => "\"jokes\", \"something else\", \"games\"",
      "result" => {"arg1" => ["jokes", "something else", "games"]}, "exception" => nil},

      {"args" => ["*arg1"], "input" => ",,\"jokes\",,,, ,,,,\"something else\",,,, ,,,,\"games\",,,",
      "result" => {"arg1" => ["jokes", "something else", "games"]}, "exception" => nil},

      {"args" => ["*arg1"], "input" => ",,\"jokes\"\"something else\",,\"games\",,,,,,",
      "result" => {"arg1" => ["jokes", "something else", "games"]}, "exception" => nil},

      {"args" => ["*arg1"], "input" => ",,\'jokes\'\'something else\',,\"games\",,,,,,",
      "result" => {"arg1" => ["jokes", "something else", "games"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => ",potato, ,\"milk\", tomato,",
      "result" => {"arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["tomato"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => ",potato, ,\"milk\", tomato,",
      "result" => {"arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["tomato"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => ",,,,,,,potato,,,,,, ,,,,,\"milk\",,,,, tomato,,,,,",
      "result" => {"arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["tomato"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => ",,\"potato\" , \"milk\" ,,, \'tomato\',,,",
      "result" => {"arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["tomato"]}, "exception" => nil},

      {"args" => ["*arg1"], "input" => ",,aa,\"bb\",,,\'tomato\',,,\"cc\"\"aa\"\"dd\"\"dd\"",
      "result" => {"arg1" => ["aa", "bb", "tomato", "cc", "aa", "dd", "dd"]}, "exception" => nil},

      {"args" => ["*arg1"], "input" => ",aa,\"bb\",\'tomato\',\"cc\",\"aa\",\"dd\",\"dd\",",
      "result" => {"arg1" => ["aa", "bb", "tomato", "cc", "aa", "dd", "dd"]}, "exception" => nil}]
    _test(tests, "test_commas")
  end

  def test_stringless_arguments()
    tests = [
      {"args" => ["cat"], "input" => "cat: orange_with_black_stripes",
      "result" => {"cat" => ["orange_with_black_stripes"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "apple vinegar sauce",
      "result" => {"arg1" => ["apple"], "arg2" => ["vinegar"], "arg3" => ["sauce"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "arg3: apple arg2: vinegar arg1: sauce",
      "result" => {"arg1" => ["sauce"], "arg2" => ["vinegar"], "arg3" => ["apple"]}, "exception" => nil},

      {"args" => ["*cat"], "input" => "cat: japanese_bobtail maltese",
      "result" => {"cat" => ["japanese_bobtail", "maltese"]}, "exception" => nil},

      # {"args" => ["cat"], "input" => "cat: orange_with_black_stripes\"",
      # "result" => nil, "exception" => ParserErrors.StringNotClosed},

      {"args" => ["cat", "color"], "input" => "cat: orange_with_black_stripes color: orange",
      "result" => {"cat" => ["orange_with_black_stripes"], "color" => ["orange"]}, "exception" => nil},

      {"args" => ["cat", "color"], "input" => "orange_with_black_stripes color: orange",
      "result" => {"cat" => ["orange_with_black_stripes"], "color" => ["orange"]}, "exception" => nil},

      {"args" => ["*breakfast", "lunch"], "input" => "orange_juice,cereal,apple,water,lunch:spaghetti",
      "result" => {"breakfast" => ["orange_juice", "cereal", "apple", "water"], "lunch" => ["spaghetti"]}, "exception" => nil},

      {"args" => ["breakfast", "lunch", "dinner"], "input" => "orange_juice,lunch:spaghetti,dinner:fruit_salad,",
      "result" => {"breakfast" => ["orange_juice"], "lunch" => ["spaghetti"], "dinner" => ["fruit_salad"]}, "exception" => nil}
    ]
    _test(tests, "test_stringless_arguments")
  end

  def test_mix_double_single_no_quotes_positional()
    tests = [{"args" => ["*recipe"], "input" => "\"potato\" \'milk\'",
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

  def test_mix_double_single_no_quotes_keywords()
    tests = [{"args" => ["arg1", "arg2"], "input" => "arg1: potato arg2: \"milk\"",
      "result" => {"arg1" => ["potato"], "arg2" => ["milk"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "potato arg2: \"milk\" arg3: \'vinegar\'",
      "result" => {"arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["vinegar"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "potato arg3: \"milk\" arg2: \'vinegar\'",
      "result" => {"arg1" => ["potato"], "arg2" => ["vinegar"], "arg3" => ["milk"]}, "exception" => nil},

      {"args" => ["breakfast", "lunch", "dinner"], "input" => "\"orange_juice\",lunch:\'spaghetti\',dinner:\"fruit_salad\",",
      "result" => {"breakfast" => ["orange_juice"], "lunch" => ["spaghetti"], "dinner" => ["fruit_salad"]},
      "exception" => nil}]

    _test(tests, "test_mix_double_single_no_quotes_keywords")
  end

  def test_developer_type_errors()
    skip "Haven't implemented this feature yet lol"
    tests = [
    {"args" => ["cat"], "input": "cat: orange_with_black_stripes",
    "result": None, "exception": TypeError},
    ]
    _test(tests, "test_developer_type_errors")
  end

  def test_types()
    skip "Haven't implemented this feature yet lol"
    tests = [
    {"args":["year: int"], "input": "year: 1970",
    "result": {"year": 1970}, "exception": None},
    ]
    _test(tests, "test_types")
  end
end
