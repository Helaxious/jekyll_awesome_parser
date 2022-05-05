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

end
