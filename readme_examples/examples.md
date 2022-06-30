# Examples

Some more examples of the parser in action:

```ruby
# Parameters = ["*splat", "after_splat", "optional=whatever"]

input = "splat: potato tomato after_splat: flour"
# {"splat" => ["potato", "tomato"], "after_splat" => ["flour"], "optional" => ["whatever"]}

input = "after_splat: 'flour', splat: \"potato\", 'tomato'"
# Returns the same thing
```

```ruby
# Parameters = ["cooking_book: str", "year: num"]

input = "year: 1984 cooking_book: \"Make your life al dente\""
# {"cooking_book" => ["Make your life al dente"], "year" => [1984]}

input = "'20 ways to fry an egg' 1998"
# {"cooking_book" => ["20 ways to fry an egg"], "year" => [1998]}

input = "cooking_book: 'How I survived 2 years with only a microwave' year: 2008"
# {"cooking_book" => ["How I survived 2 years with only a microwave"], "year" => [2008]}
```

```ruby
# Parameters = ["books: list", "is_books_cool=false: bool"]

input = "['moby dick' 'pride n\' prejudice' 'hamlet'] true"
# {"books" => [["moby_dick", "pride n\' prejudice", "hamlet"]], "is_books_cool" => [true]}

input = "['assembly for noobs'] false"
# {"books" => [["assembly for noobs"]], "is_books_cool" => [false]}
```
