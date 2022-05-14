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
end
