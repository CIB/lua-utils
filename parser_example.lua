-- this is a simple demonstration of the `parser_utils.lua` module
-- it implements a parser for a very simple grammar as defined below

-- syntax example this file can parse:
-- ``key`` = ``value``
-- ``key`` is a simple A-Za-z string
-- ``value`` is either a ' quoted string, or a number

require "parser_utils"

-- normally you should clone the parser using a deepcopy function
-- for this test case, we'll simply use the standard one
parser.text = "foo = 5\nbar = 'hello'"

key_value_pairs = { }

function parser_error(err)
    error("Error on line "..tostring(parser.line)..": "..err)
end

-- now parse the text line by line
while not parser:at_end() do
    -- parse the left-hand expression / the key
    -------------------------------------------
    local key = parser:skip_pattern("[A-Za-z]+")
    if not key then
        parser_error("Expected key at start of line.")
    end
    
    -- parse the `=` in the middle
    ------------------------------
    parser:skip_spaces()
    
    if not parser:skip("=") then
        parser_error("Expected `=` after key.")
    end
    
    parser:skip_spaces()
    
    -- parse the right-hand expression which can either be a string or a number
    ---------------------------------------------------------------------------
    local value
    
    if parser:skip("'") then
        -- parse a single quoted string
        local match, string_content = parser:skip_pattern("([^'\n]*)'")
        
        if not match then
            parser_error("String not closed.")
        end
        
        value = string_content 
    else
        local number = parser:skip_pattern("[0-9]+")
        if not number then
            parser_error("Value of unknown type.")
        end
        
        value = tonumber(number)
    end
    
    parser:skip_spaces()
    
    -- make sure the end lines after this
    -------------------------------------
    if not parser:skip("\n") and not parser:at_end() then
        parser_error("Unexpected text at end of line.")
    end
    
    key_value_pairs[key] = value
end