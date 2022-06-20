class JekyllAwesomeParser
  def validate_parameters_type(parameters, parameter, type_list)
    colon_pos = peek_until(parameter, 0, "right", ":")[2]
    parameter_type = peek_after(parameter, colon_pos, "right", " ", "")

    if peek_until_not(parameter, colon_pos, "right", " ")[1] == "no_match"
      raise_parser_type_error("empty_type", { "parameters" => parameters, "parameter_name" => parameter })
    end

    if peek_until(parameter, colon_pos, "right", "=")[1] == "match"
      raise_parser_type_error("optional_arg_after_type", { "parameters" => parameters, "parameter_name" => parameter })
    end

    # If there's a space in the type name:
    if peek_until(parameter, parameter_type[2], "right", " ")[1] == "match"
      raise_parser_type_error("type_name_with_space", { "parameters" => parameters, "parameter_name" => parameter })
    end

    type_name = parameter[(parameter_type[2])..].strip
    type_name = type_name[1..] if type_name[0] == ":"
    unless type_list.include?(type_name)
      number_note = ["int", "float", "integer"].include? type_name
      raise_parser_type_error("invalid_type", { "parameters" => parameters, "parameter_name" => parameter,
                                              "type_name" => type_name, "number_note" => number_note,
                                              "type_list" => type_list })
    end
  end

  # Parse through an optional argument string
  def parse_optional_argument(parameters, full_parameter, parameter_name)
    brackets_count = { "[" => 0, "]" => 0 }
    parsed_string = ""
    matching = [false, nil]

    for letter, i in parameter_name.split("").each_with_index
      # Unless the escape character is itself escaped, ignore
      if letter == "\\"
        if peek(parameter_name, i, "left", "\\")[1] == "match"
          parsed_string += letter
        end
      end

      if ["[", "]"].include?(letter) and matching[0] == false
        if i != 0
          raise_parser_type_error("multiple_arguments", { "parameters" => parameters, "parameter_name" => full_parameter })
        end
        if letter == "]"
          raise_parser_type_error("unclosed_list", { "parameters" => parameters, "parameter_name" => full_parameter })
        else
          matching[0] = "list"
          brackets_count["["] = 1
          next
        end
      end

      if matching[0] == "list"
        if ["[", "]"].include?(letter)
          brackets_count[letter] += 1
        end
        if brackets_count["["] == brackets_count["]"]
          tmp_parser = JekyllAwesomeParser.new
          # Not sure why this is commented, but I'll leave it like that
          # @print_errors = @print_errors || false

          tmp_parser.instance_variable_set(:@matching_list, true)
          parsed_list = tmp_parser.parse_input(["*list_arguments"], parsed_string, convert_types=@convert_types, print_errors=@print_errors)

          if peek_until(parameter_name, i-1, "right", ["[", "]"])[0] == true
            raise_parser_type_error("unclosed_list", { "parameters" => parameters, "parameter_name" => full_parameter })
          end
          if i != parameter_name.size - 1
            raise_parser_type_error("multiple_arguments", { "parameters" => parameters, "parameter_name" => full_parameter })
          end

          return parsed_list["list_arguments"]
        else
          parsed_string += letter
        end
        next
      end

      if ["\"", "\'"].include? letter and matching[0] != "list"
        # If the quote is escaped, ignore it
        if peek(parameter_name, i, "left", "\\")[1] == "match"
          parsed_string += letter
        else
          matching[1] = letter if matching[1] == nil
          if letter == matching[1]
            matching[0] = !matching[0]
          else
            parsed_string += letter
          end
          next
        end
      end

      if letter == " " and matching[0] == false
        for letter in parameter_name.split("").each
          if ["[", "]"].include? letter
            raise_parser_type_error("multiple_arguments", { "parameters" => parameters, "parameter_name" => full_parameter })
          end
        end
        raise_parser_type_error("optional_arg_with_space", { "parameters" => parameters, "parameter_name" => full_parameter })
      end

      unless ["\\", "\"", "\'"].include? letter
        parsed_string += letter
      end
    end

    if matching[0] == true
      raise_parser_type_error("unclosed_string", { "parameters" => parameters, "parameter_name" => full_parameter })
    end

    # Some extra cases to catch
    if ["\"", "\'"].include? parameter_name[0] and ["\"", "\'"].include? parameter_name[-1]
      if parameter_name[0] != parameter_name[-1]
        raise_parser_type_error("unclosed_string", { "parameters" => parameters, "parameter_name" => full_parameter })
      end
    else
      if ["\"", "\'"].include? parameter_name[0] or ["\"", "\'"].include? parameter_name[-1]
        raise_parser_type_error("unclosed_string", { "parameters" => parameters, "parameter_name" => full_parameter })
      end
    end
    raise_parser_type_error("unclosed_list", { "parameters" => parameters, "parameter_name" => full_parameter }) if matching[0] == "list"
    return parsed_string
  end

  def validate_optional_parameters(parameters, parameter)
    equals_pos = peek_until(parameter, 0, "right", "=")[2]
    optional_arg = peek_after(parameter, equals_pos, "right", " ", "")

    optional_arg_pos = optional_arg[2]
    # If there's no space after the '=', the position should add one
    if optional_arg[1] == "no_match"
      optional_arg_pos += 1
    end

    if peek_until_not(parameter, equals_pos, "right", " ")[1] == "no_match"
      raise_parser_type_error("empty_optional_arg", { "parameters" => parameters, "parameter_name" => parameter })
    end

    # Checking for a space in the optional argument
    colon_pos = parameter.size - 1
    colon_match = peek_until(parameter, optional_arg_pos, "right", ":")
    if colon_match
      colon_pos = colon_match[2]
    end

    colon_pos -= 1 if parameter[colon_pos] == ":"

    parameter_name = parameter[optional_arg_pos..colon_pos].strip
    parse_optional_argument(parameters, parameter, parameter_name)
  end

  # Validates the given parameters by an developer. Since they are given as a string
  def validate_parameters(parameters)
    type_list = ["num", "str", "list", "bool", "string", "boolean", "array"]

    if parameters.class != Array
      raise_parser_type_error("wrong_parameters_type", { "parameters" => parameters, "parameter_type" => parameters.class })
    end

    for parameter in parameters
      # If the parameter is empty
      raise_parser_type_error("empty_parameter", { "parameters" => parameters, "parameter_name" => parameter }) if parameter == ""

      # If the parameter is the wrong type
      raise_parser_type_error("wrong_parameter_type", { "parameters" => parameters, "parameter_name" => parameter,
                                                    "parameter_type" => parameter.class }) if parameter.class != String

      parameter = parameter.strip
      if %w[0 1 2 3 4 5 6 7 8 9].include? parameter[0]
        raise_parser_type_error("parameter_starts_with_number", { "parameters" => parameters, "parameter_name" => parameter })
      end

      if parameter.include? ":" # If there's a type in the parameter
        # Checks that if the colon is inside a list, then it's a keyword argument not a type
        brackets_count = { "[" => 0, "]" => 0 }
        colon_inside_list = false

        for letter in parameter.split("")
          brackets_count[letter] += 1 if ["[", "]"].include? letter
          opening, ending = brackets_count["["], brackets_count["]"]
          raise_parser_type_error("unclosed_list", { "parameters" => parameters, "parameter_name" => parameter }) if ending > opening

          # If the number of brackets aren't the same, the colon is inside a list
          colon_inside_list = true if letter == ":" && opening != ending
        end
        raise_parser_type_error("unclosed_list", { "parameters" => parameters, "parameter_name" => parameter }) if opening != ending
        # Raise the error after looping, because unclosed lists have a higher error priority
        if colon_inside_list == true
          raise_parser_type_error("keyword_argument_in_list", { "parameters" => parameters, "parameter_name" => parameter })
        end
        validate_parameters_type(parameters, parameter, type_list)
      end

      if parameter.include? "=" # If the parameterument is optional
        validate_optional_parameters(parameters, parameter)
      end

      # If there's not a type nor is it optional, just check for spaces in the parameter name
      if parameter.strip.include? " " and !(parameter.include? ":" or parameter.include? "=")
        raise_parser_type_error("parameter_name_with_space", { "parameters" => parameters, "parameter_name" => parameter })
      end
    end
  end
end
