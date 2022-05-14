class JekyllAwesomeParser
  # Recursively calls parse_argument in the list match to parse inside of it
  def parse_list(pointer, letter)
    # Yeah, creating additional copies of the parser isn't the best idea, I know
    tmp_parser = JekyllAwesomeParser.new

    # Because the parser doesn't know it's parsing a list, and doesn't know the
    # specified type, we need to tell it manually
    full_arg = @clean_lookup[@current_arg] || @current_arg
    type_name = @type_lookup[full_arg] || @type_lookup[@current_arg]

    tmp_parser.instance_variable_set(:@matching_list, true)
    tmp_parser.instance_variable_set(:@actual_type_name, type_name)

    parsed_list = tmp_parser.parse_arguments(["*list_arguments"], @tmp_string, @convert_types)

    @current_arg = @clean_lookup[@current_arg] if @clean_lookup.include?(@current_arg)
    @parsed_result[@current_arg] += [parsed_list["list_arguments"]]
    bump_current_arg(pointer, letter)

    @brackets_count = {"[" => 0, "]" => 0}
    @flags["matching"] = nil
    @tmp_string = ""
  end

  def check_lists(pointer, letter)
    # To identify the end of a list, even with nested list, we just need to count the number
    # of opening and closing brackets, when they finally are equal, the list has closed
    if ["[", "]"].include?(letter) and @flags["matching"] == nil
      raise_parser_error(pointer, "ListNotClosedError") if letter == "]"

      @flags["matching"] = "list"
      @brackets_count["["] = 1
      return "next"
    end

    if @flags["matching"] == "list"
      @brackets_count[letter] += 1 if ["[", "]"].include?(letter)
      # If the list was closed
      if @brackets_count["["] == @brackets_count["]"]
        parse_list(pointer, letter)
      else
        @tmp_string += letter
      end
      return "next"
    end
  end
end
