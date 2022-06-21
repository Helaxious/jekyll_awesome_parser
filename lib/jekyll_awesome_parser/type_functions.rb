# frozen_string_literal: true

class JekyllAwesomeParser
  # Convert the tmp_string to its type as specified in the current parameter (eg: 'arg1: bool')
  def convert_type(string, convert_nil=false)
    check_int = /^[0-9]+$/
    check_float = /^[0-9]+(\.[0-9]+)$/

    return Integer(string) if string =~ check_int
    return Float(string) if string =~ check_float

    return false if string == "false"
    return true if string == "true"
    # Small workaround, since in the optional_arg_lookup the argument can't be nil
    return :nil if (string == "nil") && (convert_nil == true)

    return string
  end

  # Converts an optional argument, either converts the type, or parses its quoted string for errors
  def convert_optional_argument(parameters, full_parameter, argument)
    # If the optional argument is enclosed between quotes:
    is_string = ["\"", "\'"].include?(argument[0]) and ["\"", "\'"].include?(argument[-1])
    is_list = argument[0] == "[" and argument[-1] == "]"
    if is_string || is_list
      return parse_optional_argument(parameters, full_parameter, argument)
    else
      return convert_type(argument, convert_nil=true)
    end
  end

  # Check if user arg matches the developer specified type and throws an error in case it doesn't
  def check_user_type(pointer)
    full_parameter = @clean_lookup[@current_parameter] || @current_parameter
    parameter_name = @dirty_lookup[@current_parameter]
    type_name = @type_lookup[full_parameter] || @type_lookup[@current_parameter]

    user_type = convert_type(@tmp_string).class
    # In case user_type is a quoted string
    user_type = String if ["\"", "\'"].include? @flags["quote"]

    # This function should behave a bit differently if its matching a list
    user_type = Array if @matching_list == true
    type_name = @actual_type_name if @actual_type_name != nil

    # Don't bother if the type is not specified
    return if type_name.nil?

    correct_type = { "str" => String, "num" => "a number", "list" => Array, "bool" => "a boolean" }[type_name]

    raise_error = lambda do |extra_info=nil|
      error_args = { "parameter_name" => parameter_name, "user_input" => @user_input, "correct_type" => correct_type,
                     "wrong_type" => user_type, "full_parameter" => full_parameter, "additional_info" => extra_info,
                     "pointer" => pointer, "clean_parameters" => @clean_lookup.keys, "parameters" => @parameters,
                     "parsed_result" => clean_parameters(order_result(@parameters, @parsed_result)),
                     "user_arg" => @tmp_string, "matching_list" => @matching_list }

      raise_parser_type_error("wrong_type", error_args)
    end

    raise_error.call if (type_name == "num") && !([Integer, Float].include? user_type)
    raise_error.call if (type_name == "list") && user_type != Array

    if (type_name == "str") && user_type != String
      if [TrueClass, FalseClass].include? user_type
        raise_error.call "(If you wanted to pass '#{@tmp_string}' as a string, you'll have to put it\n"\
                        "between quotes (\"\" or ''))"
      else
        raise_error.call
      end
    end

    if ["bool", "boolean"].include?(type_name) && !([TrueClass, FalseClass].include? user_type)
      # If the user passed "true" or "false" as a string, show an note:
      if (user_type == String) && ((@tmp_string == "true") || (@tmp_string == "false"))
        quoted_arg = { "\"" => "\"#{@tmp_string}\"", "\'" => "\'#{@tmp_string}\'" }[@flags["quote"]]
        raise_error.call "(Side note, maybe you want to get rid of the quotes of the input?\n"\
                          "#{quoted_arg} would be #{@tmp_string})"
      else
        raise_error.call
      end
    end
  end
end
