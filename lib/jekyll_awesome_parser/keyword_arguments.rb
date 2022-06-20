class JekyllAwesomeParser
  def validate_keyword(letter, pointer, keyword)
    if peek_until_not(@user_input, pointer, "right", target=[" "])[1] == "no_match"
      raise_parser_error(pointer, "EmptyKeywordError", { "extra_info": ["Empty Keyword: '#{keyword}'"] })
    end
    unless @clean_lookup.include?(keyword)
      raise_parser_error(pointer, "UnexpectedKeywordError", { "extra_info": ["Unexpected Keyword: '#{keyword}'"] })
    end
    dirty_keyword = @clean_lookup[keyword]
    if @parsed_result.include?(dirty_keyword) && !@parsed_result[dirty_keyword].empty?
      raise_parser_error(pointer, "RepeatedKeywordError", { "extra_info": ["Repeated Keyword: '#{keyword}'"] })
    else
      unless @parsed_result.include?(dirty_keyword)
        raise_parser_error(pointer, "UnexpectedKeywordError", { "extra_info": ["Unexpected Keyword: '#{keyword}'"] })
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

      @current_parameter = @dirty_lookup[@current_parameter] if @dirty_lookup.include?(@current_parameter)

      @flags["matching"] = nil
      @current_parameter = keyword
      @tmp_string = ""
    end
  end
end
