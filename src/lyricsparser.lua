local utils = require "utils"
-- TODO: Need work

local M = {}

local function time_to_ms(time_str)
    local minutes, seconds, hundredths = time_str:match("(%d+):(%d+)%.(%d+)")
    if not minutes then
        error("Invalid timestamp format: " .. tostring(time_str))
    end
    return tonumber(minutes) * 60000 + tonumber(seconds) * 1000 + tonumber(hundredths) * 10
end

local function parse_from_text(text)
    local lines = {}

    for line in text:gmatch("[^\r\n]+") do
        if line:match("%S") then
            local time_str, line_text = line:match("%[(%d+:%d+%.%d+)%]%s*(.*)")
            if time_str then
                local ms = time_to_ms(time_str)
                table.insert(lines, {time = ms, text = line_text})
            end
        end
    end

    table.sort(lines, function(a, b) return a.time < b.time end)

    return lines
end

function M.readFromFile(filename)
    local ok, content = pcall(utils.read_text_file, filename)
    if ok then
        print (content)
        return parse_from_text(content)
    else
        return content
    end
end

function M.unpackData(input)

    local lines = {}
    local linesLength = string.unpack(">H", input:sub(1,2))

    -- local encoding = string.byte(input, 3)

    local offset = 5
    for i=1, linesLength do
        local line = {}
        local time = string.unpack(">L", input:sub(offset, offset + 3))

        offset = offset + 4
        local lineCharCount = string.byte(input, offset)

        offset = offset + 1

        local text = input:sub(offset, offset + lineCharCount - 1 )

        offset = offset + lineCharCount

        table.insert(lines, {time = time, text = text})
    end

    return lines
end

function M.packData(t)
    local linesCount = 0
    local encoding = 1
    local packed = {}

    -- [1..2] = lines count, [3] = encoding, [4] == unused,
    for _, value in pairs(t) do
        packed[(linesCount * 3) + 4] = string.pack(">L", value.time)
        packed[(linesCount * 3) + 5] = string.pack(">B", #value.text)
        packed[(linesCount * 3) + 6] = value.text
        
        linesCount = linesCount + 1
    end

    packed[1] = string.pack(">H",linesCount)
    packed[2] = string.pack(">B", encoding)
    packed[3] = "\x00"

    return table.concat(packed)
end

return M