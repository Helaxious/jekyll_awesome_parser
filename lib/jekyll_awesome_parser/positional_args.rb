class JekyllAwesomeParser
  # Close a positional argument, and adds it to parsed_result
  def close_argument(pointer)
    @current_parameter = @clean_lookup[@current_parameter] if @clean_lookup.include?(@current_parameter)
    @tmp_string = @tmp_string.strip

    # If the parser is set to automatically convert types, or the parameter has a type:
    if @convert_types || @type_lookup[@current_parameter]
      argument = convert_type(@tmp_string)
    else
      argument = @tmp_string
    end

    check_user_type(pointer)
    @parsed_result[@current_parameter] += [argument]
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
        peek_pointer = check_colon[2] if check_colon[1] == "match"
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
      return true if ["stop", "end_of_string"].include?(check_colon[1])
    end
    return false
  end

  # Bumps current parameter to the next parameter in the parameters list, and does error checking too
  def bump_current_parameter(pointer, letter)
    check_remaining_quote_args = lambda do
      return peek_until(@user_input, pointer, "right", ["\"", "'"])[1] == "match"
    end
    check_next_quote_args = lambda do
      return peek_after(@user_input, pointer, "right", [" ", ","], ['"', "'"])[0] || peek(@user_input, pointer, "right", ["\"", "'"])[0]
    end

    # Gets every incomplete parameters, and checks if every one is optional
    check_every_optional_args = lambda do
      for k, v in @parsed_result
        if v == []
          return false if @optional_arg_lookup[k].nil?
        end
      end
      return true
    end

    if @current_parameter[0] != "*"
      # If there are any remaining positional arguments:
      if check_remaining_quoteless_args(pointer) || check_remaining_quote_args.call()
        raise_parser_error(pointer, "TooMuchArgumentsError") if @arg_pointer == @parameters.size - 1
        # If the exact next item in the input is a positional argument
        if check_next_quoteless_arg(pointer) || check_next_quote_args.call()
          @arg_pointer += 1
          @current_parameter = @parameters[@arg_pointer]
        end
        return
      end
      if (@arg_pointer != @parameters.size - 1) && !check_every_optional_args.call()
        raise_parser_error(pointer, "NotEnoughArgumentsError")
      end
    end

    # End the method if current arg is the last one, and there's nothing left to parse
    return if @arg_pointer == @parameters.size - 1
    return if peek_until_not(@user_input, pointer, "right", " ")[0] == true

    if @current_parameter[0] == "*"
      # Loop over the rest of the parameters and check if they're optional arguments
      for parameter in @parameters[(@parameters.index(@current_parameter) + 1)..-1]
        if (parameter.class == String) && !parameter.include?("=")
          raise_parser_error(pointer, "MissingKeywordArgumentError")
        end
      end
    end
  end

  def check_quoted_strings(pointer, letter)
    # Ignore it if the quote is escaped
    if peek(@user_input, pointer, "left", "\\")[0] == true
      @tmp_string += letter
      return
    end

    if @flags["matching"] == "argument"
      # If the quote is not the same opening quote (eg: matching ("), but found (')), don't bother
      if letter != @flags["quote"]
        @tmp_string += letter
      else
        close_argument(pointer)
        bump_current_parameter(pointer, letter)
        return
      end
    end
    if @flags["matching"] != "argument"
      @tmp_string = ""
      @flags["matching"], @flags["quote"] = ["argument", letter]

      # If there are no remaining quotes, throw an error
      if (peek_until(@user_input, pointer, "right", ["'", "\""])[1] != "match") &&
      (peek(@user_input, pointer, "right", ["'", '"'])[1] != "match")
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
        close_argument(pointer)
        bump_current_parameter(pointer, letter)
      end
    end
  end
end
