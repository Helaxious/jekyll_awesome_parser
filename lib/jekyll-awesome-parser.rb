require_relative "jekyll-awesome-parser/after_parsing.rb"
require_relative "jekyll-awesome-parser/init_variables.rb"
require_relative "jekyll-awesome-parser/keyword_arguments.rb"
require_relative "jekyll-awesome-parser/parser_errors.rb"
require_relative "jekyll-awesome-parser/peek.rb"
require_relative "jekyll-awesome-parser/positional_args.rb"
require_relative "jekyll-awesome-parser/type.rb"
require_relative "jekyll-awesome-parser/validate_developer_arguments.rb"

class JekyllAwesomeParser

  def initialize
    @matching_list = nil
    @actual_type_name = nil
  end

  # Gets the arg name from the methods arguments list (eg: "arg1=nil" becomes "arg1")
  # This method is not only used after parsing, it is also used in init_variables
  def clean_args(arguments)
    clean_arguments = {}
    for (key, value) in Array(arguments.clone())
      key = key[1..-1] if key.include?("*")
      key = key[0...key.index("=")] if key.include?("=")
      key = key[0...key.index(":")] if key.include?(":")
      clean_arguments[key] = value
    end
    return clean_arguments
  end

  # Grabs a specified error from the ParserErrors module, grabs some debug info, then returns the error
  def raise_parser_error(pointer, error, args=nil)
    error = ParserErrors.const_get(error)
    raise error.new({"user_input":@user_input, "pointer":pointer}, args)
  end

  def raise_parser_type_error(error, args=nil)
    ParserTypeErrors.send(error, args)
  end

  def parse_arguments(methods_args, input, convert_types=true)
    validate_developer_arguments(methods_args)
    init_variables(methods_args, input, convert_types)

    for letter, pointer in @user_input.split("").each_with_index
      if ['"', "'"].include?(letter) and @flags["matching"] != "list"
        check_quoted_strings(pointer, letter)
        next # Don't run the code below, and go to the next iteration
      end

      # To identify the end of a list, even with nested list, we just need to count the number
      # of opening and closing brackets, when they finally are equal, the list has closed
      if ["[", "]"].include?(letter) and @flags["matching"] == nil
        if letter == "]"
          raise_parser_error(pointer, "ListNotClosedError")
        else
          @flags["matching"] = "list"
          @brackets_count["["] = 1
          next
        end
      end

      if @flags["matching"] == "list"
        if ["[", "]"].include?(letter)
          @brackets_count[letter] += 1
        end
        if @brackets_count["["] == @brackets_count["]"]
          # Yeah, creating additional copies of the parser isn't the best idea, I know
          tmp_parser = JekyllAwesomeParser.new

          # Because the parser doesn't know it's parsing a list, and doesn't know the
          # specified type, we need to tell it manually
          full_arg = @clean_lookup[@current_arg] || @current_arg
          type_name = @type_lookup[full_arg] || @type_lookup[@current_arg]

          tmp_parser.instance_variable_set(:@matching_list, true)
          tmp_parser.instance_variable_set(:@actual_type_name, type_name)

          parsed_list = tmp_parser.parse_arguments(["*list_arguments"], @tmp_string)

          @current_arg = @clean_lookup[@current_arg] if @clean_lookup.include?(@current_arg)
          @parsed_result[@current_arg] += [parsed_list["list_arguments"]]
          bump_current_arg(pointer, letter)

          @brackets_count = {"[" => 0, "]" => 0}
          @flags["matching"] = nil
          @tmp_string = ""
        else
          @tmp_string += letter
        end
        next
      end

      if @flags["matching"] == "argument"
        check_quoteless_strings(pointer, letter)
        if ["[", "]"].include? letter
          @flags["matching"] = "list"
          @brackets_count["["] = 1
          next
        end

        if letter == "\\"
          # Ignore if the escape character is not being escaped
          next if peek(input, pointer, "left", "\\")[1] != "match"
        end
        @tmp_string += letter
        next
      end

      # Checking for a stray colon
      if letter == ":" and @flags["matching"] == nil
        raise_parser_error(pointer, "InvalidKeywordError")
      end

      if @flags["matching"] == nil && ![" ", ","].include?(letter)
        raise_parser_error(pointer, "InvalidCharacterError") if letter == "\\"

        @tmp_string = ""
        # Checking for a quote less positional argument
        if peek_until(@user_input, pointer, "right", target=[":"], stop=[" ", ","])[0] == false
          @flags["matching"],@flags["quote"] = ["argument", false]
          @tmp_string += letter

          # If the argument is one character length and it's the end of the user input
          if pointer == input.size - 1
            close_argument()
            bump_current_arg(pointer, letter)
          end

        # Checking for a keyword argument
        else
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
    return clean_args(@parsed_result)
  end
end
