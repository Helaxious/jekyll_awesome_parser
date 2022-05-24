class TestParser < Minitest::Test
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
      "result" => nil, "exception" => get_parser_error("StringNotClosedError")},

      {"args" => ["arg1", "*arg2", "arg3"], "input" => "\"jokes\" \"fun_facts\" \"games\"",
      "result" => nil, "exception" => get_parser_error("MissingKeywordArgumentError")},

      {"args" => ["arg1"], "input" => "\\\"jokes\"",
      "result" => nil, "exception" => get_parser_error("InvalidCharacterError")},

      {"args" => ["*arg1"], "input" => ": \"jokes\"",
      "result" => nil, "exception" => get_parser_error("InvalidKeywordError")},

      {"args" => ["*arg1"], "input" => "aaa\\aaa: \"jokes\"",
      "result" => nil, "exception" => get_parser_error("InvalidKeywordError")},

      {"args" => ["arg1"], "input" => "\"jokes\" \"fun_facts\"",
      "result" => nil, "exception" => get_parser_error("TooMuchArgumentsError")},

      {"args" => ["arg1", "arg2"], "input" => "\"jokes\"",
      "result" => nil, "exception" => get_parser_error("NotEnoughArgumentsError")},

      {"args" => ["arg1", "arg2"], "input" => "\"jokes\" \"something else",
      "result" => nil, "exception" => get_parser_error("StringNotClosedError")}]
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
