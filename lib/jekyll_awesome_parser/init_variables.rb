# frozen_string_literal: true

class JekyllAwesomeParser
  def init_optional_arg_and_type_lookup(parameters)
    @optional_arg_lookup = {}
    @type_lookup = {}
    # Parsing the parameters to create keyword defaults and type lookups
    for parameter in parameters
      @type_lookup[parameter] = parameter.split(":")[1].strip if parameter.include? ":"

      next unless parameter.include? "="

      if parameter.include? ":"
        @optional_arg_lookup[parameter] = convert_optional_argument(parameters,
                                                                    parameter, parameter.split("=")[1].split(":")[0].strip)
      else
        @optional_arg_lookup[parameter] = convert_optional_argument(parameters,
                                                                    parameter, parameter.split("=")[1].strip)
      end
    end
  end

  def init_variables(parameters, user_input, convert_types, print_errors)
    @user_input = user_input
    @parameters = parameters
    @convert_types = convert_types

    if @deactivate_print_errors
      @print_errors = false
    else
      @print_errors = print_errors
    end

    ParserErrors.set_vars(@debug_context, @print_errors)

    _clean_parameters = clean_parameters(@parameters.map { |key| [key, []] }.to_h).keys()
    @clean_lookup = _clean_parameters.zip(@parameters).map { |clean, dirty| [clean, dirty] }.to_h
    @dirty_lookup = _clean_parameters.zip(@parameters).map { |clean, dirty| [dirty, clean] }.to_h

    @tmp_string = ""
    @flags = { "matching" => nil, "quote" => nil }
    @current_parameter = @parameters[0]
    @arg_pointer = 0
    @parsed_result = @parameters.map { |key| [key, []] }.to_h
    @brackets_count = { "[" => 0, "]" => 0 }

    init_optional_arg_and_type_lookup(parameters)
  end
end
