class JekyllAwesomeParser
  def validate_dev_args_type(arg_list, arg, type_list)
    colon_pos = peek_until(arg, 0, "right", ":")[2]
    arg_type = peek_after(arg, colon_pos, "right", " ", "")

    if peek_until_not(arg, colon_pos, "right", " ")[1] == "no_match"
      raise_parser_type_error("empty_type", {"arg_list" => arg_list, "arg_name" => arg})
    end

    if peek_until(arg, colon_pos, "right", "=")[1] == "match"
      raise_parser_type_error("optional_arg_after_type", {"arg_list" => arg_list, "arg_name" => arg})
    end

    # If there's a space in the type name:
    if peek_until(arg, arg_type[2], "right", " ")[1] == "match"
      raise_parser_type_error("type_name_with_space", {"arg_list" => arg_list, "arg_name" => arg})
    end

    type_name = arg[(arg_type[2])..].strip
    type_name = type_name[1..] if type_name[0] == ":"
    if !type_list.include?(type_name)
      number_note = ["int", "float", "integer"].include? type_name
      raise_parser_type_error("invalid_type", {"arg_list" => arg_list, "arg_name" => arg,
                                              "type_name" => type_name, "number_note" => number_note,
                                              "type_list" => type_list})
    end
  end

  # Parse through an optional argument string
  def parse_optional_argument(arg_list, full_arg, arg_name)
    brackets_count = {"[" => 0, "]" => 0}
    parsed_string = ""
    matching = [false, nil]

    for letter, i in arg_name.split("").each_with_index
      # Unless the escape character is itself escaped, ignore
      if letter == "\\"
        if peek(arg_name, i, "left", "\\")[1] == "match"
          parsed_string += letter
        end
      end

      if ["[", "]"].include?(letter) and matching[0] == false
        if i != 0
          raise_parser_type_error("multiple_arguments", {"arg_list" => arg_list, "arg_name" => full_arg})
        end
        if letter == "]"
          raise_parser_type_error("unclosed_list", {"arg_list" => arg_list, "arg_name" => full_arg})
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
          # @print_errors = @print_errors || false

          tmp_parser.instance_variable_set(:@matching_list, true)
          parsed_list = tmp_parser.parse_arguments(["*list_arguments"], parsed_string, convert_types=@convert_types, print_errors=@print_errors)

          if peek_until(arg_name, i-1, "right", ["[", "]"])[0] == true
            raise_parser_type_error("unclosed_list", {"arg_list" => arg_list, "arg_name" => full_arg})
          end
          if i != arg_name.size - 1
            raise_parser_type_error("multiple_arguments", {"arg_list" => arg_list, "arg_name" => full_arg})
          end

          return parsed_list["list_arguments"]
        else
          parsed_string += letter
        end
        next
      end

      if ["\"", "\'"].include? letter and matching[0] != "list"
        # If the quote is escaped, ignore it
        if peek(arg_name, i, "left", "\\")[1] == "match"
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
        for letter in arg_name.split("").each
          if ["[", "]"].include? letter
            raise_parser_type_error("multiple_arguments", {"arg_list" => arg_list, "arg_name" => full_arg})
          end
        end
        raise_parser_type_error("optional_arg_with_space", {"arg_list" => arg_list, "arg_name" => full_arg})
      end

      if !["\\", "\"", "\'"].include? letter
        parsed_string += letter
      end
    end

    if matching[0] == true
      raise_parser_type_error("unclosed_string", {"arg_list" => arg_list, "arg_name" => full_arg})
    end

    # Some extra cases to catch
    if ["\"", "\'"].include? arg_name[0] and ["\"", "\'"].include? arg_name[-1]
      if arg_name[0] != arg_name[-1]
        raise_parser_type_error("unclosed_string", {"arg_list" => arg_list, "arg_name" => full_arg})
      end
    else
      if ["\"", "\'"].include? arg_name[0] or ["\"", "\'"].include? arg_name[-1]
        raise_parser_type_error("unclosed_string", {"arg_list" => arg_list, "arg_name" => full_arg})
      end
    end
    raise_parser_type_error("unclosed_list", {"arg_name" => full_arg}) if matching[0] == "list"
    return parsed_string
  end

  def validate_dev_args_optional(arg_list, arg)
    equals_pos = peek_until(arg, 0, "right", "=")[2]
    optional_arg = peek_after(arg, equals_pos, "right", " ", "")

    optional_arg_pos = optional_arg[2]
    # If there's no space after the '=', the position should add one
    if optional_arg[1] == "no_match"
      optional_arg_pos += 1
    end

    if peek_until_not(arg, equals_pos, "right", " ")[1] == "no_match"
      raise_parser_type_error("empty_optional_arg", {"arg_list" => arg_list, "arg_name" => arg})
    end

    # Checking for a space in the optional argument
    colon_pos = arg.size - 1
    colon_match = peek_until(arg, optional_arg_pos, "right", ":")
    if colon_match
      colon_pos = colon_match[2]
    end

    colon_pos -= 1 if arg[colon_pos] == ":"

    arg_name = arg[optional_arg_pos..colon_pos].strip
    parse_optional_argument(arg_list, arg, arg_name)
  end

  # Validates the given method arguments by an developer. Since they are given as a string
  def validate_developer_arguments(arg_list)
    type_list = ["num", "str", "list", "bool", "string", "boolean", "array"]

    if arg_list.class != Array
      raise_parser_type_error("wrong_arg_list_type", {"args" => arg_list, "arg_type" => arg_list.class})
    end

    for arg in arg_list
      # If argument is empty
      raise_parser_type_error("empty_argument", {"arg_list" => arg_list, "arg_name" => arg}) if arg == ""

      # If argument is the wrong type
      raise_parser_type_error("wrong_argument_type", {"arg_list" => arg_list, "arg_name" => arg, "arg_type" => arg.class}) if arg.class != String

      arg = arg.strip
      if %w[0 1 2 3 4 5 6 7 8 9].include? arg[0]
        raise_parser_type_error("arg_starts_with_number", {"arg_list" => arg_list, "arg_name" => arg})
      end

      if arg.include? ":" # If there's a type in the arg
        # Checks if the colon is inside a list, then it's a keyword argument not a type
        brackets_count = {"[" => 0, "]" => 0}
        colon_inside_list = false
        for letter in arg.split("")
          brackets_count[letter] += 1 if ["[", "]"].include? letter
          opening, ending = brackets_count["["], brackets_count["]"]
          raise_parser_type_error("unclosed_list", {"arg_list" => arg_list, "arg_name" => arg}) if ending > opening

          # If the number of brackets are the same, the colon is inside a list
          colon_inside_list = true if letter == ":" && opening != ending
        end
        raise_parser_type_error("unclosed_list", {"arg_list" => arg_list, "arg_name" => arg}) if opening != ending
        # Raise the error after looping, because unclosed lists have a higher error priority
        if colon_inside_list == true
          raise_parser_type_error("keyword_argument_in_list", {"arg_list" => arg_list, "arg_name" => arg})
        end
        validate_dev_args_type(arg_list, arg, type_list)
      end

      if arg.include? "=" # If the argument is optional
        validate_dev_args_optional(arg_list, arg)
      end

      # If there's not a type nor is it optional, just check for spaces
      if arg.strip.include? " " and !(arg.include? ":" or arg.include? "=")
        raise_parser_type_error("arg_name_with_space", {"arg_list" => arg_list, "arg_name" => arg})
      end
    end
  end
end
