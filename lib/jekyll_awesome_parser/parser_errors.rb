def get_debug_info(info, args)
  message = ["User Input: #{info[:user_input]}", (" " * (info[:pointer] + 12)) + "^",
            "Argument Names: #{info[:clean_args]}"].join("\n")

  if args != nil and args[:extra_info]
    args[:extra_info].each { |info| message += "\n" + info}
  end

  message += ["\n\n[Info]",
  "Method Arguments: #{info[:method_args]}","Parsed Result: #{info[:parsed_result]}"].join("\n")

  # FIXME
  if info[:matching_list] != nil
    message += "\n\n(Important note: The parser was parsing inside a list when it threw this error,\n"+
                "that means that the debug information probably is not complete, this is a known issue\n"+
                "and it will be fixed later, sorry for the inconvenience.)"
  end
  return message
end

module ParserErrors
  class ParserError < StandardError
    def initialize(info, args)
      debug_info = get_debug_info(info, args)
      super((@message + "\n\n") + debug_info)
    end
  end

  class InvalidCharacterError < ParserError
    def initialize(info, args)
      @message = "[Invalid Character] It was detected a backslash '\\' in the input."+
                  "Maybe you accidentally typed that? (Backslashes aren't allowed in the input)\n"

      super(info, args)
    end
  end
  class StringNotClosedError < ParserError
    def initialize(info, args)
      @message = "[String Not Closed] It was detected an unclosed string. Maybe you forgot to close an string or mixed different quotes?"
      super(info, args)
    end
  end
  class InvalidKeywordError < ParserError
    def initialize(info, args)
      @message = "[Invalid Keyword] It was detected an invalid keyword. Maybe you put a stray colon, or you put a backslash in your keyword?"
      super(info, args)
    end
  end
  class EmptyKeywordError < ParserError
    def initialize(info, args)
      @message = "[Empty keyword] No positional argument was detected past this keyword.\n"+
                  "Maybe you forgot to enter an argument, or maybe you accidentally put a colon ':'?"
      super(info, args)
    end
  end
  class TooMuchArgumentsError < ParserError
    def initialize(info, args)
      @message = "[Too Much Arguments] It was given more arguments than specified in the method arguments!"
      super(info, args)
    end
  end
  class NotEnoughArgumentsError < ParserError
    def initialize(info, args)
      @message = "[Not Enough Arguments] It was given less arguments than specified in the method arguments!"
      super(info, args)
    end
  end
  class RepeatedKeywordError < ParserError
    def initialize(info, args)
      @message = "[Repeated Keyword] It was detected that a keyword was given two or more times."
      super(info, args)
    end
  end
  class UnexpectedKeywordError < ParserError
    def initialize(info, args)
      @message = "[Unexpected Keyword] It was given a keyword that was not specified in the method arguments!\n"+
                  "Maybe you accidentally put a colon in a string?"
      super(info, args)
    end
  end
  class MissingKeywordArgumentError < ParserError
    def initialize(info, args)
      @message = "[Missing Keyword] One or more required keyword arguments were not given."
      super(info, args)
    end
  end
  class ListNotClosedError < ParserError
    def initialize(info, args)
      @message = "[List Not Closed] It was detected an unclosed list! Maybe you forgot to close the list with ']'?\n"+
                  "(In an additional note, if you intended to use the brackets characters in\n"+
                  "a string, you'll need to put quotes ('' or \"\") in your string.)"
      super(info, args)
    end
  end
end

def raise_type_error(message, args, developer_error=true)
  if args != nil and args["extra_info"]
    args["extra_info"].each { |info| message += "\n" + info}
  end

  developer_note = "\n\n(This is a developer error, this error should be fixed by the\n" +
              "developers and not the user, if you're the user, contact the developers!)"
  message += developer_note if developer_error

  # FIXME
  if args["matching_list"] != nil
    message += "\n\n(Important note: The parser was parsing inside a list when it threw this error,\n"+
                "that means that the debug information probably is not complete, this is a known issue\n"+
                "and it will be fixed later, sorry for the inconvenience.)"
  end
  raise TypeError, message
end

