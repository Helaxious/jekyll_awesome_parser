# I would put this method inside the class, but I don't know how to access it :(
def get_debug_info(info, extra_info)
  message = ["#{info[:user_input]}", (" " * info[:pointer]) + "^"].join("\n")
  extra_info.each { |info| message += "\n" + info} if extra_info

  return message
end

module ParserErrors
  class ParserError < StandardError
    def initialize(info, extra_info)
      debug_info = get_debug_info(info, extra_info)
      super((@message + "\n\n") + debug_info)
    end
  end

  class InvalidCharacterError < ParserError
    def initialize(info, *args, extra_info)
      @message = ("Invalid character, please don't use backslashes on their own.\n" +
                  "(In an additional note, if you tried to escape a quote,\n") +
                  "you can only do that inside quotes.)"
      super(info, extra_info)
    end
  end
  class StringNotClosedError < ParserError
    def initialize(info, *args, extra_info)
      @message = "String not closed, maybe you forgot to close an string or mixed different quotes?"
      super(info, extra_info)
    end
  end
  class InvalidKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Invalid Keyword, maybe you put a stray colon, or you put a backslash in your keyword?"
      super(info, extra_info)
    end
  end
  class EmptyKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Empty keyword, nothing was detected past the keyword."
      super(info, extra_info)
    end
  end
  class TooMuchArgumentsError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Too much arguments, it was given more arguments than specified!"
      super(info, extra_info)
    end
  end
  class NotEnoughArgumentsError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Not enough arguments, it was given less arguments than specified!"
      super(info, extra_info)
    end
  end
  class RepeatedKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Repeated Keyword, you're not allowed to do that."
      super(info, extra_info)
    end
  end
  class UnexpectedKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Unexpected Keyword! It was given a keyword that was not specified in the method!"
      super(info, extra_info)
    end
  end
  class MissingKeywordArgumentError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Missing keyword, It was not given one or more required keyword arguments."
      super(info, extra_info)
    end
  end
  class ListNotClosedError < ParserError
    def initialize(info, *args, extra_info)
      @message = "List not closed! Closing list character ']' was not found!\n"+
                  "(In an additional note, if you intended to use the brackets characters in\n"+
                  "a string, you'll need to put quotes ('') in your string.)"
      super(info, extra_info)
    end
  end
end
