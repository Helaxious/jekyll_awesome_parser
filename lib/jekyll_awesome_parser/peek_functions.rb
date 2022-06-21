# frozen_string_literal: true

class JekyllAwesomeParser
  # Looks if there's an letter in a string in the left, or in the right of the pointer
  def peek(string, pointer, direction, target, stop=nil)
    stop = Array(stop) if stop.instance_of?(String)
    target = Array(target) if target.instance_of?(String)

    direction = ({ "left" => -1, "right" => 1 })[direction]
    if (0 <= pointer + direction) && (pointer + direction <= string.size - 1)
      return [true, "match", pointer + direction] if target.include?(string[pointer + direction])
      return [false, "stop", pointer + direction] if stop != nil && (stop.include?(string[pointer + direction]))
      return [false, "no_match", pointer + direction]
    end
    return [false, "end_of_string", string.size - 1]
  end

  # Peeks continuously in one direction, and returns True if it eventually matches
  def peek_until(string, pointer, direction, target, stop=nil)
    pointer_direction = ({ "left" => -1, "right" => 1 })[direction]
    peek_pointer = pointer
    while true
      peek_pointer += pointer_direction
      result = peek(string, peek_pointer, direction, target, stop)
      return result if ["match", "end_of_string", "stop"].include?(result[1])
    end
  end

  # Returns True if the peek_until eventually doesn't match
  def peek_until_not(string, pointer, direction, target)
    pointer_direction = ({ "left" => -1, "right" => 1 })[direction]
    peek_pointer = pointer
    while true
      peek_pointer += pointer_direction
      result = peek(string, peek_pointer, direction, target, nil)
      return [true, "match", peek_pointer + pointer_direction] if result[1] == "no_match"
      return [false, "no_match", peek_pointer + pointer_direction] if result[1] == "end_of_string"
    end
  end

  # Does a peek_until, then does a peek (eg: peek_until ' ' then peeks for the letter '(')
  # '       (potato)'  #  '(potato)'
  #  ^      ^ match!   #   ^ doesn't match!
  #  pointer           # pointer
  def peek_after(string, pointer, direction, target, target_after, stop=nil)
    stop = [] if stop.nil?
    stop = Array(stop) if stop.instance_of?(String)
    target_after = Array(target_after) if target_after.instance_of?(String)

    if peek(string, pointer, "right", target)[0] == true
      second_peek = peek_until_not(string, pointer, direction, target)
      return second_peek if second_peek[0] == "no_match"

      is_stop = stop.include?(string[second_peek[2]])
      return [false, "stop", second_peek[2]] if is_stop
      return [target_after.include?(string[second_peek[2]]), "match", second_peek[2]]
    else
      return [false, "no_match", pointer]
    end
  end
end
