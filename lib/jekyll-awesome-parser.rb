require_relative "parser_errors.rb"

class JekyllAwesomeParser

  # Looks if there's an letter in a string in the left, or in the right of the pointer
  def peek(string, pointer, direction, target, stop=nil)
    stop = Array(stop) if stop.class == String
    target = Array(target) if target.class == String

    direction = ({"left" => -1, "right" => 1})[direction]
    if (0 <= pointer + direction) and (pointer + direction <= string.size - 1)
      if target.include?(string[pointer + direction])
        return [true, "match", pointer + direction]
      end
      if stop != nil && (stop.include?(string[pointer + direction]))
        return [false, "stop", pointer + direction]
      end
      return [false, "no_match", pointer + direction]
    end
    return [false, "end_of_string", string.size - 1]
  end

  # Peeks continuously in one direction, and returns True if it eventually matches
  def peek_until(string, pointer, direction, target, stop=nil)
    pointer_direction = ({"left" => -1, "right" => 1})[direction]
    peek_pointer = pointer
    while true
      peek_pointer += pointer_direction
      result = peek(string, peek_pointer, direction, target, stop)
      if ["match", "end_of_string", "stop"].include?(result[1])
        return result
      end
    end
  end

  # Returns True if the peek_until eventually doesn't match
  def peek_until_not(string, pointer, direction, target)
    pointer_direction = ({"left" => -1, "right" => 1})[direction]
    peek_pointer = pointer
    while true
      peek_pointer += pointer_direction
      result = peek(string, peek_pointer, direction, target, nil)
      if result[1] == "no_match"
        return [true, "match", peek_pointer + pointer_direction]
      end
      if result[1] == "end_of_string"
        return [false, "no_match", peek_pointer + pointer_direction]
      end
    end
  end

  # Does a peek_until, then does a peek (eg: peek_until ' ' then peeks for the letter '(')
  # '       (potato)'  #  '(potato)'
  #  ^      ^ match!   #   ^ doesn't match!
  #  pointer           # pointer
  def peek_after(string, pointer, direction, target, target_after, stop=nil)
    stop = [] if stop === nil
    stop = Array(stop) if stop.class == String
    target_after = Array(target_after) if target_after.class == String

    if peek(string, pointer, "right", target)[0] == true
      second_peek = peek_until_not(string, pointer, direction, target)
      return second_peek if second_peek[0] == "no_match"

      is_stop = stop.include?(string[second_peek[2]])
      return [false, "stop", second_peek[2]] if is_stop
      return [target_after.include?(string[second_peek[2]]), "match", second_peek[2]]
    else
      return [false, "no_match", pointer]
    end
  end

  # Gets the arg name from the methods arguments list (eg: "arg1=nil" becomes "arg1")
  def clean_args(arguments)
    clean_arguments = {}
    for (key, value) in Array(arguments.clone())
      key = key[1..-1] if key.include?("*")
      key = key[0...key.index("=")] if key.include?("=")
      clean_arguments[key] = value
    end
    return clean_arguments
  end

  # Ruby's dicts are ordered by insertion, so order it based on the methods arguments list
  def order_result(arguments, result)
    return arguments.map{|key|[key, result[key]]}.to_h
  end

  # Grabs a specified error from the ParserErrors module, grabs some debug info, then returns the error
  def raise_parser_error(pointer, error, args=nil)
    error = ParserErrors.const_get(error)
    raise error.new({"user_input":@user_input, "pointer":pointer}, args)
  end

  def raise_parser_type_error(error, args=nil)
    error_method = ParserTypeErrors.send(error, args)
  end

  # Validates the given method arguments by an developer. Since they are given as a string
  def validate_developer_arguments(args)
    error_note = "(This is a developer error, this error should be fixed by the\n" +
                "developers and not the user, if you're the user, contact the developers!)"
    invalid_characters = "()[]\\`^~!#$%&<>?@{}'\".,;/+"
    type_list = ["num", "str", "list", "bool", "string", "boolean", "array"]

    if args.class != Array
      raise_parser_type_error("wrong_arg_list_type", {"arg_type" => args.class})
    end

    for arg in args
      # If argument is empty
      raise_parser_type_error("empty_argument", {"arg_name" => arg}) if arg == ""

      # If argument is the wrong type
      raise_parser_type_error("wrong_argument_type", {"arg_name" => arg, "arg_type" => arg.class}) if arg.class != String

      arg = arg.strip
      if %w[0 1 2 3 4 5 6 7 8 9].include? arg[0]
        raise_parser_type_error("arg_starts_with_number", {"arg_name" => arg})
      end

      # Checking invalid characters
      arg.split("").each do |letter|
        if invalid_characters.include? letter
          raise_parser_type_error("invalid_character", {"letter" => letter, "invalid_characters" => invalid_characters})
        end
      end

      if arg.include? ":" # If there's a type in the arg
        colon_pos = peek_until(arg, 0, "right", ":")[2]
        arg_type = peek_after(arg, colon_pos, "right", " ", "")

        if peek_until_not(arg, colon_pos, "right", " ")[1] == "no_match"
          raise_parser_type_error("empty_type", {"arg_name" => arg})
        end

        if peek_until(arg, colon_pos, "right", "=")[1] == "match"
          raise_parser_type_error("optional_arg_after_type", {"arg_name" => arg})
        end

        # If there's a space in the type name:
        if peek_until(arg, arg_type[2], "right", " ")[1] == "match"
          raise_parser_type_error("type_name_with_space", {"arg_name" => arg})
        end

        type_name = arg[(arg_type[2])..].strip
        if !type_list.include? type_name
          number_note = ["int", "float", "integer"].include? type_name
          raise_parser_type_error("wrong_type", {"type_name" => type_name, "number_note" => number_note, "type_list" => type_list})
        end
      end
      if arg.include? "=" # If the argument is optional
      end

      # If there's not a type nor is it optional, just check for spaces
      if arg.strip.include? " " and !(arg.include? ":" or arg.include? "=")
        raise_parser_type_error("arg_name_with_space", {"arg_name" => arg})
      end
    end
  end

  def init_variables(method_args, user_input)
    @user_input = user_input
    @method_args = method_args

    clean_args = clean_args(@method_args.map{|key|[key, []]}.to_h).keys()
    @clean_lookup = clean_args.zip(@method_args).map{|clean, dirty|[clean, dirty]}.to_h
    @dirty_lookup = clean_args.zip(@method_args).map{|clean, dirty|[dirty, clean]}.to_h

    @tmp_string = ""
    @flags = {"matching" => nil, "quote" => nil}
    @current_arg = @method_args[0]
    @arg_pointer = 0
    @parsed_result = @method_args.map{|key|[key, []]}.to_h
  end

  def validate_keyword(letter, pointer, keyword)
    if peek_until_not(@user_input, pointer, "right", target=[" "])[1] == "no_match"
      raise_parser_error(pointer, "EmptyKeywordError")
    end
    if !@clean_lookup.include?(keyword)
      raise_parser_error(pointer, "UnexpectedKeywordError")
    end
    dirty_keyword = @clean_lookup[keyword]
    if @parsed_result.include?(dirty_keyword) && !@parsed_result[dirty_keyword].empty?
      raise_parser_error(pointer, "RepeatedKeywordError")
    else
      if !@parsed_result.include?(dirty_keyword)
        raise_parser_error(pointer, "UnexpectedKeywordError")
      end
    end
  end

  # Close a positional argument, and adds it to parsed_result
  def close_argument()
    if @clean_lookup.include?(@current_arg)
      @current_arg = @clean_lookup[@current_arg]
    end
    @tmp_string = @tmp_string.strip
    @parsed_result[@current_arg] += [@tmp_string]
    @tmp_string = ""

    @flags["matching"], @flags["quote"] = [nil, nil]
  end

  # Checks if, given the pointer, there are any remaining quoteless arguments in the user_input
  def check_remaining_quoteless_args(pointer, user_input=nil)
    user_input = user_input || @user_input
    peek_pointer = pointer

    return false if peek_until_not(user_input, peek_pointer, "right", [" ", ","])[0] == false

    while true
      peek_after_result = peek_after(user_input, peek_pointer, "right", target=[" ", ","], target_after="", stop=["\\", "\"", "'"])
      peek_result = peek(user_input, peek_pointer, "right", target="", stop=["\\", "\"", "'"])

      # Checking if the match is zero length
      return false if peek_after_result[2] == peek_pointer && peek_result[2] == peek_pointer

      if !["stop", "end_of_string"].include?(peek_after_result[1]) || !["stop", "end_of_string"].include?(peek_result[1])
        check_colon = peek_until(user_input, peek_pointer, "right", ":", stop=[" ", ","])
        if ["stop", "end_of_string"].include?(check_colon[1])
          return false if check_colon[2] == peek_pointer
          return true
        end
        if check_colon[1] == "match"
          peek_pointer = check_colon[2]
        end
      else
        return false
      end

    end
  end

  # Checks if, given the pointer, the exact next item in the user input is a quoteless argument
  def check_next_quoteless_arg(pointer)
    peek_result = peek(@user_input, pointer, "right", "", stop=["\\", " ", ","])
    peek_after_result = peek_after(@user_input, pointer, "right", target=[" ", ","], target_after="", stop=["\\", "\"", "'"])
    if !["stop", "end_of_string"].include?(peek_after_result[1]) || !["stop", "end_of_string"].include?(peek_result[1])
      check_colon = peek_until(@user_input, pointer, "right", ":", stop=[" ", ","])
      if ["stop", "end_of_string"].include?(check_colon[1])
        return true
      end
    end
    return false
  end

  # Bumps current_arg to the next argument in the methods arguments list, and does error checking too
  def bump_current_arg(pointer, letter)
    check_remaining_quote_args = lambda do
      return peek_until(@user_input, pointer, "right", ["\"", "'"])[1] == "match"
    end
    check_next_quote_args = lambda do
      return peek_after(@user_input, pointer, "right", [" ", ","], ['"',"'"])[0] || peek(@user_input, pointer, "right", ["\"", "'"])[0]
    end

    if @current_arg[0] != "*"
      # If there are any remaining positional arguments:
      if check_remaining_quoteless_args(pointer) || check_remaining_quote_args.call()
        if @arg_pointer == @method_args.size - 1
          raise_parser_error(pointer, "TooMuchArgumentsError")
        end
        # If the exact next item in the input is a positional argument
        if check_next_quoteless_arg(pointer) || check_next_quote_args.call()
          @arg_pointer += 1
          @current_arg = @method_args[@arg_pointer]
        end
        return
      end
      if @arg_pointer != @method_args.size - 1
        raise_parser_error(pointer, "NotEnoughArgumentsError")
      end
    end

    # End the method if current arg is the last one, and there's nothing left to parse
    return if @arg_pointer == @method_args.size - 1
    return if peek_until_not(@user_input, pointer, "right", " ")[0] == true

    # If the current arg is a splat, and the next method argument is not optional, throw an error
    next_method_argument = @method_args[@method_args.index(@current_arg) + 1]
    if (@current_arg[0] == "*") && !next_method_argument.include?("=")
      raise_parser_error(pointer, "MissingKeywordArgumentError")
    end
  end

  def check_quoted_strings(pointer, letter)
    # Ignore it if the quote is escaped
    return if peek(@user_input, pointer, "left", "\\")[0] == true

    if @flags["matching"] == "argument"
      close_argument()
      bump_current_arg(pointer, letter)
      return
    end
    if @flags["matching"] != "argument"
      @tmp_string = ""
      @flags["matching"],@flags["quote"] = ["argument", letter]

      # If there are no remaining quotes, throw an error
      if peek_until(@user_input, pointer, "right", ["'", "\""])[1] != "match" and
      peek(@user_input, pointer, "right", ["'", '"'])[1] != "match"
        raise_parser_error(pointer, "StringNotClosedError")
      end
    end
  end

  def check_quoteless_strings(pointer, letter)
    if @flags["quote"] == false
      raise_parser_error(pointer, "InvalidCharacterError") if letter == "\\"

      @tmp_string += letter if pointer == @user_input.length - 1
      next_character_is_quote = peek(@user_input, pointer, "right", ["\"", "'"])

      # Checking either if the current character is a space, quote, comma, or it it's the
      # last character in the user_input
      if [" ", ","].include?(letter) || (pointer == @user_input.size - 1) || next_character_is_quote[0]
        # Manually removing all commas, ok, it's hacky I know
        @tmp_string = @tmp_string.gsub(",", "")
        close_argument()
        bump_current_arg(pointer, letter)
      end
    end
  end

  # Assigns current letter to tmp_string, and checks if the keyword argument is closed
  def match_keywords(pointer, letter)
    return if @flags["matching"] != "keyword"

    if letter != ":"
      raise_parser_error(pointer, "InvalidKeywordError") if ["\\"].include?(letter)
      @tmp_string += letter
    end
    if letter == ":"
      keyword = @tmp_string.strip
      validate_keyword(letter, pointer, keyword)

      # If there's quoted arguments or quoteless arguments to the left of the argument, bump the argument pointer
      if peek_until(@user_input, pointer, "left", target=["\"", "'"])[1] == "match" || check_remaining_quoteless_args(0, @user_input[0...pointer] + ":")
        @arg_pointer += 1
      end

      @current_arg = @dirty_lookup[@current_arg] if @dirty_lookup.include?(@current_arg)

      @flags["matching"] = nil
      @current_arg = keyword
      @tmp_string = ""
    end
  end

  def parse_arguments(methods_args, input)
    validate_developer_arguments(methods_args)
    init_variables(methods_args, input)

    for letter, pointer in @user_input.split("").each_with_index
      if ['"', "'"].include?(letter)
        check_quoted_strings(pointer, letter)
        next # Don't run the code below, and go to the next iteration
      end

      if @flags["matching"] == "argument"
        check_quoteless_strings(pointer, letter)
        @tmp_string += letter
        next
      end

      # Checking for a stray colon
      if letter == ":" and @flags["matching"] == nil
        raise_parser_error(pointer, "InvalidKeywordError")
      end

      if @flags["matching"] == nil && ![" ", ","].include?(letter)
        raise_parser_error(pointer, "InvalidCharacterError") if letter == "\\"

        @tmp_string = ""
        # Checking for a keyword argument
        if peek_until(@user_input, pointer, "right", target=[":"], stop=[" ", ","])[0] == false
          @flags["matching"],@flags["quote"] = ["argument", false]
          @tmp_string += letter
        # Checking for a quote less positional argument
        else
          @flags["matching"] = "keyword"
          @tmp_string += letter
        end

      else
        match_keywords(pointer, letter)
      end
    end

    return clean_args(@parsed_result)
  end
end
