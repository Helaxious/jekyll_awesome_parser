class TestParser < Minitest::Test
  def test_lists()
    tests = [
    {"args":["recipe"], "input": "recipe: ['brown sugar', \"flour\" love 12, false]",
    "result": {"recipe" => [["brown sugar", "flour", "love", 12, false]]}, "exception": nil},

    {"args":["recipe"], "input": "recipe: [['brown sugar'], \"flour\" love [12], false]",
    "result": {"recipe" => [[["brown sugar"], "flour", "love", [12], false]]}, "exception": nil},

    {"args":["recipe"], "input": "recipe: [['brown sugar'], \"flour\" love [[[[12]]]], false]",
    "result": {"recipe" => [[["brown sugar"], "flour", "love", [[[[12]]]], false]]}, "exception": nil},

    {"args":["*recipe"], "input": "recipe: cake['brown sugar', \"flour\" love 12, false]3_servings",
    "result": {"recipe" => ["cake", ["brown sugar", "flour", "love", 12, false], "3_servings"]}, "exception": nil},

    {"args":["*recipe"], "input": "recipe: \'cake\'['brown sugar', \"flour\" love 12, false]\"3_servings\"",
    "result": {"recipe" => ["cake", ["brown sugar", "flour", "love", 12, false], "3_servings"]}, "exception": nil},

    {"args":["arg1"], "input": "[1 2 3]",
    "result": {"arg1" => [[1, 2, 3]]}, "exception": nil},

    {"args":["arg1", "arg2", "arg3"], "input": "potato [1 2 3] avocado",
    "result": {"arg1" => ["potato"], "arg2" => [[1, 2, 3]], "arg3" => ["avocado"]}, "exception": nil},

    {"args":["arg1", "*arg2", "arg3=nil"], "input": "potato [1 2 3]",
    "result": {"arg1" => ["potato"], "arg2" => [[1, 2, 3]], "arg3" => [nil]}, "exception": nil},

    {"args":["arg1=nil", "*arg2", "arg3=nil"], "input": "arg2: [1 2 3]",
    "result": {"arg1" => [nil], "arg2" => [[1, 2, 3]], "arg3" => [nil]}, "exception": nil},

    {"args":["*arg1", "arg2=nil", "arg3=nil"], "input": "arg1: [1 2 3]",
    "result": {"arg1" => [[1, 2, 3]], "arg2" => [nil], "arg3" => [nil]}, "exception": nil},

    {"args":["arg1", "arg2", "arg3"], "input": "arg1: [1 2 3] arg2: [[1]] arg3: [false]",
    "result": {"arg1" => [[1, 2, 3]], "arg2" => [[[1]]], "arg3" => [[false]]}, "exception": nil},

    {"args":["arg1", "arg2", "arg3"], "input": "arg2: [1 2 3] arg3: [[1]] arg1: [false]",
    "result": {"arg1" => [[false]], "arg2" => [[1, 2, 3]], "arg3" => [[[1]]]}, "exception": nil},

    {"args":["arg1", "arg2", "arg3"], "input": "[1 2 3] [[1]] [false]",
    "result": {"arg1" => [[1, 2, 3]], "arg2" => [[[1]]], "arg3" => [[false]]}, "exception": nil},
    ]
    _test(tests, "test_lists")
  end

  # Tests the parser option of automatically convert types
  def test_no_automatic_conversion()
    tests = [
    {"args":["arg1", "arg2", "arg3"], "input": "123, false, \"potato\"",
    "result": {"arg1" => ["123"], "arg2" => ["false"], "arg3" => ["potato"]}, "exception": nil},

    {"args":["arg1", "arg2", "arg3"], "input": "123 [1, 2, 3] false",
    "result": {"arg1" => ["123"], "arg2" => [["1", "2", "3"]], "arg3" => ["false"]}, "exception": nil},

    {"args":["arg1: num", "arg2: list", "arg3: bool", "arg4: str"], "input": "123 [1, 2, 3] false aaa",
    "result": {"arg1" => [123], "arg2" => [["1", "2", "3"]], "arg3" => [false], "arg4" => ["aaa"]},
    "exception": nil},
    ]
    _test(tests, "test_no_automatic_conversion", false)
  end

  def test_typed_method_arguments_same_types()
    tests = [
    {"args":["article: str"], "input": "article: 'How I was raised by a bear'",
    "result": {"article" => ["How I was raised by a bear"]}, "exception": nil},

    {"args":["year: num"], "input": "year: 1970",
    "result": {"year" => [1970]}, "exception": nil},

    {"args":["pi: num"], "input": "pi: 3.14159",
    "result": {"pi" => [3.14159]}, "exception": nil},

    {"args":["awesome: bool"], "input": "awesome: true",
    "result": {"awesome" => [true]}, "exception": nil},

    {"args":["awesome: bool"], "input": "awesome: false",
    "result": {"awesome" => [false]}, "exception": nil},

    {"args":["recipe: list"], "input": "recipe: ['two eggs', 'one cup of flour', 'love']",
    "result": {"recipe" => [['two eggs', 'one cup of flour', 'love']]}, "exception": nil},
    ]
    _test(tests, "test_typed_method_arguments_same_types")
  end

  def test_typed_method_arguments_different_types()
    tests = [
    [["year: str"], "year: 1970"],
    [["year: bool"], "year: 1970"],
    [["year: list"], "year: 1970"],

    [["year: str"], "year: [1970]"],
    [["year: num"], "year: [1970]"],
    [["year: bool"], "year: [1970]"],

    [["year: num"], "year: \"1970\""],
    [["year: bool"], "year: \"1970\""],
    [["year: list"], "year: \"1970\""],

    [["year: str"], "year: true"],
    [["year: num"], "year: true"],
    [["year: list"], "year: true"],

    [["year: str", "age: num", "recipe: list"], "year: \"1970\" age: 20 aaa"],
    [["year: num", "age: num", "recipe: list"], "year: \"1970\" age: 20 [1, 2, 3]"],
    [["year", "age: num", "recipe: list"], "year: \"1970\" age: 20 123"],
    [["*year: num"], "1 2 3 4 arg"],
    ]
    _test_wrong_type_errors(tests)
  end

  def test_type_star_args
    tests = [
    {"args":["*recipe: str"], "input": "recipe: 'flour' 'sugar' 'salt' 'chocolate'",
    "result": {"recipe" => ["flour", "sugar", "salt", "chocolate"]}, "exception": nil},

    {"args":["*true_or_false: bool"], "input": "false false true true false",
    "result": {"true_or_false" => [false, false, true, true, false]}, "exception": nil},

    {"args":["*true_or_false: num"], "input": "12 23 34 45 56",
    "result": {"true_or_false" => [12, 23, 34, 45, 56]}, "exception": nil},

    {"args":["*true_or_false: list"], "input": "[12] [23] [34] [45] [56]",
    "result": {"true_or_false" => [[12], [23], [34], [45], [56]]}, "exception": nil},

    {"args":["*recipe: str"], "input": "recipe: 'flour' 123 'salt' 'chocolate'",
    "result": {"recipe" => nil}, "exception": TypeError},

    {"args":["arg1", "*recipe: str", "something: list"], "input": "recipe: 'flour' 123 'salt' ['chocolate']",
    "result": {"recipe" => nil}, "exception": TypeError},

    {"args":["arg1", "*recipe: str", "something: list"], "input": "recipe: 'flour' 'salt' ['chocolate']",
    "result": {"recipe" => nil}, "exception": TypeError},

    {"args":["*true_or_false: bool"], "input": "false false 123 true false",
    "result": {"true_or_false" => nil}, "exception": TypeError},

    {"args":["*true_or_false: num"], "input": "112 5353 123 12 false",
    "result": {"true_or_false" => nil}, "exception": TypeError},

    {"args":["*true_or_false: list"], "input": "[1, 2, 3] [12] ['123'] 23",
    "result": {"true_or_false" => nil}, "exception": TypeError},
    ]
    _test(tests, "test_type_star_args")
  end

  def test_validate_developer_arguments
    # Note that this test's asserts number is actually half what it's supposed to be
    tests = [
      ["cat", "[Wrong Arg Type]"],
      [[""], "[Empty Argument]"],
      [[false], "[Wrong Arg Type]"],
      [[nil], "[Wrong Arg Type]"],
      [[123], "[Wrong Arg Type]"],

      [["arg1 = potato\""], "[Unclosed String]"],
      [["arg1 = \'potato\""], "[Unclosed String]"],
      [["arg1 = \"\"potato\""], "[Unclosed String]"],
      [["arg1 = \"\'potato\""]],

      [["arg1 a"], "[Argument Name With Space]"],
      [["arg1:"], "[Empty Type]"],
      [["arg1:="], "[Empty Type]"],
      [["arg1: int =1"], "[Optional Arg After Type]"],
      [["arg1: int ="], "[Optional Arg After Type]"],
      [["arg1: in t"], "[Type Name With Space]"],
      [["arg1:in t"], "[Type Name With Space]"],
      [["arg1: type_that_doesnt_exist"], "[Invalid Type]"],
      [["arg1: int"], "[Invalid Type]"],
      [["arg1: float"], "[Invalid Type]"],
      [["0arg1"], "[Argument Starts With Number]"],
      [["01233123123123arg1"], "[Argument Starts With Number]"],
      [["arg1="], "[Empty Optional Argument]"],
      [["arg1=nil:"], "[Empty Type]"],

      [["arg1=ni l"], "[Optional Argument With Space]"],
      [["arg1=  ni l"], "[Optional Argument With Space]"],
      [["arg1=  ni l: num"], "[Optional Argument With Space]"],
      [["arg1  =  ni l: num"], "[Optional Argument With Space]"],
      [["arg1=  ni l: int"], "[Invalid Type]"],

      [["arg1= ]"], "[Unclosed List]"],
      [["arg1= ["], "[Unclosed List]"],
      [["arg1= []]"], "[Unclosed List]"],
      [["arg1= [[]"], "[Unclosed List]"],

      [["arg1= ] : num"], "[Unclosed List]"],
      [["arg1= [ : num"], "[Unclosed List]"],
      [["arg1= []] : num"], "[Unclosed List]"],
      [["arg1= [[] : num"], "[Unclosed List]"],

      [["arg1= potato[]potato : num"], "[Multiple Arguments]"],
      [["arg1= potato [] potato : num"], "[Multiple Arguments]"],
      [["arg1= [] potato : num"], "[Multiple Arguments]"],
      [["arg1= potato [] : num"], "[Multiple Arguments]"],

      [["number=nil : num"]],
      [["number=nil:num"]],
      [["number = nil:num"]],
      [["number =nil :num"]],
      [["number =   nil: num"]],
      [["number=   nil:num"]],
      [["number       =   nil:num"]],

      [["arg1 = 'potatochips'"]],
      [["arg1 = \"potatochips\""]],

      [["arg1 = 'potato chips'"]],
      [["arg1 = 'ketchup with maionnaise'"]],
      [["arg1 = 'spaghetti with meatballs'"]],

      [["arg1 = \"\\\"potato\""]],
      [["arg1 = \"\\\"potato\\\"\""]],
      [["arg1 = \"\'potato\""]],
      [["arg1 = '\"potato'"]],
      [["arg1 = \"\'\\\"potato\\\"\'\""]],
    ]
    _test_validate_developer_arguments(tests)
  end
end
