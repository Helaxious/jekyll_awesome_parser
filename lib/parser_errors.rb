# I would put this method inside the class, but I don't know how to access it :(
def get_debug_info(info, args)
  message = ["#{info[:user_input]}", (" " * info[:pointer]) + "^"].join("\n")

  if args != nil and args["extra_info"]
    args["extra_info"].each { |info| message += "\n" + info}
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
      @message = ("[Invalid Character] You can't put backslashes on their own.\n" +
                  "(In an additional note, if you tried to escape a quote,\n") +
                  "you can only do that inside quotes.)"
      super(info, args)
    end
  end
  class StringNotClosedError < ParserError
    def initialize(info, args)
      @message = "[String Not Closed] Maybe you forgot to close an string or mixed different quotes?"
      super(info, args)
    end
  end
  class InvalidKeywordError < ParserError
    def initialize(info, args)
      @message = "[Invalid Keyword] Maybe you put a stray colon, or you put a backslash in your keyword?"
      super(info, args)
    end
  end
  class EmptyKeywordError < ParserError
    def initialize(info, args)
      @message = "[Empty keyword] Nothing was detected past the keyword."
      super(info, args)
    end
  end
  class TooMuchArgumentsError < ParserError
    def initialize(info, args)
      @message = "[Too Much Arguments] It was given more arguments than specified!"
      super(info, args)
    end
  end
  class NotEnoughArgumentsError < ParserError
    def initialize(info, args)
      @message = "[Not Enough Arguments] It was given less arguments than specified!"
      super(info, args)
    end
  end
  class RepeatedKeywordError < ParserError
    def initialize(info, args)
      @message = "[Repeated Keyword] You're not allowed to do that."
      super(info, args)
    end
  end
  class UnexpectedKeywordError < ParserError
    def initialize(info, args)
      @message = "[Unexpected Keyword] It was given a keyword that was not specified in the method!"
      super(info, args)
    end
  end
  class MissingKeywordArgumentError < ParserError
    def initialize(info, args)
      @message = "[Missing Keyword] It was not given one or more required keyword arguments."
      super(info, args)
    end
  end
  class ListNotClosedError < ParserError
    def initialize(info, args)
      @message = "[List Not Closed] Closing list character ']' was not found!\n"+
                  "(In an additional note, if you intended to use the brackets characters in\n"+
                  "a string, you'll need to put quotes ('') in your string.)"
      super(info, args)
    end
  end
end

def raise_type_error(message, args, developer_error=true)
  if args != nil and args["extra_info"]
    args["extra_info"].each { |info| message += "\n" + info}
  end

  developer_note = "(This is a developer error, this error should be fixed by the\n" +
              "developers and not the user, if you're the user, contact the developers!)"
  message += developer_note if developer_error
  raise TypeError, message
end

module ParserTypeErrors
  def self.check_args_is_nil(args)
    if args == nil
      raise TypeError, "'args' can't be empty, please fill it with the methods arguments\n"
    end
  end

  def self.empty_argument(args)
    check_args_is_nil(args)
    message = "[Empty Argument] argument '#{args['arg_name']}' is empty"
    raise_type_error(message, args, developer_error=true)
  end

  def self.wrong_argument_type(args)
    check_args_is_nil(args)
    message = "[Wrong Arg Type] '#{args['arg_name']}' is #{args['arg_type']} when it should be String"
    raise_type_error(message, args, developer_error=true)
  end

  def self.arg_starts_with_number(args)
    check_args_is_nil(args)
    message = "[Argument Starts With Number] '#{args['arg_name']}' Starts with a number.\n"+
              "(Ruby doesn't allow variables that starts with a number soooo...)"

    raise_type_error(message, args, developer_error=true)
  end

  def self.wrong_arg_list_type(args)
    check_args_is_nil(args)
    message = "[Wrong Arg Type] argument list '#{args['arg_type']}' should be a Hash"
    raise_type_error(message, args, developer_error=true)
  end

  def self.invalid_character(args)
    check_args_is_nil(args)
    letter, invalid_characters = args["letter"], args["invalid_characters"]
    message = "[Invalid Character] The character '#{letter}' is not allowed\n"+
              "(Here's the characters you can't put in your args '#{invalid_characters}')"
    raise_type_error(message, args, developer_error=true)
  end

  def self.arg_name_with_space(args)
    check_args_is_nil(args)
    arg_name = args["arg_name"]
    message = "[Argument Name With Space] #{arg_name} should not have spaces."
    raise_type_error(message, args, developer_error=true)
  end

  def self.type_name_with_space(args)
    check_args_is_nil(args)
    arg_name = args["arg_name"]
    message = "[Type Name With Space] #{arg_name} has a type that should not have spaces."
    raise_type_error(message, args, developer_error=true)
  end

  def self.empty_type(args)
    check_args_is_nil(args)
    arg_name = args["arg_name"]
    message = "[Empty Type] #{arg_name} Has an empty type (nothing was detected past the ':')."
    raise_type_error(message, args, developer_error=true)
  end

  def self.optional_arg_after_type(args)
    check_args_is_nil(args)
    arg_name = args["arg_name"]
    message = "[Optional Arg After Type] #{arg_name} Has an optional arg (also known as 'keyword default').\n"+
              "after the type. (a '=' was detected after a ':')"
    raise_type_error(message, args, developer_error=true)
  end

  def self.wrong_type(args)
    check_args_is_nil(args)
    type_name, number_note, type_list = args["type_name"], args["number_note"], args["type_list"]
    message = "[Wrong Type] #{type_name} Is not a valid type. Maybe you mispelled?\n"
    message += "(It was detected that you wanted to pass the type as an int/float.\n"+
                "For simplicity, there is no differentiation between ints and floats.\n"+
                "To pass a number type, use 'num' (eg: 'arg: num'). It will accept ints and floats.\n"+
                "And it will return either a int or a float.)" if number_note == true
    message += "(All valid types: #{type_list})"
    raise_type_error(message, args, developer_error=true)
  end

  def self.empty_optional_arg(args)
    check_args_is_nil(args)
    arg_name = args["arg_name"]
    message = "[Empty Optional Argument] #{arg_name} Has an empty optional argument (nothing was\n"+
              "detected past the '=')"
    raise_type_error(message, args, developer_error=true)
  end

  def self.pos_arg_with_space(args)
    check_args_is_nil(args)
    arg_name = args["arg_name"]
    message = "[Positional Argument With Space] #{arg_name} has a positional argument that should not have spaces."
    raise_type_error(message, args, developer_error=true)
  end
end
