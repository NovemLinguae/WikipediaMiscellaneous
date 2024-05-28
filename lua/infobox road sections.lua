local p = {}

local concat = table.concat
local insert = table.insert
--local format = mw.ustring.format
--local frame = mw.getCurrentFrame()

function p._section(args, num)
	local lengthModule = require "Module:Infobox road/length"
    local length = lengthModule._length(num, args)
    local title 
		if num == '' then title = "Major intersections"
		else title = args["section" .. num] or 'Section ' .. num
    	end
	local dir_a = args["direction_a" .. num] or args.direction_a or ''
    local dir_b = args["direction_b" .. num] or args.direction_a or ''
	local end_a = args["terminus_a" .. num] or args["end_a" .. num] or ''
    local end_b = args["terminus_b" .. num] or args["end_b" .. num] or ''
    local jcts = args["junction" .. num] or ''
    local direction_a
    	if dir_a == '' then direction_a = 'From'
    	else direction_a = dir_a .. ' end'
    	end
    local direction_b
    	if dir_b == '' then direction_b = 'To'
    	else direction_b = dir_b .. ' end'
    	end
		
	return frame:expandTemplate{ title = 'infobox', args = 
		  { title = title,
			label1 = "Length",
			data1 = length,
			label2 = direction_a,
			data2 = end_a,
			label3 = "Major junctions",
			data3 = jcts,
			label4 = direction_b,
			data4 = end_b,
			child = "yes",
			decat = "yes"
		} }
end
    

function p.section(frame)
    local pframe = frame:getParent()
    local config = frame.args -- the arguments passed BY the template, in the wikitext of the template itself
    local args = pframe.args -- the arguments passed TO the template, in the wikitext that transcludes the template
    
    local num = config.num or ''
    return p._section(args, num)
end

--return p

-- {{#invoke:Infobox road/sections|section|num=1}}
frame = {args = {num = 1}}
print(p.section(frame))