local component = require("component")
local fs = require("filesystem")

if not component.isAvailable("internet") then
  error("Internet card required!")
end

local internet = component.internet

local BASE_URL = "https://raw.githubusercontent.com/tenttomi/tapeify-player/main/src/"

local INSTALL_DIR = "/usr/lib/tapeify/"
local EXEC_PATH = "/usr/bin/tapeify"

local FILES = {
  "tapeify.lua",
  "metadata.lua",
  "metadataeditor.lua",
  "renderer.lua",
  "tapeanalyzer.lua",
  "lyricsparser.lua",
  "utils.lua",
  "crc32lua.lua",
}

local function download(url, path)
  io.write("Downloading: " .. url .. " ... ")

  local handle, err = internet.request(url)
  if not handle then
    print("FAILED")
    error(err)
  end

  local file, ferr = io.open(path, "wb")
  if not file then
    handle.close()
    error("File error: " .. tostring(ferr))
  end

  while true do
    local chunk = handle.read(math.huge)
    if not chunk then break end
    file:write(chunk)
  end

  file:close()
  handle.close()

  os.sleep(0.1)
  print("OK")
end

if not fs.exists("/usr") then fs.makeDirectory("/usr") end
if not fs.exists("/usr/bin") then fs.makeDirectory("/usr/bin") end
if not fs.exists("/usr/lib") then fs.makeDirectory("/usr/lib") end
if not fs.exists(INSTALL_DIR) then fs.makeDirectory(INSTALL_DIR) end

for _, file in ipairs(FILES) do
  download(BASE_URL .. file, INSTALL_DIR .. file)
end

local f, err = io.open(EXEC_PATH, "w")
if not f then
  error("Failed to create launcher: " .. tostring(err))
end

f:write([[local shell = require("shell")
shell.execute("/usr/lib/tapeify/tapeify.lua", nil, ...)
]])
f:close()

print("\n✅ Installed!")
print("Run with: tapeify")