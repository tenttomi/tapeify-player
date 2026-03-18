local M = {}

function M.uuid32()
  local t = {}
  for i = 1, 8 do
    t[i] = string.char(math.random(0,255))
  end
  return table.concat(t)
end

function M.uuid64()
  local t = {}
  for i = 1, 16 do
    t[i] = string.char(math.random(0,255))
  end
  return table.concat(t)
end

function M.uuid32toHex(uuid)
    local output = {}
    for i = 1, #uuid do
        output[#output+1] = string.format("%02x", uuid:byte(i))

        if i % 2 == 0 and i % 8 ~= 0 then
            output[#output+1] = "-"
        end
    end

    return table.concat(output)
end

function M.fitString(str, n)
    local len = #str
    if len > n then
        return string.sub(str, 1, n)
    elseif len < n then
        return str .. string.rep("\0", n - len)
    else
        return str
    end
end

----------------------------------

function M.has_flag(mask, flag)
    return (mask & flag) ~= 0
end

function M.toggle_flag(mask, flag)
    return mask ~ flag
end

function M.set_flag(mask, flag)
    return mask | flag
end

function M.clear_flag(mask, flag)
    return mask & (~flag)
end

------------------------------------

function M.read_text_file(filename)
    local file = io.open(filename, "r")
    if not file then
        error("File not found: " .. tostring(filename))
    end
    local content = file:read("*a")
    file:close()
    return content
end

-------------------------------------


function M.bytesToMs(bytes)
    return bytes * 1000 / 4096
end

function M.msToBytes(ms)
    return math.floor(ms * 4096 / 1000)
end

return M