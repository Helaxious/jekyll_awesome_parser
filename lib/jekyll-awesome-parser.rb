require_relative "parser_errors.rb"

class JekyllAwesomeParser

  def peek(string, pointer, direction, target, stop=nil)
    if stop.class == String
      stop = Array(stop)
    end
    if target.class == String
      target = Array(target)
    end
    direction = ({"left" => -1, "right" => 1})[direction]
    if (0 <= pointer + direction) and (pointer + direction <= string.size - 1)
      if target.include?(string[pointer + direction])
        return [true, "match", pointer + direction]
      else
        if stop != nil && (stop.include?(string[pointer + direction]))
          return [false, "stop", pointer + direction]
        else
          return [false, "no_match", pointer + direction]
        end
      end
    end
    return [false, "end_of_string", string.size - 1]
  end

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

  def peek_until_not(string, pointer, direction, target)
    pointer_direction = ({"left" => -1, "right" => 1})[direction]
    peek_pointer = pointer
    while true
      peek_pointer += pointer_direction
      result = peek(string, peek_pointer, direction, target, nil)
      if result[1] == "no_match"
        return [true, "match", peek_pointer + pointer_direction]
      else
        if result[1] == "end_of_string"
          return [false, "no_match", peek_pointer + pointer_direction]
        end
      end
    end
  end

  def peek_after(string, pointer, direction, target, target_after, stop=nil)
    if stop === nil
      stop = []
    end
    if stop.class == String
      stop = Array(stop)
    end
    if target_after.class == String
      target_after = Array(target_after)
    end

    if peek(string, pointer, "right", target)[0] == true
      second_peek = peek_until_not(string, pointer, direction, target)
      if second_peek[0] == "no_match"
        return second_peek
      else
        is_stop = stop.include?(string[second_peek[2]])
        if is_stop
          return [false, "stop", second_peek[2]]
        end
        return [target_after.include?(string[second_peek[2]]), "match", second_peek[2]]
      end
    else
      return [false, "no_match", pointer]
    end
  end

  def clean_args(arguments)
    clean_arguments = {}
    for (key, value) in Array(arguments.clone())
      if key.include?("*")
        key = key[1..-1]
      else
        if key.include?("=")
          key = key[0...key.index("=")]
        end
      end
      clean_arguments[key] = value
    end
    return clean_arguments
  end

  def order_result(arguments, result)
    return arguments.map{|key|[key, result[key]]}.to_h
  end

  def raise_parser_error(pointer, error, *args, extra_info)
    # You can't have an optional argument after a splat?????? why??????
    raise TypeError, "'extra_info' needs to be a Array" unless [Array, NilClass].include? extra_info.class

    error = ParserErrors.const_get(error)
    raise error.new({"user_input":@user_input, "pointer":pointer}, *args, extra_info=extra_info)
  end

  def validate_developer_arguments(args)
    error_note = "(This is a developer error, this error should be fixed by the\n" +
                "developers and not the user, if you're the user, contact the developers!)"
    if args.class != Array
      raise TypeError, "Wrong type lol" + "\n" + error_note
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
      raise_parser_error(pointer, "EmptyKeywordError", extra_info=nil)
    end
    if !@clean_lookup.include?(keyword)
      raise_parser_error(pointer, "UnexpectedKeywordError", extra_info=nil)
    end
    dirty_keyword = @clean_lookup[keyword]
    if @parsed_result.include?(dirty_keyword) && @parsed_result[dirty_keyword]
      raise_parser_error(pointer, "RepeatedKeywordError", extra_info=nil)
    else
      if !@parsed_result.include?(dirty_keyword)
        raise_parser_error(pointer, "UnexpectedKeywordError", extra_info=nil)
      end
    end
  end

  def close_argument()
    @flags["matching"], @flags["quote"] = [nil, nil]
    if @clean_lookup.include?(@current_arg)
      @current_arg = @clean_lookup[@current_arg]
    end
    @tmp_string = @tmp_string.strip
    @parsed_result[@current_arg] = @parsed_result[@current_arg] + [@tmp_string]
    @tmp_string = ""
  end

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

  def bump_current_arg(pointer, letter)
    check_remaining_quote_args = lambda do
      return peek_until(@user_input, pointer, "right", ["\"", "'"])[1] == "match"
    end
    check_next_quote_args = lambda do
      return peek_after(@user_input, pointer, "right", [" ", ","], ['"',"'"])[0] || peek(@user_input, pointer, "right", ["\"", "'"])[0]
    end

    if @current_arg[0] != "*"
      if check_remaining_quoteless_args(pointer) || check_remaining_quote_args.call()
        if @arg_pointer == @method_args.size - 1
          raise_parser_error(pointer, "TooMuchArgumentsError", extra_info=nil)
        end
        if check_next_quoteless_arg(pointer) || check_next_quote_args.call()
          @arg_pointer += 1
          @current_arg = @method_args[@arg_pointer]
        end
        return
      end
      if @arg_pointer != @method_args.size - 1
        raise_parser_error(pointer, "NotEnoughArgumentsError", extra_info=nil)
      end
    end
    if @arg_pointer == @method_args.size - 1
      return
    end
    if peek_until_not(@user_input, pointer, "right", " ")[0] == true
      return
    end
    next_method_argument = @method_args[@method_args.index(@current_arg) + 1]
    if (@current_arg[0] == "*") && !next_method_argument.include?("=")
      raise_parser_error(pointer, "MissingKeywordArgumentError", extra_info=nil)
    end
  end

  def check_quoted_strings(pointer, letter)
    return if peek(@user_input, pointer, "left", "\\")[0] == true

    if @flags["matching"] == "argument"
      close_argument()
      bump_current_arg(pointer, letter)
      return
    end
    if @flags["matching"] != "argument"
      @tmp_string = ""
      @flags["matching"],@flags["quote"] = ["argument", letter]
      if peek_until(@user_input, pointer, "right", ["'", "\""])[1] != "match"
        raise_parser_error(pointer, "StringNotClosedError", extra_info=nil)
      end
    end
  end

  def check_quoteless_strings(pointer, letter)
    if @flags["quote"] == false
      raise_parser_error(pointer, "InvalidCharacterError", extra_info=nil) if letter == "\\"

      next_character_is_quote = peek(@user_input, pointer, "right", ["\"", "'"])
      if pointer == @user_input.length - 1
        @tmp_string += letter
      end
      if [" ", ","].include?(letter) || (pointer == @user_input.size - 1) || next_character_is_quote[0]
        # Manually removing all commas, ok, it's hacky I know
        @tmp_string = @tmp_string.gsub(",", "")
        close_argument()
        bump_current_arg(pointer, letter)
      end
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
      if letter == ":"
        if @flags["matching"] == nil
          raise_parser_error(pointer, "InvalidKeywordError", extra_info=nil)
        end
      end

      if @flags["matching"] == nil && ![" ", ","].include?(letter)
        raise_parser_error(pointer, "InvalidCharacterError", extra_info=nil) if letter == "\\"

        @tmp_string = ""
        if peek_until(@user_input, pointer, "right", target=[":"], stop=[" ", ","])[0] == false
          @flags["matching"],@flags["quote"] = ["argument", false]
          @tmp_string += letter
        else
          @flags["matching"] = "keyword"
          @tmp_string += letter
        end

      else
        if @flags["matching"] == "keyword" && letter != ":"
          raise_parser_error(pointer, "InvalidKeywordError", extra_info=nil) if ["\\"].include?(letter)
          @tmp_string += letter
        else
          if @flags["matching"] == "keyword" && letter == ":"
            keyword = @tmp_string.strip
            validate_keyword(letter, pointer, keyword)
            if peek_until(@user_input, pointer, "left", target=["\"", "'"])[1] == "match" || check_remaining_quoteless_args(0, @user_input[0...pointer] + ":")
              @arg_pointer += 1
            end

            if @dirty_lookup.include?(@current_arg)
              @current_arg = @dirty_lookup[@current_arg]
            end

            @flags["matching"] = nil
            @current_arg = keyword
            @tmp_string = ""
          end
        end
      end
    end
    return clean_args(@parsed_result)
  end
end
