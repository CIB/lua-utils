parser = { text = "", pos = 1, line = 1 }

-- returns true if we are done parsing the text
function parser:at_end()
  return (self.pos > self.text:len())
end

-- returns the next @amount characters ahead in the stream, or nil if not that many chars are left
function parser:get_next(amount)
	if self.pos + amount > self.text:len() then
		return nil
	end

	return self.text:sub(self.pos, self.pos + amount - 1)
end

-- returns the next char ahead in the stream, or nil if we're at the end
function parser:get_char()
    return self:get_next(1)
end

-- checks if the given word is ahead in the stream, returns true if yes, false otherwise
function parser:is_next(word)
    local compare = self:get_next(word:len())
    
    if not compare then return false end

	if word == "\n" and compare == "\n" then
		self.line = self.line + 1
	end

	return (compare == word)
end

-- skips a given amount of characters
function parser:skip_amount(amount)
    for i = 1, amount do
        local chr = self.text[self.pos]
        if chr == "\n" then
            self.line = self.line + 1
        end
        self.pos = self.pos + 1
    end
end

-- checks if @word is ahead in the stream, and if so, skips past it, otherwise does nothing
-- return is equivalent to parser:is_next()
function parser:skip(word)
	if self:is_next(word) then
		self:skip_amount(word:len())
		return true
	else
		return false
	end
end

-- matches the string ahead against a lua expression
-- returns nil if the match failed, 
-- otherwise a pair of the matched string, and a table containing all captures
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

-- matches the string ahead against a lua expression, and skips it if successful
-- returns the same as parser:is_next_pattern
function parser:skip_pattern(pattern)
    local result, captures = self:is_next_pattern(pattern)
    
    if not result then return nil end
    
    self:skip_amount(result:len())
    
    return result, unpack(captures)
end

-- skips all upcoming spaces(\s or \t)
function parser:skip_spaces()
    self:skip_pattern("[ \t]*")
end
