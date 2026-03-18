package.path = "/usr/lib/tapeify/?.lua;" .. package.path

local shell = require("shell")
local args, opts = shell.parse(...)

local component = require("component")
local event = require("event")
local term = require("term")

local md = require("metadata")
local mdeditor = require("metadataeditor")
local utils= require("utils")
local renderer = require("renderer")
local lyricsparser = require("lyricsparser")

local tape = component.tape_drive

local metadata = {}

local state = {
    system = "NOTAPE", -- NOTAPE, READ, PLAYER, EDITOR, SHUTDOWN, METADATA
    playback = "STOPPED", -- PLAYING, PAUSED, STOPPED, ENDED
    loop = false,
    position = 0,   -- ms
    duration = 0,   -- ms

    title = "",
    artist = "",
    album = "",
    year = "",
    tracknumber = "",
    genreid = "",
    genre = "",
    comment = "",
    uniqueid = "",

    hasart = false,
    haslyric = false,

    lyrictable = {},
    lyric = "",
    art = ""
}

-- INPUT ------------------

local input = 0

local function handleInput()
    local e,_,_,key = event.pull(0.1,"key_down")

    input = key
end

-- INPUT ENDS -----------

-- TAPE DATA ------------

local function checkTape()
  if not tape.isReady() then
    if state.system ~= "NOTAPE" and state.system ~= "SHUTDOWN" then
      state.system = "NOTAPE"
    end
  else
    if state.system == "NOTAPE" then
      state.system = "READ"
    end
  end
end

local function readTape()
    tape.stop()
    tape.seek(tape.getSize())
    tape.seek(-8191)
    local bytes = tape.read(8192)
    if md.tagExist(bytes) then
        -- print("metadata found")
        metadata = md.unpackMetadata(bytes)
        return true
    else
        -- print("Metadata not found")
        return false
    end
end

-- TAPE DATA ENDS ------------

-- PLAYBACK CONTROLS -----------------------------

local function resumePlayback()
  state.playback = "PLAYING"
  tape.play()
end

local function playFromStart()
  state.position = 0
  state.playback = "PLAYING"

  tape.seek(-math.huge)
  tape.play()
end

local function pausePlayback()
  state.playback = "PAUSED"
  tape.stop()
end

local function stopPlayback()
  state.playback = "STOPPED"
  tape.stop()
  tape.seek(-math.huge)
end

-- for now stop and end are basically the same, its redundant
local function endPlayback()
  state.playback = "ENDED"
  tape.stop()
end

local function seek(second)
  tape.seek(second * 4096)
  state.position = tape.getPosition()
  if state.playback == "ENDED" then state.playback = "PAUSED" end
end

local function handlePlayback()
  if state.playback == "PLAYING" then pausePlayback()
  elseif state.playback == "PAUSED" then resumePlayback()
  elseif state.playback == "STOPPED" then playFromStart()
  elseif state.playback == "ENDED" then playFromStart() -- this too
  end
end

-- PLAYBACK CONTROLS ENDS -----------------------------

-- LYRICS HANDLER -------------------------

local lyricIndex = 1
local lyricLastPosition = 0

local function lyricFindIndex(lyrics, currentMs)
  local left, right = 1, #lyrics
  local result = 1

  while left <= right do
    local mid = math.floor((left + right) / 2)

    if lyrics[mid].time <= currentMs then
      result = mid
      left = mid + 1
    else
      right = mid - 1
    end
  end

  return result
end

local function lyricUpdateIndex(lyrics, index, currentMs)
  while index < #lyrics and lyrics[index + 1].time <= currentMs do
    index = index + 1
  end
  return index
end

local function lyricUpdate()
  if state.position < lyricLastPosition then
    lyricIndex = lyricFindIndex(state.lyrictable, state.position)
  else
    lyricIndex = lyricUpdateIndex(state.lyrictable, lyricIndex, state.position)
  end

  lyricLastPosition = state.position

  return state.lyrictable[lyricIndex] and state.lyrictable[lyricIndex].text or nil
