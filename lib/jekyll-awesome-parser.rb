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

  def validate_developer_arguments(args)
    error_note = "(This is a developer error, this error should be fixed by the\n" +
                "developers and not the user, if you're the user, contact the developers!)"
    if args.class != Array
      raise TypeError, "Wrong type lol" + "\n" + error_note
    end
  end

  def parse_arguments(args, input)
  end
end
