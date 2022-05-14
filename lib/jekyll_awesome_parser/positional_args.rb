class JekyllAwesomeParser
  # Close a positional argument, and adds it to parsed_result
  def close_argument()
    @current_arg = @clean_lookup[@current_arg] if @clean_lookup.include?(@current_arg)
    @tmp_string = @tmp_string.strip

    # If the parser is set to automatically convert types, or the argument is typed:
    if @convert_types or @type_lookup[@current_arg]
      argument = convert_type(@tmp_string)
    else
      argument = @tmp_string
    end

    check_user_type()
    @parsed_result[@current_arg] += [argument]
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

    # Gets every incomplete method argument, and checks if every one is optional
    check_every_optional_args = lambda do
      for k, v in @parsed_result
        if v == []
          return false if @optional_arg_lookup[k] == nil
        end
      end
      return true
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
      if @arg_pointer != @method_args.size - 1 and !check_every_optional_args.call()
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
    if peek(@user_input, pointer, "left", "\\")[0] == true
      @tmp_string += letter
      return
    end

    if @flags["matching"] == "argument"
      # If the quote is not the same opening quote (eg: matching ("), but found (')), dont bother
      if letter != @flags["quote"]
        @tmp_string += letter
      else
        close_argument()
        bump_current_arg(pointer, letter)
        return
      end
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
end
