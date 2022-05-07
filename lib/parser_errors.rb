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
      @message = ("Whoops, it seems like you put an invalid character!\n" +
                  "In an additional note, if you tried to escape a quote,\n") +
                  "you can only do that inside quotes"
      super(info, extra_info)
    end
  end
  class StringNotClosedError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like you forgot to close a argument!"
      super(info, extra_info)
    end
  end
  class InvalidKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like your keyword is invalid!"
      super(info, extra_info)
    end
  end
  class EmptyKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like your keyword is empty!"
      super(info, extra_info)
    end
  end
  class TooMuchArgumentsError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like there's more given arguments than it's needed!"
      super(info, extra_info)
    end
  end
  class NotEnoughArgumentsError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like there's not enough given arguments!"
      super(info, extra_info)
    end
  end
  class RepeatedKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like two or more repeated keywords!"
      super(info, extra_info)
    end
  end
  class UnexpectedKeywordError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like there was an unexpected keyword!"
      super(info, extra_info)
    end
  end
  class MissingKeywordArgumentError < ParserError
    def initialize(info, *args, extra_info)
      @message = "Whoops, it seems like there's one or more missing keyword arguments"
      super(info, extra_info)
    end
  end
end
