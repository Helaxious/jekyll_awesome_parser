# Jekyll Awesome Parser

## What is jekyll-awesome-parser?

jekyll-awesome-parser is a complete argument parser for Jekyll, packed with every feature you may (or may not) need.

Let's say you have these method arguments:

```ruby
method_arguments = ["*cat_breed", "size=100", "eye_color: list", "cute=true: bool"]
```

and the user passes this:

```ruby
`cat_breed: "egyptian" 200 eye_color: ["red", blue 'yellow']`
```

jekyll-awesome-parser will return a completely parsed Hash:

```ruby
{"cat_breed" => ["egyptian"], "size" => [200],
"eye_color" => [["red", "blue", "yellow"]],
"cute" => [true]}
```

To use it, simply import the parser, initialize it, and use the `parse_arguments` method.

```ruby
# Import the gem
require "jekyll_awesome_parser"
# Or import the external files
# require_relative "jekyll_awesome_parser/lib/jekyll_awesome_parser.rb"

def initialize(tag_name, input, tokens)
  parser = JekyllAwesomeParser.new

  arguments = ["*cat_breed", "size=100", "eye_color: list", "cute=true: bool"]
  parsed_input = parser.parse_arguments(arguments, input)
end
```

## Method arguments

To specify the method arguments, simply make a list like this:

```ruby
method_arguments = ["arg1", "*arg2", "arg3=12: num"]
```

Here are the type of arguments you can specify:

- ### Star args (splats)
  Define an argument as a splat by putting a star (asterisk) before the variable name:

  ```ruby
  method_arguments = ["*var1"]
  ```

  Like regular splats, this argument will accept more than one argument, but requires being given at least one.

  #### Example:
  ```ruby
  method_arguments = ["no_splat", "*splat"]
  input = "chocolate fruit banana"
  # {"no_splat" => ["chocolate"], "splat" => ["fruit", "banana"]}
  ```

  Note that you're able to make keyword-only arguments:

  ```ruby
  method_arguments = ["*splat", "no_splat"]
  input = "chocolate fruit banana"
  # Raises Missing Keyword Error
  ```

- ### Keyword Defaults (optional arguments)
  Optional arguments are what it says on the tin, it's arguments that the user doesn't need to provide, and will default to some specified value:

  ```ruby
  method_arguments = ["arg1=tomato", "arg2=Cheese", "arg3=wont_default"]
  input = "arg3: pineapple"
  # {"arg1" => ["tomato"], "arg2" => ["Cheese"], "arg3" => ["pineapple"]}
  ```

  To specify it, put a `=` after the argument name, and put the default argument, the default argument can be of any type:

  ```ruby
  method_arguments = ["coolness=true"]
  method_arguments = ["age=35"]
  method_arguments = ["chef_name=\"Peter Parker\""]
  method_arguments = ["pizza_ingredients=[tomato cheese pineapple]"]
  ```

- ### Types

  You're able to specify the input type by putting a colon and putting the name of the type:

  ```
  method_arguments = ["chef_name: str", "age: num", "delivery: bool", "recipe: list"]
  ```

  Here are the list of the valid names you can pass as type:

  - String: `string`, `str`
  - Number: `number`, `num`
  - Boolean: `boolean`, `bool`
  - List: `list`, `array`

  That way, you require the user to pass the specified type.

  `parse_arguments` by default converts the user types automatically, but you can disable it by passing the keyword argument `convert_types=false`.

  Note that even if you turn automatic type conversion off, the argument will still be converted if you specify the type.

  Also, if you want both type and keyword default in your argument, you have to put the default argument before the type:

  ```ruby
  method_arguments = ["chef_name='Mark': str", "age=20: num", "delivery=false: bool"]
  ```

## Syntax

`jekyll-awesome-parser` has a a very simple and flexible syntax:

Positional arguments are arguments that are assigned by their position, passing an argument without an keyword makes it positional:

```ruby
method_arguments = ["arg1", "arg2", "arg3"]
input = `value3 value2 value1`
# {"arg1" => ["value3"], "arg2" => ["value2"], "arg1" => ["arg1"]}
```

Keyword arguments are arguments that are assigned by their keyword:

