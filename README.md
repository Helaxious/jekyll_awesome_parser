# Jekyll Awesome Parser

![](robot_banner.png)

An Awesome gem for Jekyll Plugin makers to completely parse your arguments!

## What is jekyll_awesome_parser?

jekyll_awesome_parser is a complete argument parser for Jekyll plugins, packed with every feature you may (or may not) need.

Let's say you have these parameters:

```ruby
parameters = ["*cat_breed", "size=100", "eye_color: list", "cute=true: bool"]
```

and the user passes this as the input:

```ruby
`cat_breed: "egyptian" 200 eye_color: ["red", blue 'yellow']`
```

jekyll_awesome_parser will parse the input, and return a completely parsed Hash:

```ruby
{"cat_breed" => ["egyptian"], "size" => [200],
"eye_color" => [["red", "blue", "yellow"]],
"cute" => [true]}
```

To use it, simply import the parser, initialize it, and use the `parse_input` method.

```ruby
# Import the gem
require "jekyll_awesome_parser"
# Or import the external files
# require_relative "jekyll_awesome_parser/lib/jekyll_awesome_parser.rb"

def initialize(tag_name, input, tokens)
  parser = JekyllAwesomeParser.new

  parameters = ["*cat_breed", "size=100", "eye_color: list", "cute=true: bool"]
  parsed_input = parser.parse_input(parameters, input)
end
```

## Why?

