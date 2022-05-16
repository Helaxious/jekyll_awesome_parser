class JekyllAwesomeParser
  def init_optional_arg_and_type_lookup(method_args)
    @optional_arg_lookup = {}
    @type_lookup = {}
    # Parsing the method arguments to create keyword defaults and type lookups
    for arg in method_args
      @type_lookup[arg] = arg.split(":")[1].strip if arg.include? ":"

      next if !(arg.include? "=")
      if arg.include? ":"
        @optional_arg_lookup[arg] = convert_optional_argument(method_args, arg, arg.split("=")[1].split(":")[0].strip)
      else
        @optional_arg_lookup[arg] = convert_optional_argument(method_args, arg, arg.split("=")[1].strip)
      end
    end
  end

  def init_variables(method_args, user_input, convert_types)
    @user_input = user_input
    @method_args = method_args
    @convert_types = convert_types

    if ![true, false].include? convert_types
      raise TypeError, "convert_types must be a boolean, not #{convert_types.class}"
    end

    _clean_args = clean_args(@method_args.map{|key|[key, []]}.to_h).keys()
    @clean_lookup = _clean_args.zip(@method_args).map{|clean, dirty|[clean, dirty]}.to_h
    @dirty_lookup = _clean_args.zip(@method_args).map{|clean, dirty|[dirty, clean]}.to_h

    @tmp_string = ""
    @flags = {"matching" => nil, "quote" => nil}
    @current_arg = @method_args[0]
    @arg_pointer = 0
    @parsed_result = @method_args.map{|key|[key, []]}.to_h
    @brackets_count = {"[" => 0, "]" => 0}

    init_optional_arg_and_type_lookup(method_args)
  end
end