end

-- LYRICS HANDLER ENDS --------------------------

-- STATE FUNCTIONS -----------------------------

local function notape()
  -- print("No tape detected in tape drive.")
  -- print("Insert a tape")
  if input == 16 then -- Q
    state.system = "SHUTDOWN"
  end
end

local function read()

    if readTape() then 
        state.title = md.readTitle(metadata)
        state.artist = md.readArtist(metadata)
        state.album = md.readAlbum(metadata)
        state.year = md.readYear(metadata)
        state.tracknumber = md.readTrackNumber(metadata)
        state.genreid = md.readGenreId(metadata)
        state.genre = md.readGenre(metadata)
        state.comment = md.readComment(metadata)
        state.uniqueid = md.readUniqueID(metadata)

        state.hasart = md.hasAsciiArt(metadata)
        if (state.hasart) then
          state.art = md.readAsciiArt(metadata)
        else
          state.art = ""
        end
        
        state.haslyric = md.hasLyrics(metadata)
        if (state.haslyric) then
          state.lyrictable = lyricsparser.unpackData(md.readLyrics(metadata))
        else
          state.lyrictable = {}
        end

        state.duration = utils.bytesToMs(md.readDuration(metadata))
    else
        state.title = "Unknown"
        state.artist = "Unknown"
        state.album = "Unknown"
        state.year = "Unknown"
        state.tracknumber = "Unknown"
        state.genreid = "Unknown"
        state.genre = "Unknown"
        state.comment = "Unknown"
        state.uniqueid = "Unknown"
        state.hasart = "Unknown"
        state.haslyric = "Unknown"

        state.art = ""
        state.lyrictable = {}
        state.lyric = ""

        state.duration = utils.bytesToMs(tape.getSize())
    end

  state.system = "PLAYER"
  playFromStart()
end

local function player()
  if input == 16 then -- Q
    state.system = "SHUTDOWN"
  elseif input == 0x39 then -- Space
    handlePlayback()
  elseif input == 0xCB then -- left
    seek(-5)
  elseif input == 0xCD then -- right
    seek(5)
  elseif input == 0x12 then -- E
    state.system = "EDITOR"
  elseif input == 0x26 then -- L
    state.loop = not state.loop
  elseif input == 0x13 then -- R
    playFromStart()
  elseif input == 0x32 then -- M
    state.system = "METADATA"
  end
end

local function metadataview()
  if input == 16 then -- Q
    state.system = "PLAYER"
  end
end

local function editor()
  local ok, err = pcall(mdeditor.runEditor)

  if ok then
    print("Editor closed")
  else
    print("Editor crashed: ", err)
  end

  state.system = "READ"

  io.write("\nPress any key to continue...")
  event.pull("key_down")
end

local function shutdown()
  stopPlayback()
  -- print("Shutting down tape player.")
  term.clear()
end

local function updateState()
    state.position = utils.bytesToMs(tape.getPosition())

    state.lyric = lyricUpdate()

    if state.position >= state.duration then
      if state.loop then playFromStart()
      else endPlayback()
    end
  end
end

-- STATE FUNCTIONS ENDS -----------------------------

local function main()

  -- editor only
  if args[1] == "editor" then
    local ok, err = pcall(mdeditor.runEditor)

    if ok then
      print("Editor closed")
    else
      print("Editor crashed: ", err)
    end

    term.clear()
    return
  end

  state.system = "NOTAPE"

  while true do
    checkTape()
    handleInput()
    if state.system == "NOTAPE" then
      notape()
    elseif state.system == "READ" then
      read()
    elseif state.system == "PLAYER" then
      player()
    elseif state.system == "METADATA" then
      metadataview() 
    elseif state.system == "EDITOR" then
      editor()
    elseif state.system == "SHUTDOWN" then
      shutdown()
      break
    end
    updateState()
    renderer.render(state)

    -- term.clear()
    -- print("state.system: ", state.system)
    -- print("state.playback: ", state.playback)
  end
end

main()