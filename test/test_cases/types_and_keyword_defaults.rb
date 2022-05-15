class TestParser < Minitest::Test
  def test_types_and_keyword_defaults
    tests = [
    {"args":["number=nil : num"], "input": "number: 123",
    "result": {"number" => [123]}, "exception": nil},

    {"args":["number   = nil: num"], "input": "",
    "result": {"number" => [nil]}, "exception": nil},

    {"args":["number=asdasd:list"], "input": "",
    "result": {"number" => ["asdasd"]}, "exception": nil},

    {"args":["number=    [1 2 3]:list"], "input": "[1 2 3]",
    "result": {"number" => [[1, 2, 3]]}, "exception": nil},

    {"args":["number=[1 2 3]: list"], "input": "",
    "result": {"number" => [[1, 2, 3]]}, "exception": nil},

    {"args":["number   =false: bool"], "input": "",
    "result": {"number" => [false]}, "exception": nil},

    {"args":["number  =false :bool"], "input": "true",
    "result": {"number" => [true]}, "exception": nil},

    {"args":["number  =    false     :   bool"], "input": "true",
    "result": {"number" => [true]}, "exception": nil},

    {"args":["number  =    123     :   bool"], "input": "",
    "result": {"number" => [123]}, "exception": nil},

    {"args":["number = [123]: list"], "input": "",
    "result": {"number" => [[123]]}, "exception": nil},

    {"args":["arg1", "number = [123]: list"], "input": "potato",
    "result": {"arg1" => ["potato"], "number" => [[123]]}, "exception": nil},

    {"args":["arg1", "*lists = [123]: list", "arg3=nil"], "input": "potato [1] [\"abc\"] [[[false]]]",
    "result": {"arg1" => ["potato"], "lists" => [[1], ["abc"], [[[false]]]], "arg3" => [nil]}, "exception": nil},

    {"args":["*quotes=nil: str", "*exclude=nil: str"], "input": "exclude: art",
    "result": {"quotes" => [nil], "exclude" => ["art"]}, "exception": nil},
    ]
    _test(tests, "test_types_and_keyword_defaults")
  end

  def test_types_and_keyword_defaults_exceptions
    tests = [
    [["number    =  [123]   :   list"], "123"],
    [["number    =spinach :   str"], "false"],
    [["number    =  nil   : num"], "\"something\""],
    [["number =  3.1415   : bool"], "[\"potato\"]"],
    ]
    _test_wrong_type_errors(tests)
  end
end
