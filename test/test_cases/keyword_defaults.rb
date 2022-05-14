class TestParser < Minitest::Test
  def test_keyword_defaults_arguments_single_args
    tests = [
    {"args":["favorite_fruit=apple"], "input": "",
    "result": {"favorite_fruit" => ["apple"]}, "exception": nil},

    {"args":["true_or_false=true"], "input": "",
    "result": {"true_or_false" => [true]}, "exception": nil},

    {"args":["true_or_false=123"], "input": "",
    "result": {"true_or_false" => [123]}, "exception": nil},

    {"args":["favorite_fruit=\"apple\""], "input": "",
    "result": {"favorite_fruit" => ["apple"]}, "exception": nil},

    {"args":["favorite_fruit=\"He says, 'I hate peanuts'\""], "input": "",
    "result": {"favorite_fruit" => ["He says, 'I hate peanuts'"]}, "exception": nil},

    {"args":["favorite_fruit=\'She replies, \"Do you mean the comic?\"\'"], "input": "",
    "result": {"favorite_fruit" => ["She replies, \"Do you mean the comic?\""]}, "exception": nil},

    {"args":["favorite_fruit=\"He replies, \\\"'Do you mean the comic?' No, the comic is kinda nice\\\"\""], "input": "",
    "result": {"favorite_fruit" => ["He replies, \"'Do you mean the comic?' No, the comic is kinda nice\""]}, "exception": nil},
    ]
    _test(tests, "test_keyword_defaults_arguments")
  end

  def test_keyword_defaults_arguments_multiple_args
    tests = [
    {"args":["arg1", "arg2", "arg3=sauce"], "input": "arg1: apple arg2: vinegar",
    "result": {"arg1" => ["apple"], "arg2" => ["vinegar"], "arg3" => ["sauce"]}, "exception": nil},

    {"args":["arg1", "arg2=pineapple", "arg3"], "input": "arg1: apple arg3: vinegar",
    "result": {"arg1" => ["apple"], "arg2" => ["pineapple"], "arg3" => ["vinegar"]}, "exception": nil},

    {"args":["arg1=apple", "arg2=pineapple", "arg3"], "input": "arg3: vinegar",
    "result": {"arg1" => ["apple"], "arg2" => ["pineapple"], "arg3" => ["vinegar"]}, "exception": nil},

    {"args":["*arg1=apple"], "input": "",
    "result": {"arg1" => ["apple"]}, "exception": nil},

    {"args":["*arg1=apple"], "input": "super duper hyper quack",
    "result": {"arg1" => ["super", "duper", "hyper", "quack"]}, "exception": nil},

    {"args":["arg1", "*arg2", "arg3=quack"], "input": "super duper hyper",
    "result": {"arg1" => ["super"], "arg2" => ["duper", "hyper"], "arg3" => ["quack"]}, "exception": nil},

    {"args":["arg1=something", "*arg2"], "input": "super duper hyper",
    "result": {"arg1" => ["super"], "arg2" => ["duper", "hyper"]}, "exception": nil},

    {"args":["arg1=something", "arg2=123", "arg3=nil"], "input": "",
    "result": {"arg1" => ["something"], "arg2" => [123], "arg3" => [nil]}, "exception": nil},
    ]
    _test(tests, "test_keyword_defaults_arguments")
  end

  def test_keyword_default_arguments_lists
    tests = [
    {"args":["arg1=[this is a list]"], "input": "",
    "result": {"arg1" => [["this", "is", "a", "list"]]}, "exception": nil},

    {"args":["arg1=[1 2 3]"], "input": "",
    "result": {"arg1" => [[1, 2, 3]]}, "exception": nil},

    {"args":["arg1=nil", "arg2=  [1 2 3]"], "input": "",
    "result": {"arg1" => [nil], "arg2" => [[1, 2, 3]]}, "exception": nil},

    {"args":["arg1", "*arg2", "arg3=  [[[1 2 3]]]"], "input": "potato vinegar sauce",
    "result": {"arg1" => ["potato"], "arg2" => ["vinegar", "sauce"], "arg3" => [[[[1, 2, 3]]]]}, "exception": nil},
    ]
    _test(tests, "test_default_arguments_lists")
  end

  def test_keyword_defaults_arguments_errors
    tests = [
    {"args":["arg1=something", "arg2", "arg3"], "input": "super",
    "result": nil, "exception": ParserErrors::NotEnoughArgumentsError},
    ]
    _test(tests, "test_keyword_defaults_arguments")
  end
end
