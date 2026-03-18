local component = require("component")
local gpu = component.gpu

local M = {}

local function centerText(x, width, text)
    return x + math.floor((width - #text) / 2)
end

local function formatTime(ms)
    local sec = math.floor(ms / 1000)
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d", m, s)
end

local function drawBorder(x, y, w, h)
    gpu.set(x, y, "┌" .. string.rep("─", w-2) .. "┐")

    for i=1,h-2 do
        gpu.set(x, y+i, "│")
        gpu.set(x+w-1, y+i, "│")
    end

    gpu.set(x, y+h-1, "└" .. string.rep("─", w-2) .. "┘")
end

local function drawProgressBar(x, y, w, progress)
    local filled = math.floor(progress * w)

    local bar =
        string.rep("█", filled) ..
        string.rep("░", w-filled)

    gpu.set(x, y, bar)
end

local function drawAsciiArt(art)
    if not art then return end

    local line = ""

    for i = 0, 43 do
        line = art:sub(1 + (i * 80), (i + 1) * 80)
        gpu.set(1, i+1, line)
    end
end

local function drawKeyGuide(x, y, width, data)

    if (data.system == "PLAYER") then
        local line1 = "[SPACE] Pause   [←/→] Seek"
        local line2 = "[R] Restart   [L] Loop"
        local line3 = "[M] Metadata   [E] Edit   [Q] Exit"

        gpu.set(centerText(x,width,line1), y, line1)
        gpu.set(centerText(x,width,line2), y+1, line2)
        gpu.set(centerText(x,width,line3), y+2, line3)
    
    elseif (data.system == "METADATA") then
        local line3 = "[Q] Back"
        gpu.set(centerText(x,width,line3), y+2, line3)

    elseif (data.system == "NOTAPE") then
        local line3 = "[Q] Exit"
        gpu.set(centerText(x,width,line3), y+2, line3)
    end  
end

local function drawLyrics(x, y, width, lyrics)
    if not lyrics or lyrics == "" then
        return
    end

    local text = "♪ " .. lyrics

    gpu.set(centerText(x, width, text), y, text)
end

local function drawPlayer(x, y, w, h, data, small)

    local yPos ={}

    if small then
        yPos = {
        title = 3,
        artist = 4,
        time = 6,
        loop = 7,
        progress = 8,
        playback = 9,
        lyric = 10
    }
    else
        yPos = {
        title = 4,
        artist = 6,
        time = 9,
        loop = 10,
        progress = 11,
        playback = 12,
        lyric = 15
    }
    end

    gpu.set(x+3, y+yPos.title, "TITLE : "..(data.title or ""))
    gpu.set(x+3, y+yPos.artist, "ARTIST: "..(data.artist or ""))

    local t = formatTime(data.position or 0)
    local d = formatTime(data.duration or 0)

    local timeStr = t.." / "..d

    gpu.set(centerText(x,w,timeStr), y+yPos.time, timeStr)

    local barWidth = w-10
    local progress = 0

    if data.duration and data.duration > 0 then
        progress = (data.position or 0) / data.duration
    end

    local loopStr = ""
    if (data.loop) then loopStr = "LOOP ON" else loopStr = "LOOP OFF" end

    gpu.set(x + w - 13, y+yPos.loop, loopStr)
    drawProgressBar(x+5, y+yPos.progress, barWidth, progress)

    if (data.playback == "PAUSED") then
        gpu.set(centerText(x, w, "PAUSED"), y+yPos.playback, "PAUSED")
    end

    drawLyrics(x, y+yPos.lyric, w, data.lyric)

end

local function drawMetadata(x, y, w, h, data)
    gpu.set(x+3, y+2, "TITLE : "..(data.title or ""))
    gpu.set(x+3, y+3, "ARTIST: "..(data.artist or ""))
    gpu.set(x+3, y+4, "ALBUM: "..(data.album or ""))
    gpu.set(x+3, y+5, "YEAR: "..(data.year or ""))
    gpu.set(x+3, y+6, "TRACK NUMBER: "..(data.tracknumber or ""))
    gpu.set(x+3, y+7, "GENREID: "..(data.genreid or ""))
    gpu.set(x+3, y+8, "GENRE: "..(data.genre or ""))
    gpu.set(x+3, y+9, "COMMENT: "..(data.comment or ""))
    gpu.set(x+3, y+10, "UNIQUEID: "..(data.uniqueid or ""))
    gpu.set(x+3, y+11, "DURATION: "..(data.duration or ""))
    gpu.set(x+3, y+12, "COVER ART: "..(tostring(data.hasart) or ""))
    gpu.set(x+3, y+13, "LYRICS: "..(tostring(data.haslyric) or ""))
end

local function drawPlayerBody(x, y, w, h, data, small)

    drawBorder(x,y,w,h)

    local title = "== Tapeify Player v0.5.0 =="

    gpu.set(centerText(x,w,title), y+1, title)

    if data.system == "PLAYER" then
        drawPlayer(x, y, w, h, data, small)
    elseif data.system == "METADATA" then
        drawMetadata(x, y, w, h, data)
    elseif data.system == "READ" then
        gpu.set(x+3, y+4, "READING TAPE...")
    elseif data.system == "NOTAPE" then
        gpu.set(x+3, y+4, "PLEASE INSERT TAPE")
    elseif data.system == "SHUTDOWN" then
        gpu.set(x+3, y+4, "SHUTTING DOWN")
    end

    if (small) then drawKeyGuide(x, y+h-4, w, data)
    else drawKeyGuide(x, y+h-5, w, data) end
end

function M.render(data)

    local sw, sh = gpu.getResolution()

    gpu.fill(1,1,sw,sh," ")

    if sw >= 160 and sh >= 50 then

        if (data.art == "") then
            drawPlayerBody(1,1,sw,sh,data)
        else
            drawAsciiArt(data.art)

            drawPlayerBody(81,1,80,sh,data)
        end
    elseif (sw >= 80 and sh >= 25) then

        drawPlayerBody(1,1,sw,sh,data)
    
    else
        drawPlayerBody(1,1,sw,sh,data, true)
    end
end

return M