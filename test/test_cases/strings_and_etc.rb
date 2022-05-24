class TestParser < Minitest::Test
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

      # This somehow gave an error, I don't even know how
      {"args" => ["*numbers"], "input" => "1 2 3",
      "result" => {"numbers" => [1, 2, 3]}, "exception" => nil},

      {"args" => ["*numbers"], "input" => "a b c",
      "result" => {"numbers" => ["a", "b", "c"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "apple vinegar sauce",
      "result" => {"arg1" => ["apple"], "arg2" => ["vinegar"], "arg3" => ["sauce"]}, "exception" => nil},

      {"args" => ["arg1", "arg2", "arg3"], "input" => "arg3: apple arg2: vinegar arg1: sauce",
      "result" => {"arg1" => ["sauce"], "arg2" => ["vinegar"], "arg3" => ["apple"]}, "exception" => nil},

      {"args" => ["*cat"], "input" => "cat: japanese_bobtail maltese",
      "result" => {"cat" => ["japanese_bobtail", "maltese"]}, "exception" => nil},

      {"args" => ["cat"], "input" => "cat: orange_with_black_stripes\"",
      "result" => nil, "exception" => get_parser_error("StringNotClosedError")},

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

  def test_mix_match_quotes
    tests = [
    {"args":["sentence"], "input": "sentence: \"He says, 'I hate peanuts'\"",
    "result": {"sentence" => ["He says, 'I hate peanuts'"]}, "exception": nil},

    {"args":["sentence"], "input": 'sentence: \'She replies, "Do you mean the comic?"\'',
    "result": {"sentence" => ["She replies, \"Do you mean the comic?\""]}, "exception": nil},

    {"args":["sentence"],
    "input": "sentence: \"He replies, \\\"'Do you mean the comic?' No, the comic is kinda nice\\\"\"",
    "result": {"sentence" => ["He replies, \"'Do you mean the comic?' No, the comic is kinda nice\""]},
    "exception": nil},

    {"args":["character"], "input": "character: \" ' \"",
    "result": {"character" => ["'"]}, "exception": nil},

    {"args":["character"], "input": "character: ' \" '",
    "result": {"character" => ["\""]}, "exception": nil},

    {"args":["character"], "input": "character: '\"\\'\"'",
    "result": {"character" => ["\"'\""]}, "exception": nil},
    ]
    _test(tests, "test_mix_match_quotes")
  end

  def test_mix_match_quotes_unclosed_string
    # It should only raise an error if only the surrounding quotes are missing
    tests = [
    {"args":["sentence"], "input": "sentence: \"He says, 'I hate peanuts'",
    "result": nil, "exception": get_parser_error("StringNotClosedError")},

    {"args":["sentence"], "input": 'sentence: \'She replies, "Do you mean the comic?"',
    "result": nil, "exception": get_parser_error("StringNotClosedError")},

    {"args":["sentence"],
    "input": "sentence: \"He replies, \\\"'Do you mean the comic?' No, the comic is kinda nice\\\"",
    "result": nil, "exception": get_parser_error("StringNotClosedError")},
    ]
    _test(tests, "test_mix_match_quotes_unclosed_string")
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
    test_parser.init_variables(method_args, input, false, false)

    clean_lookup = test_parser.instance_variable_get(:@clean_lookup)
    dirty_lookup = test_parser.instance_variable_get(:@dirty_lookup)
    parsed_result = test_parser.instance_variable_get(:@parsed_result)

    assert_equal(clean_lookup, {"arg1" => "*arg1", "arg2" => "arg2=None", "arg3" => "arg3"})
    assert_equal(dirty_lookup, {"*arg1" => "arg1", "arg2=None" => "arg2", "arg3" => "arg3"})
    assert_equal(parsed_result, {"*arg1" => [], "arg2=None" => [], "arg3" => []})
  end

  def test_empty_strings()
    tests = [
    {"args" => ["arg1"], "input": "''",
    "result": {"arg1" => [""]}, "exception": nil},
    ]
    _test(tests, "test_developer_type_errors")
  end

  def test_empty_input()
    tests = [
    {"args" => ["arg1"], "input": "",
    "result": nil, "exception": get_parser_error("NotEnoughArgumentsError")},

    {"args" => ["arg1=123", "arg2=312", "arg3"], "input": "",
    "result": nil, "exception": get_parser_error("NotEnoughArgumentsError")},
    ]
    _test(tests, "test_developer_type_errors")
  end
end