```ruby
method_arguments = ["arg1", "arg2", "arg3"]
input = `arg2: two arg1: one arg3: three`
# {"arg1" => ["one"], "arg2" => ["two"], "arg3" => ["three"]}
```

Notice that for these two examples, There's no comma separating these arguments, neither are quotes surrounding the strings, that's because both are optional, this means that this is valid too:

```ruby
method_arguments = ["arg1", "arg2", "arg3"]
input = `"one fish", 'two fish', red_fish`
# {"arg1" => ["one fish"], "arg2" => ["two fish"], "arg1" => ["red_fish"]}
```

Currently, there are four types you can have in the parser, strings, booleans, numbers and lists.

```ruby
# Like mentioned before, strings can have double quotes, single quotes, or have no quotes at all
strings = `"double_quotes" 'single_quotes' no_quotes`
# Numbers can be both int or floats
numbers = `123 321 12.1111 3.141592`
# Booleans needs to be in lowercase either, 'true' or 'false'
booleans = `true false`
# Pass a list by surrounding it in brackets
# Lists can be nested, and even be empty. But they can't have keyword arguments.
lists = `["abc" 123 true [nested lists!] []]`
```

## Tricky cases

Although I do my best to make this plugin as easy and intuitive as possible, there are still some tricky cases with some weird results you may want to be aware of:

## Known issues

Some known issues that needs to be fixed later that you should be aware of:

## Installing and using it

### Installing

Either install the gem:

```bash
gem install jekyll_awesome_parser
```

and use `require` to import it:

```ruby
require "jekyll_awesome_parser"
parser = JekyllAwesomeParser.new
```

Or download the parser and import it locally with `require_relative`:

```
# File structure
main.rb <-- We're here
jekyll_awesome_parser/
  - lib/
    - jekyll_awesome_parser.rb <-- You need to import this
    - jekyll_awesome_parser/
```

```ruby
# At main.rb
require_relative "jekyll_awesome_parser/lib/jekyll_awesome_parser.rb"
parser = JekyllAwesomeParser.new
```

### Using it

All you gotta do is instantiate `JekyllAwesomeParser`, and use its `parse_arguments` function.

You can optionally check if you want to automatically convert types with `convert_types` keyword argument, or you want to print the error messages before throwing then with `print_errors`

Then all you need to do is provide your method arguments, and the input you want to parse:

```ruby
require "jekyll_awesome_parser"
parser = JekyllAwesomeParser.new

# Method Arguments must be a list
method_arguments = ["plugin_name:str", "awesome=true: bool"]
# Input needs to be a string
input = "plugin_name: jekyll_awesome_parser, awesome: true"

# Parser will return a hash:
parsed_result = parser.parse_arguments(method_arguments, input)

plugin_name = parsed_result["plugin_name"]
is_plugin_awesome = parsed_result["awesome"]
```

Additionally, you may want to pass the plugin's context (only available if you're making a liquid tag) to the parser's method `set_context` with the context variable, so the parser can say what file was it parsing on when it throws an error:

```ruby
# Inside a plugin file
require "jekyll_awesome_parser"

module Jekyll
  class YourPlugin < Liquid::tag
    def initialize(tag_name, input, tokens)
      # Since we need the context variable, we need to
      # make the input variable an instance variable:
      @input = input
      @method_arguments = ["mamma mia", "here i go again"]
    end

    def render(context)
      parser = JekyllAwesomeParser.new
      # Setting the parser context with the context variable
      parser.set_context(context)
      # Parsing the arguments as usual
      thingy = parser.parse_arguments(@method_arguments, @input)
    end
  end
end
```

Obviously, this is totally optional, this is just to get an slightly more useful error message.

## Using the parser outside Jekyll

Although this plugin is called jekyll_awesome_parser, it is not dependent on Jekyll at all, all the plugin's functionality is available outside Jekyll, the only Jekyll-specific thing is the `set_context` function, but that's really it.

You're able to use the parser for other things. (although I can't think of a use case outside for Jekyll)

## Contributing

0. Open an Issue. (optional)
1. Fork the repo.
2. Make your cool changes.
3. Run the tests with `rake` (and make new ones if needed)
4. Open a PR, and done!

## License

This plugin is licensed under the MIT license.
