-- This module contains a few very simple helpers for parsing text with lua.
-- 
-- The basic idea behind is that the parsing state(parsed text, current position, current line)
-- will be kept in a central state object, from which you can do various operations, such as
-- checking what the next text will be, advancing the cursor, and so on.
--
-- See `parser_example.lua` for a simple "howto"

--** parser
--*? The parser state object, copy this for personal use
parser = { 
    text = "", 
    pos = 1, 
    line = 1 
}

--** parser:at_end
--*@ is_at_end = parser:at_end()
--*? Returns true if the cursor is at the end of the text.
function parser:at_end()
  return (self.pos > self.text:len())
end

--** parser:get_next
--*@ next_characters = parser:get_next(amount)
--*? Returns the next @amount characters ahead in the text, or nil if not that many chars are left.
function parser:get_next(amount)
	if self.pos + amount > self.text:len() then
		return nil
	end

	return self.text:sub(self.pos, self.pos + amount - 1)
end

--** parser:get_char
--*@ next_char = parser:get_char()
--*? Returns the next char ahead in the stream, or nil if we're at the end.
function parser:get_char()
    return self:get_next(1)
end

--** parser:is_next
--*@ word_is_next = parser:is_next(word)
--*? Checks if the given word is ahead in the stream, returns true if yes, false otherwise.
function parser:is_next(word)
    local compare = self:get_next(word:len())
    
    if not compare then return false end

	if word == "\n" and compare == "\n" then
		self.line = self.line + 1
	end

	return (compare == word)
end

--** parser:skip_amount
--*@ skipped_text = parser:skip_amount(amount)
--*? Skips a given amount of characters.
function parser:skip_amount(amount)
    local start = self.pos
    for i = 1, amount do
        local chr = self.text[self.pos]
        if chr == "\n" then
            self.line = self.line + 1
        end
        self.pos = self.pos + 1
        
        -- if we're at the end of the stream already, abort
        if self:at_end() then break end
    end
    
    return self.text:sub(start, self.pos-1)
end

--** parser:skip
--*@ has_skipped_word = parser:skip(word)
--*? Checks if @word is ahead in the stream, and if so, skips past it, otherwise does nothing.
--   Return value is equivalent to parser:is_next()
function parser:skip(word)
	if self:is_next(word) then
		self:skip_amount(word:len())
		return true
	else
		return false
	end
end

--** parser:is_next_pattern
--*@ matched_string, captures = parser:is_next_pattern(pattern)
--*? Matches the string ahead against a lua expression, then returns nil if the match failed, 
--   otherwise a pair of the matched string, and a table containing all captures.
function parser:is_next_pattern(pattern)
    local substring_to_search = self.text:sub(self.pos, self.text:len())
    
    local results = {string.find(substring_to_search, pattern)}
    
    local start, stop = unpack(results)
    
    if start ~= 1 then return nil end
    
    local i = 3
    local captures = {}
    while true do
        if i > #results then break end
        
        table.insert(captures, results[i])
        i = i + 1
    end
    
    return substring_to_search:sub(start, stop), captures
end

--** parser:skip_pattern
--*@ matched_string, capture1, capture2, ... = parser:skip_pattern(pattern)
--*? Matches the string ahead against a lua expression, and skips it if successful.
--   Returns the same as parser:is_next_pattern
function parser:skip_pattern(pattern)
    local result, captures = self:is_next_pattern(pattern)
    
    if not result then return nil end
    
    self:skip_amount(result:len())
    
    return result, unpack(captures)
end

--** parser:skip_spaces
--*@ parser:skip_spaces()
--*? Skips all upcoming spaces(\s or \t)
function parser:skip_spaces()
    self:skip_pattern("[ \t]*")
end

--** parser:skip_to_next_line
--*@ parser:skip_to_next_line()
--*? Advances the cursor past this line to the next one.
function parser:skip_to_next_line()
    local rval = ""
    while not self:skip("\n") and not self:at_end() do
        rval = rval .. self:skip_amount(1)
    end
    
    return rval
end
