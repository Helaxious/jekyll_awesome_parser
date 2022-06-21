# frozen_string_literal: true

class TestParser < Minitest::Test
  def test_peek
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

  def test_peek_until
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
      assert_equal(@@parser.peek_until(*input), result)
    end
  end

  def test_peek_until_not
    tests = [
    [["       potato", 0, "right", " "], [true, "match", 7]],
    [[" a      ", 1, "right", " "], [false, "no_match", 8]],
    [[" a      ", 1, "left", " "], [false, "no_match", -1]],
    [[" a      ", 5, "left", " "], [true, "match", 1]],
    [[" a     a ", 5, "right", " "], [true, "match", 7]],
    [[" aaaaaaa ", 5, "right", "a"], [true, "match", 8]],
    [[" aaaaaaa ", 5, "left", "a"], [true, "match", 0]]
    ]

    for (input, result) in tests
      assert_equal(@@parser.peek_until_not(*input), result)
    end
  end

  def test_peek_after
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
end
