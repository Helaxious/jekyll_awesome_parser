class JekyllAwesomeParser
  # Convert the tmp string to its type as specified in the current_arg (eg: 'arg1: bool')
  def convert_type(string, convert_nil=false)
    check_int = /^[0-9]+$/
    check_float = /^[0-9]+(\.[0-9]+)$/

    return Integer(string) if string =~ check_int
    return Float(string) if string =~ check_float

    return false if string == "false"
    return true if string == "true"
    # Small workaround, since in the optional_arg_lookup the argument can't be nil
    return :nil if string == "nil" and convert_nil == true
    return string
  end

  # Converts an optional argument, either converts the type, or parses a quoted string for errors
  def convert_optional_argument(full_arg, argument)
    # If the optional argument is enclosed between quotes:
    is_string = ["\"", "\'"].include?(argument[0]) and ["\"", "\'"].include?(argument[-1])
    is_list = argument[0] == "[" and argument[-1] == "]"
    if is_string or is_list
      return parse_optional_argument(full_arg, argument)
    else
      return convert_type(argument, convert_nil=true)
    end
  end

  # Check if user arg matches the developer specified type and throws an error in case it doesn't
  def check_user_type()
    full_arg = @clean_lookup[@current_arg] || @current_arg
    arg_name = @dirty_lookup[@current_arg]
    type_name = @type_lookup[full_arg] || @type_lookup[@current_arg]

    user_type = convert_type(@tmp_string).class
    # In case user_type is a quoted string
    user_type = String if ["\"", "\'"].include? @flags["quote"]

    # This function should behave a bit differently if its matching a list
    user_type = Array if @matching_list == true
    type_name = @actual_type_name if @actual_type_name != nil

    # Don't bother if the type is not specified
    return if type_name == nil

    correct_type = {"str" => String, "num" => "a number", "list" => Array, "bool" => "a boolean"}[type_name]

    raise_error = lambda do |extra_info=nil|
      error_args = {"arg_name" => arg_name, "user_input" => @tmp_string, "correct_type" => correct_type,
                    "wrong_type" => user_type, "full_arg" => full_arg, "additional_info" => extra_info}
      raise_parser_type_error("wrong_type", error_args)
    end

    raise_error.call if type_name == "num" and !([Integer, Float].include? user_type)
    raise_error.call if type_name == "str" and !(user_type == String)

    if type_name == "list" and !(user_type == Array)
      raise_error.call "'#{arg_name}' Probably needs to be [#{arg_name}]"
    end

    if type_name == "bool" and !([TrueClass, FalseClass].include? user_type)
      raise_error.call "(In an additional note, if you just wanted to pass a string named '#{arg_name}',\n+"
                        "put it in quotes (#{arg_name} -> \"#{arg_name}\"))"
    end
  end
end
