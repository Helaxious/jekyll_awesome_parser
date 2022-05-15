class JekyllAwesomeParser
  def check_optional_args
    # Checks every key in parsed_result for every empty entry and fills it with an optional arg if it exists
    for k, v in @parsed_result
      if v.empty? and @optional_arg_lookup[k] != nil
        @parsed_result[k] = [@optional_arg_lookup[k]]

        if @optional_arg_lookup[k] == :nil
          @parsed_result[k] = [nil]
        end
      end
    end
  end

  # Ruby's dicts are ordered by insertion, so order it based on the methods arguments list
  def order_result(arguments, result)
    return arguments.map{|key|[key, result[key]]}.to_h
  end

  # If the user passed nothing, check if every argument is optional, else throw an error
  def check_empty_input(pointer, method_args, input)
    return if input != "" or @matching_list != nil
    for method in method_args
      is_optional = false
      for letter in method.split("")
        is_optional = true if letter == "="
      end
      raise_parser_error(pointer, "NotEnoughArgumentsError") if is_optional == false
    end
  end
end
