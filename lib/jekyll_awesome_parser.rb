# frozen_string_literal: true

require_relative "jekyll_awesome_parser/after_parsing"
require_relative "jekyll_awesome_parser/check_lists"
require_relative "jekyll_awesome_parser/init_variables"
require_relative "jekyll_awesome_parser/keyword_arguments"
require_relative "jekyll_awesome_parser/parser_errors"
require_relative "jekyll_awesome_parser/peek_functions"
require_relative "jekyll_awesome_parser/positional_args"
require_relative "jekyll_awesome_parser/type_functions"
require_relative "jekyll_awesome_parser/validate_parameters"

class JekyllAwesomeParser
  def initialize
    @matching_list = nil
    @actual_type_name = nil
    @debug_context = nil # Jekyll specific debugging context
    @deactivate_print_errors = nil
    @convert_types = false
    @print_errors = false
  end

  def deactivate_print_errors
    @deactivate_print_errors = true
  end

  # Jekyll only method, it gets an object that contains some useful debugging context
  def set_context(context)
    @debug_context = context
  end

  # Gets the parameter name from the parameters (eg: "arg1=nil" becomes "arg1")
  # This method is not only used after parsing, it is also used in init_variables
  def clean_parameters(parameters)
    clean_parameters = {}
    for (key, value) in Array(parameters.clone())
      key = key[1..-1] if key.include?("*")
      key = key[0...key.index("=")] if key.include?("=")
      key = key[0...key.index(":")] if key.include?(":")
      key = key.strip
      clean_parameters[key] = value
    end
    return clean_parameters
  end

  # Grabs a specified error from the ParserErrors class, then returns the error
  def raise_parser_error(pointer, error, args=nil)

    error = ParserErrors.const_get(error)
    raise error.new({ "user_input": @user_input, "pointer": pointer, "parameters": @parameters,
                      "clean_parameters": @clean_lookup.keys,
                      "parsed_result": clean_parameters(order_result(@parameters, @parsed_result)),
                      "matching_list": @matching_list }, args)
  end

  def raise_parser_type_error(error, args=nil)
    ParserTypeErrors.send(error, args.merge("matching_list" => @matching_list))
  end

  def parse_input(parameters, input, convert_types=true, print_errors=true)
    validate_parameters(parameters)
    init_variables(parameters, input, convert_types, print_errors)

    check_empty_input(0, parameters, input)

    for letter, pointer in @user_input.split("").each_with_index
      if ['"', "'"].include?(letter) && (@flags["matching"] != "list")
        check_quoted_strings(pointer, letter)
        next # Don't run the code below, and jump to the next iteration
      end

      next if check_lists(pointer, letter) == "next"

      if @flags["matching"] == "argument"
        check_quoteless_strings(pointer, letter)
        if ["[", "]"].include? letter
          @flags["matching"] = "list"
          @brackets_count["["] = 1
          next
        end

        # Ignore if the escape character is not being escaped
        next if peek(input, pointer, "left", "\\")[1] != "match" && letter == "\\"

        @tmp_string += letter
        next
      end

      # Checking for a stray colon
      raise_parser_error(pointer, "InvalidKeywordError") if (letter == ":") && @flags["matching"].nil?

      if @flags["matching"].nil? && ![" ", ","].include?(letter)
        raise_parser_error(pointer, "InvalidCharacterError") if letter == "\\"

        @tmp_string = ""
        # Checking for a quoteless positional argument
        if peek_until(@user_input, pointer, "right", target=[":"], stop=[" ", ","])[0] == false
          @flags["matching"], @flags["quote"] = ["argument", false]
          @tmp_string += letter

          # If the argument is one character length and it's the end of the user input
          if pointer == input.size - 1
            close_argument(pointer)
            bump_current_parameter(pointer, letter)
          end

        # Checking for a keyword argument
        else
          # Keyword arguments don't make sense in lists, raise an error if there is one
          raise_parser_error(pointer, "KeywordArgumentInListError") if @matching_list == true

          @flags["matching"] = "keyword"
          @tmp_string += letter
        end

      else
        match_keywords(pointer, letter)
      end
    end

    raise_parser_error(pointer, "StringNotClosedError") if @flags["matching"] == "argument"
    raise_parser_error(pointer, "ListNotClosedError") if @flags["matching"] == "list"
    check_optional_args()
    return clean_parameters(order_result(parameters, @parsed_result))
  end
end