As to my knowledge, there is no good way to parse the user input with the Liquid tags or filters, [it seems](https://stackoverflow.com/questions/29480950/custom-liquid-tag-with-two-parameters) [possible](https://stackoverflow.com/questions/40734882/pass-multiple-argument-to-custom-plugin-in-jekyll) to do so, but it is very limited, and kinda clunky, so I created a parser, with a loose syntax with a lot of features, to do this for me.

## Setting the Parameters

To specify the parameters, simply pass a list like this:

```ruby
parameters = ["arg1", "*arg2", "arg3=12: num"]
```

Here's what you can do with them:

- ### Star args (splats)
  Define an parameter as a splat by putting a star (asterisk) before the variable name:

  ```ruby
  parameters = ["*var1"]
  ```

  One small difference from the normal splats, is that this requires being given *at least one* argument.

  #### Example:
  ```ruby
  parameters = ["no_splat", "*splat"]
  input = "chocolate fruit banana"
  # {"no_splat" => ["chocolate"], "splat" => ["fruit", "banana"]}
  ```

  Note that with this, you're able to make keyword-only arguments:

  ```ruby
  parameters = ["*splat", "no_splat"]
  input = "chocolate fruit banana"
  # Raises Missing Keyword Error
  ```

- ### Keyword Defaults (optional arguments)
  Keyword defaults are parameters that the user doesn't need to provide, and if that's the case, it will default to some specified value:

  ```ruby
  parameters = ["arg1=tomato", "arg2=Cheese", "arg3=wont_default"]
  input = "arg3: pineapple"
  # {"arg1" => ["tomato"], "arg2" => ["Cheese"], "arg3" => ["pineapple"]}
  ```

  The syntax is simple, put a `=` after the parameter name, and put the default argument, the default argument can be either a `bool`, `num`, `str` or a `list` (check the Syntax section for more):

  ```ruby
  parameters = ["coolness=true"]
  parameters = ["age=35"]
  parameters = ["chef_name=\"Peter Parker\""]
  parameters = ["pizza_ingredients=[tomato cheese pineapple]"]
  ```

- ### Types

  You're able to specify the input type by putting a colon after the parameter, and putting the name of the type:

  ```ruby
  parameters = ["chef_name: str", "age: num", "delivery: bool", "recipe: list"]
  ```

  Here are the list of the valid names you can pass as type:

  - String: `string`, `str`
  - Number: `number`, `num`
  - Boolean: `boolean`, `bool`
  - List: `list`, `array`

  This will require the user to pass the appropriate type, and will throw an error in case the argument passed was the wrong type.

  `parse_input` by default converts the user types automatically, but you can disable it by passing the keyword argument `convert_types=false`.

  But note that even if you turn automatic type conversion off, the argument will still be converted if the parameter has an specified type.

  Also, if you want both a type and a keyword default in your parameter, you need to do it like this, put `=` and a default argument right after the parameter name, then a `:` and the type name:

  ```ruby
  parameters = ["chef_name='Mark': str", "age=20: num", "delivery=false: bool"]
  ```

## Syntax

`jekyll_awesome_parser` has a a very simple and loose syntax:

Positional arguments are arguments that are assigned by their position, passing an argument without an keyword makes it positional:

```ruby
parameters = ["arg1", "arg2", "arg3"]
input = `value3 value2 value1`
# {"arg1" => ["value3"], "arg2" => ["value2"], "arg1" => ["arg1"]}
```

Keyword arguments are arguments that are assigned by their keyword:

```ruby
parameters = ["arg1", "arg2", "arg3"]
input = `arg2: two arg1: one arg3: three`
# {"arg1" => ["one"], "arg2" => ["two"], "arg3" => ["three"]}
```

Commas and quotes around strings are optional, this means that this is valid too:

```ruby
parameters = ["arg1", "arg2", "arg3"]
input = `"one fish", 'two fish', red_fish`
# {"arg1" => ["one fish"], "arg2" => ["two fish"], "arg1" => ["red_fish"]}
```

Currently, there are four types you can pass, strings, booleans, numbers and lists.

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

Although I do my best to make this parser as easy and intuitive as possible both for the user, and for plugin developers, there are some tricky cases you may want to be aware of:

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

Or download the parser and import it locally with `require_relative`, all the parser logic is inside the `lib` folder:

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

All you gotta do is instantiate `JekyllAwesomeParser`, and use its `parse_input` function.

You can optionally check if you want to automatically convert types with `convert_types` keyword argument (which is `true` by default), or you want to print the error messages before throwing then with `print_errors` (which is also `true` by default).

Then all you need to do is provide your parameters, and the user input you want to parse:

```ruby
require "jekyll_awesome_parser"
parser = JekyllAwesomeParser.new

# Parameters must be a list
parameters = ["plugin_name:str", "awesome=true: bool"]
# Input needs to be a string
input = "plugin_name: jekyll_awesome_parser, awesome: true"

# Parser will return a hash:
parsed_result = parser.parse_input(parameters, input)

plugin_name = parsed_result["plugin_name"]
is_plugin_awesome = parsed_result["awesome"]
```

Additionally, in case you're making a Liquid Tag, you may want to give the context variable to the parser with the method `set_context`, with that, the parser can say on what file was it parsing on when it throws an error.

Although doing that requires doing something like this:

```ruby
# Inside a plugin file
require "jekyll_awesome_parser"

module Jekyll
  class AbbaLyrics < Liquid::tag
    def initialize(tag_name, input, tokens)
      # Since we can only call the parser on the render method,
      # we need to make the input an instance variable:
      @input = input
      @parameters = ["abba_song"]
    end

    def render(context)
      parser = JekyllAwesomeParser.new
      # Setting the parser context with the context variable
      parser.set_context(context)
      # Parsing the arguments as usual
      parsed_input = parser.parse_input(@parameters, @input)

      return "Mamma Mia, here I go again."
    end
  end
end
Liquid::Template.register_tag('abba_lyrics', Jekyll::AbbaLyrics)
```

Obviously, this is totally optional, this is just to get an slightly more useful error message.

## Using the parser outside Jekyll

Although this plugin is called jekyll_awesome_parser, it is not dependent on Jekyll at all, all the plugin's functionality is available outside Jekyll, the only Jekyll-specific thing is the optional `set_context` function, but that's really it.

You're able to use the parser for other things. It's only targeted at Jekyll because of the non-existent parsing capabilities of Liquid.

## Contributing

0. Open an Issue. (optional)
1. Fork the repo.
2. Make your cool changes.
3. Run the tests with `rake`, install the gem if you don't have it (and make new ones if needed)
4. Open a PR, and done!

## License

This plugin is licensed under the MIT license. Pretty cool huh?
