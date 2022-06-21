# frozen_string_literal: true

class TestParser < Minitest::Test
  def test_keyword_arguments_and_star_args
    tests = [
    { "args" => ["arg1"], "input" => "arg1: \"jokes\"",
      "result" => { "arg1" => ["jokes"] }, "exception" => nil },

    { "args" => ["*arg1", "arg2"], "input" => "arg1: \"jokes\" \"fun_facts\" \"games\" arg2: \"web_dev\"",
      "result" => { "arg1" => ["jokes", "fun_facts", "games"], "arg2" => ["web_dev"] }, "exception" => nil },

    { "args" => ["arg1", "arg2"], "input" => "arg2: \"jokes\" arg1: \"fun_facts\"",
      "result" => { "arg1" => ["fun_facts"], "arg2" => ["jokes"] }, "exception" => nil },

    { "args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\"",
      "result" => { "arg1" => ["fun_facts", "web_dev"], "arg2" => ["jokes", "games"] }, "exception" => nil }
    ]

    _test(tests, "test_keyword_arguments_and_star_args")
  end

  def test_keyword_arguments_and_star_args_exceptions
    tests = [
    { "args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3:",
      "result" => nil, "exception" => get_parser_error("EmptyKeywordError") },

    { "args" => ["*arg1", "*arg2"], "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3:",
      "result" => nil, "exception" => get_parser_error("EmptyKeywordError") },

    { "args" => ["*arg1", "*arg2"],
      "input" => "arg2: \"jokes\" \"games\" arg1: \"fun_facts\" \"web_dev\" arg3: \"aaa\"",
      "result" => nil, "exception" => get_parser_error("UnexpectedKeywordError") },

    { "args" => ["arg1"], "input" => "\"jokes\" include:",
      "result" => nil, "exception" => get_parser_error("EmptyKeywordError") }
    ]

    _test(tests, "test_keyword_arguments_and_star_args_exceptions")
  end

  def test_mix_double_single_no_quotes_keywords
    tests = [
    { "args" => ["arg1", "arg2"], "input" => "arg1: potato arg2: \"milk\"",
      "result" => { "arg1" => ["potato"], "arg2" => ["milk"] }, "exception" => nil },

    { "args" => ["arg1", "arg2", "arg3"], "input" => "potato arg2: \"milk\" arg3: \'vinegar\'",
      "result" => { "arg1" => ["potato"], "arg2" => ["milk"], "arg3" => ["vinegar"] }, "exception" => nil },

    { "args" => ["arg1", "arg2", "arg3"], "input" => "potato arg3: \"milk\" arg2: \'vinegar\'",
      "result" => { "arg1" => ["potato"], "arg2" => ["vinegar"], "arg3" => ["milk"] }, "exception" => nil },

    { "args" => ["breakfast", "lunch", "dinner"], "input" => "\"orange_juice\",lunch:\'spaghetti\',dinner:\"fruit_salad\",",
      "result" => { "breakfast" => ["orange_juice"], "lunch" => ["spaghetti"], "dinner" => ["fruit_salad"] },
      "exception" => nil }
    ]

    _test(tests, "test_mix_double_single_no_quotes_keywords")
  end
end
