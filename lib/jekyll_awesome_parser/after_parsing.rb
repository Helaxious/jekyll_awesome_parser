class JekyllAwesomeParser
  def check_optional_args
    # Loops through parsed_result and fills any empty parameters if they're optional
    for k, v in @parsed_result
      if v.empty? and @optional_arg_lookup[k] != nil
        @parsed_result[k] = [@optional_arg_lookup[k]]

        if @optional_arg_lookup[k] == :nil
          @parsed_result[k] = [nil]
        end
      end
    end
  end

  # Order parsed_result by insertion based on the arguments parameter
  def order_result(arguments, result)
    return arguments.map{ |key|[key, result[key]] }.to_h
  end

  # If there`s no user input, check if every parameter is optional, else, throw an error
  def check_empty_input(pointer, parameters, input)
    return if input != "" or @matching_list != nil
    for method in parameters
      is_optional = false
      for letter in method.split("")
        is_optional = true if letter == "="
      end
      raise_parser_error(pointer, "NotEnoughArgumentsError") if is_optional == false
    end
  end
end
