-- This module manages parsing special lua comment syntax into documentation metadata,
-- and generating HTML from this metadata.

require "parser_utils"
require "utils"

local tag_normal = "line"
local tag_head = "head"

--== parse_file
--[c]  parse_file(input_text, output_table)
--=  Parses a lua file, extracting information from comments and putting it into @output_table
--=  input_text:  The text contents of the lua file to parse
--=  output_text: A table to generate the extracted information into
function parse_file(input_text, output_table)
    -- get a local parser instance
    local parser = clone(parser)
    parser.text = input_text
    
    -- store some other metadata in the parser temporarily
    parser.current_comment_type = nil -- can be one of nil, "head", "code", "comment"
    
    while not parser:at_end() do
        if parser:skip("--= ") then
            -- we got a normal comment
            store_comment_type(parser, output_table)
            parser.current_comment_type = tag_normal
            parser.current_comment_value = parser:skip_to_next_line()
        elseif parser:skip("--== ") then
            -- we got a head comment
            store_comment_type(parser, output_table)
            parser.current_comment_type = tag_head
            parser.current_comment_value = parser:skip_to_next_line()
        elseif parser:is_next_pattern("--%[(.)%] ") then
            -- we got a special comment type
            match, format_char = parser:skip_pattern("--%[(.)%]")
            
            store_comment_type(parser, output_table)
            parser.current_comment_type = format_char
            parser.current_comment_value = parser:skip_to_next_line()
        else
            if parser.current_comment_type then
                -- store the comment in the table
                store_comment_type(parser, output_table)
            end
            
            parser:skip_to_next_line()
        end
    end
end

--= store_comment_type(parser, output_table)
--= Stores the comment the parser has last parsed into the output table,
--  then resets the parser's comment.
function store_comment_type(parser, output_table)
    -- if there's no comment, do nothing
    if parser.current_comment_type == nil then return end

    local new_entry = {
        type = parser.current_comment_type,
        value = parser.current_comment_value
    }
    
    table.insert(output_table, new_entry)
    
    parser.current_comment_type = nil
    parser.current_comment_value = nil
end

--== generate_html
--=  html = generate_html(metadata)
--=  Takes a table with metadata as populated by `parse_file` and generates an HTML document from it.
function generate_html(metadata)
    html = "<html><head><title>Documentation Test</title></head><body>"
    
    -- generate the TOC
    html = html .. "<div class='tocBox'>\n"
    html = html .. "<div class='tocHead'>Table of Contents</div>\n"
    for i, entry in ipairs(metadata) do
        if entry.type == tag_head then
            html = html .. "<div class='tocEntry'><a href='#"..tostring(i).."'>"..entry.value.."</a></div>\n"
        end
    end
    html = html .. "</div>\n"
    
    -- generate the body
    html = html .. "<div class='docBox'>\n"
    for i, entry in ipairs(metadata) do
        if entry.type == tag_head then
            html = html .. "<div class='docHead'><a name='"..tostring(i).."'>"..entry.value.."</a></div>\n"
        else
            html = html .. "<div class='doc_"..entry.type.."'>"..entry.value.."</div>\n"
        end
    end
    html = html .. "</div>\n"
    
    html = html.."</body></html>"
    
    return html
end