module ParserTypeErrors
  def self.check_args_is_nil(args)
    if args == nil
      raise TypeError, "'args' can't be empty, please fill it with the correct methods arguments\n."
    end
  end

  def self.empty_argument(args)
    check_args_is_nil(args)
    message = "[Empty Argument] One or more provided method arguments in #{args['arg_list']} are empty strings."
    raise_type_error(message, args, developer_error=true)
  end

  def self.wrong_argument_type(args)
    check_args_is_nil(args)
    message = "[Wrong Arg Type] Provided method argument '#{args['arg_name']}' in #{args['arg_list']} is #{args['arg_type']} when it should be String."
    raise_type_error(message, args, developer_error=true)
  end

  def self.arg_starts_with_number(args)
    check_args_is_nil(args)
    message = "[Argument Starts With Number] Provided method argument '#{args['arg_name']}' in #{args["arg_list"]} starts with a number.\n"+
              "(Ruby doesn't allow variables that starts with a number :p)"

    raise_type_error(message, args, developer_error=true)
  end

  def self.wrong_arg_list_type(args)
    check_args_is_nil(args)
    message = "[Wrong Arg Type] Provided method argument list '#{args['args']}' is a #{args['arg_type']} when it should be an Array"
    raise_type_error(message, args, developer_error=true)
  end
  
  def self.arg_name_with_space(args)
    check_args_is_nil(args)
    message = "[Argument Name With Space] Provided method argument '#{args["arg_name"]}' in #{args["arg_list"]} has an argument name that should not have spaces."
    raise_type_error(message, args, developer_error=true)
  end

  def self.type_name_with_space(args)
    check_args_is_nil(args)
    message = "[Type Name With Space] Provided method argument '#{args["arg_name"]}' in #{args["arg_list"]} has a type that should not have spaces."
    raise_type_error(message, args, developer_error=true)
  end

  def self.empty_type(args)
    check_args_is_nil(args)
    message = "[Empty Type] Provided method argument '#{args["arg_name"]}' in #{args["arg_list"]} has an empty type (nothing was detected past the ':')."
    raise_type_error(message, args, developer_error=true)
  end

  def self.optional_arg_after_type(args)
    check_args_is_nil(args)
    message = "[Optional Argument After Type] Provided method argument '#{args["arg_name"]}' in #{args["arg_list"]} has an optional arg (also known as 'keyword default')\n"+
              "after a type. (a '=' was detected after a ':')"
    raise_type_error(message, args, developer_error=true)
  end

  def self.invalid_type(args)
    check_args_is_nil(args)
    message = "[Invalid Type] Provided method argument '#{args["arg_name"]}' in #{args["arg_list"]} has type '#{args["type_name"]}', which is not a valid type. Maybe you mispelled it?\n\n"

    message += "(It was detected that you wanted to pass the type as an int/float.\n"+
                "For simplicity, there is no differentiation between ints and floats.\n"+
                "To pass a number type, use 'num' (eg: 'arg: num'). It will accept ints and floats.\n"+
                "And it will return either a int or a float.)\n\n" if args["number_note"] == true
    message += "(All valid types: #{args["type_list"]})"
    raise_type_error(message, args, developer_error=true)
  end

  def self.empty_optional_arg(args)
    check_args_is_nil(args)
    message = "[Empty Optional Argument] Provided method argument '#{args["arg_name"]}' in #{args["arg_list"]} has an empty optional argument\n"+
              "(nothing was detected past the '=')"
    raise_type_error(message, args, developer_error=true)
  end

  def self.optional_arg_with_space(args)
    check_args_is_nil(args)
    arg_name = args["arg_name"]
    message = "[Optional Argument With Space] Provided method argument '#{args["arg_name"]}' in #{args["arg_list"]} has an optional argument with spaces.\n"+
              "Maybe you tried to pass multiple arguments?"
    raise_type_error(message, args, developer_error=true)
  end

  def self.unclosed_string(args)
    check_args_is_nil(args)
    message = "[Unclosed String] Provided method argument '#{args['arg_name']}' in #{args['arg_list']} has an unclosed quote.\n"+
              "Check if you accidentally have not mixed single and double quotes,\n"+
              "or maybe you forgot to escape a quote, or maybe you just forgot to put a quote?"
    raise_type_error(message, args, developer_error=true)
  end

  def self.unclosed_list(args)
    check_args_is_nil(args)
    message = "[Unclosed List] Provided method argument '#{args['arg_name']}' in #{args['arg_list']} has an unclosed list.\n"+
              "Check if you accidentally have not mixed the brackets."
    raise_type_error(message, args, developer_error=true)
  end

  def self.multiple_arguments(args)
    check_args_is_nil(args)
    message = "[Multiple Arguments] Provided method argument '#{args['arg_name']}' in #{args['arg_list']} has multiple arguments, when it should only have one.\n"+
              "In an additional note, you may have wanted to wrap the arguments in a list."
    raise_type_error(message, args, developer_error=true)
  end

  def self.wrong_type(args)
    check_args_is_nil(args)
    arg_name, user_input, correct_type = args["arg_name"], args["user_input"], args["correct_type"]
    wrong_type, pointer, clean_args = args["wrong_type"], args["pointer"], args["clean_args"]
    method_args, parsed_result, user_arg = args["method_args"], args["parsed_result"], args["user_arg"]

    message = "[Wrong Type] Argument '#{arg_name}' (which was provided as '#{user_arg}') should be #{correct_type}, not #{wrong_type}\n"+
              "User Input: #{user_input}\n"+
              "#{(" " * (pointer + 12)) + "^\n"}"+
              "Argument Names: #{clean_args}"

    if args != nil and args["additional_info"]
      message += "\n" + args["additional_info"]
    end

    message += ["\n\n[Info]",
    "Method Arguments: #{method_args}","Parsed Result: #{parsed_result}"].join("\n")

    # FIXME
    if args["matching_list"] != nil
      message += "\n\n(Important note: The parser was parsing inside a list when it threw this error,\n"+
                  "that means that the debug information probably is not complete, this is a known issue\n"+
                  "and it will be fixed later, sorry for the inconvenience.)"
    end

    raise TypeError, message
  end
end
