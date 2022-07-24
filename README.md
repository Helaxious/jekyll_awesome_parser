# Jekyll Awesome Parser

![Banner, a robot with laser eyes, parsing a jekyll tag reading 'tag input'](robot_banner.png)

An Awesome gem for Jekyll Plugin makers to completely parse your arguments!

## What is jekyll_awesome_parser?

jekyll_awesome_parser is a complete argument parser for Jekyll plugins, packed with every feature you may (or may not) need.

Let's say you have these parameters:

```ruby
parameters = ["*cat_breed", "image_size=100", "eye_color: list", "cute=true: bool"]
```

and the user passes this as the input:

```ruby
`cat_breed: "egyptian" 200 eye_color: ["red", blue 'yellow']`
```

jekyll_awesome_parser will parse the input, and return a completely parsed Hash:

```ruby
{"cat_breed" => ["egyptian"], "image_size" => [200],
"eye_color" => [["red", "blue", "yellow"]], "cute" => [true]}
```

To use it, simply import the parser, initialize it, and use the `parse_input` method inside your plugin.

```ruby
# Import the gem
require "jekyll_awesome_parser"
# Or import the external files
# require_relative "jekyll_awesome_parser/lib/jekyll_awesome_parser.rb"

def initialize(tag_name, input, tokens)
  # Instantiate the parser
  parser = JekyllAwesomeParser.new
  input = '"egyptian" "siamese" 500 eye_color: ["brown", purple \'green\']'

  parameters = ["*cat_breed", "image_size=100", "eye_color: list", "cute=true: bool"]
  parsed_input = parser.parse_input(parameters, input)

  cat_breeds = parsed_input["cat_breed"] # ["egyptian", "siamese"]
  image_size = parsed_input["image_size"][0] # 500
  is_cat_cute = parsed_input["cute"][0] # true
end
```

## Why?

As to my knowledge, there is no good way to parse the user input with the Liquid tags or filters, [it seems](https://stackoverflow.com/questions/29480950/custom-liquid-tag-with-two-parameters) [possible](https://stackoverflow.com/questions/40734882/pass-multiple-argument-to-custom-plugin-in-jekyll) to do so, but it is very limited, and kinda clunky, so I created a parser, with a loose syntax with a lot of features to do this for me.

## Setting the Parameters

To specify the parameters, simply pass a list like this:

```ruby
parameters = ["shirt_color=blue", "pants_color=brown", "accessories: list"]
```

Here's what you can do with them:

- ### Star args (splats)
  Define an parameter as a splat by putting a star (asterisk) before the variable name:

  ```ruby
  parameters = ["*splat_argument"]
  ```

  One small difference from normal splats, is that it requires being given *at least one* argument.

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
  Keyword defaults are parameters that are optional to the user, when the user doesn't provide an argument, the parameter will default to some specified value:

  ```ruby
  parameters = ["arg1=tomato", "arg2=Cheese", "arg3=wont_default"]
  input = "arg3: pineapple"
  # {"arg1" => ["tomato"], "arg2" => ["Cheese"], "arg3" => ["pineapple"]}
  ```

  The syntax is simple, put a `=` after the parameter name (or before the type), and put the default argument value, this value can be either a `str`, `num`, `bool` or a `list` (check the Syntax section for more):

  ```ruby
  parameters = ["chef_name=\"Peter Parker\""]
  parameters = ["age=35"]
  parameters = ["coolness=true"]
  parameters = ["pizza_ingredients=[tomato cheese pineapple]"]
  ```

- ### Types

  You're able to specify the parameter type by putting a colon after the parameter name (or after the default argument), and putting the name of the type:

  ```ruby
  parameters = ["chef_name: str", "age: num", "delivery: bool", "recipe: list"]
  ```

  Here are the list of the type names you can pass:

  - String: `string`, `str`
  - Number: `number`, `num`
  - Boolean: `boolean`, `bool`
  - List: `list`, `array`

  Specifying the type will require the user to pass an argument with the appropriate type, and will throw an error in case the argument was the wrong type.

  `parse_input` by default converts the user types automatically, but you can disable it by passing the keyword argument `convert_types=false` to the function.

  But note that even if you turn automatic type conversion off, the argument will still be converted individually for parameters that have a type.

  Also, if you want both a type and a keyword default in your parameter, you need to do it like this, put `=` and a default argument right after the parameter name, then a `:` and the type name:

  ```ruby
  parameters = ["chef_name='Mark': str", "age=20: num", "delivery=false: bool"]
  ```

## Syntax

`jekyll_awesome_parser` has a a very simple and loose syntax:

Positional arguments are arguments that are assigned by their position:

```ruby
parameters = ["arg1", "arg2", "arg3"]
input = `value3 value2 value1`
# {"arg1" => ["value3"], "arg2" => ["value2"], "arg1" => ["arg1"]}
```

Keyword arguments are arguments that are assigned by their keyword, simply put the parameter name with a colon (with no spaces in-between) and place your arguments right after:

```ruby
parameters = ["arg1", "arg2", "arg3"]
input = `arg2: two arg1: one arg3: three`
# {"arg1" => ["one"], "arg2" => ["two"], "arg3" => ["three"]}
```

Commas are optional, as well as quotes on strings, this means that this is valid too:

```ruby
parameters = ["arg1", "arg2", "arg3"]
input = `"one fish", 'two fish' red_fish`
# {"arg1" => ["one fish"], "arg2" => ["two fish"], "arg1" => ["red_fish"]}
```

Currently, there are four argument types you can pass, strings, booleans, numbers and lists.

```ruby
# Like mentioned before, strings can have double quotes, single quotes, or have no quotes at all
strings = `"double_quotes" 'single_quotes' no_quotes`

# Numbers can be both int or floats
numbers = `123 321 12.1111 3.141592`

# Booleans needs to be in lowercase and are either 'true' or 'false'
booleans = `true false`

# Pass a list by surrounding it in brackets
# Lists can be nested, and also empty. But you can't place keyword arguments inside them.
lists = `["abc" 123 true [nested lists!] []]`
```

## Examples

If you still are in doubt on how to use this parser, or you prefer learning with pratical examples, you can check the [examples](readme_examples/examples.md) folder for more.

## Known issues

Some known issues that needs to be fixed later that you should be aware of:

- Error messages details are generally incomplete when it happens while parsing a list

- This shouldn't really occur:
    ```ruby
    parser.parse_input(["arg1", "arg2"], "arg2: 123 potato")
    # {"arg1"=>[], "arg2"=>[123, "potato"]}
    ```

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

Or download the parser and import it locally with `require_relative`, all the parser logic is inside the `lib` folder, so you can get rid of the other files (except the license, you have to keep it):

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

plugin_name = parsed_result["plugin_name"][0]
is_plugin_awesome = parsed_result["awesome"][0]
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

## Acknowledgements

I would like to thank [naitoh](https://github.com/naitoh) and other contributors for developing the [py2rb](https://github.com/naitoh/py2rb) tool, which I used to convert my initial python implementation to ruby, and also wanted to thank [nanobowers](https://github.com/nanobowers) for creating a [fork](https://github.com/nanobowers/py2rb) of py2rb that supported more later python versions.

## Contributing

0. Open an Issue. (optional)
1. Fork the repo.
2. Make your cool changes.
3. Run the tests with `rake` (and make new ones if needed)
4. Open a PR, and done!

## License

This plugin is licensed under the MIT license. Pretty cool huh?
