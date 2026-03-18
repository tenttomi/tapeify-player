local md = require("metadata")
local lyrics = require("lyricsparser")
local utils = require("utils")
local analyzer = require("tapeanalyzer")
local event = require("event")

local term = require("term")
local component = require("component")
local tape = component.tape_drive

local metadata = {}
local metadataOriginal = {}

local standalone = false
local exit = false

local M = {}

local function pressAnyKey()
    io.write("\nPress any key to continue...")
    event.pull("key_down")
end

-- TODO: Maybe this shouldnt be here, prolly should be in main program instead but idk
local function readTape()
    tape.stop()
    tape.seek(tape.getSize())
    tape.seek(-8191)
    local bytes = tape.read(8192)
    if md.tagExist(bytes) then
        print("TPFY tag found")
        metadata = md.unpackMetadata(bytes)
        metadataOriginal = md.unpackMetadata(md.packMetadata(metadata))
        return true
    else
        while true do
            print("TPFY tag not found, initialize tag? [y/N]")
            local input = io.read()
            if input == "y" then
                md.initializeTag(metadata)
                metadataOriginal = md.unpackMetadata(md.packMetadata(metadata))
                return true
            elseif input == "N" then
                return false
            end
        end
    end
end

local function writeTape()
    tape.stop()
    tape.seek(tape.getSize())
    tape.seek(-8191)
    tape.write(md.packMetadata(metadata))
end

local function clearMetadata()
    tape.stop()
    tape.seek(tape.getSize())
    tape.seek(-8191)
    tape.write(string.rep("\0", 8192))
end

local function showMetadata()
    print("Title: \t\t" .. md.readTitle(metadata))
    print("Artist: \t" .. md.readArtist(metadata))
    print("Album: \t\t" .. md.readAlbum(metadata))
    print("Year: \t\t" .. md.readYear(metadata))
    print("TrackNumber: \t" .. md.readTrackNumber(metadata))
    print("GenreId: \t" .. md.readGenreId(metadata))
    print("Genre: \t\t" .. md.readGenre(metadata))
    print("Comment: \t" .. md.readComment(metadata))
    print("UniqueID: \t" .. md.readUniqueID(metadata))
    print("Duration: \t" .. md.readDuration(metadata))
    print("FeatureFlags: \t" .. "AsciiArt: " .. tostring(md.hasAsciiArt(metadata)) .. " Lyrics: " .. tostring(md.hasLyrics(metadata)))
end

local function showDetailed()
    print("Metadata")
    print("Checksum: \t" .. md.readChecksum(metadata))
    print("MetaVersion: \t" .. md.readVersion(metadata))
    print("EncoderUsed: \t" .. md.readEncoderUsed(metadata))
    print("EncoderFlags: \t" .. md.readEncoderFlags(metadata))
    print("UniqueID: \t" .. md.readUniqueID(metadata))
    print("Duration: \t" .. md.readDuration(metadata))
    print("FeatureFlags: \t" .. md.readFeatureFlags(metadata))
    print("Title: \t\t" .. md.readTitle(metadata))
    print("Artist: \t" .. md.readArtist(metadata))
    print("Album: \t\t" .. md.readAlbum(metadata))
    print("Year: \t\t" .. md.readYear(metadata))
    print("TrackNumber: \t" .. md.readTrackNumber(metadata))
    print("GenreId: \t" .. md.readGenreId(metadata))
    print("Genre: \t\t" .. md.readGenre(metadata))
    print("Comment: \t" .. md.readComment(metadata))
end

local function show_menu()
    print("=== Metadata Editor ===")
    print("1. Show Metadata")
    print("2. Analyze length")
    print("3. Edit Metadata")
    print("4. Edit Features")
    -- print("2. Edit Title")
    -- print("3. Edit Artist")
    -- print("4. Edit Album")
    -- print("5. Edit Year")
    -- print("6. Edit Track number")
    -- print("7. Edit GenreId")
    -- print("8. Edit Genre")
    print("5. Show (Detailed)")
    print("6. Save")
    print("7. Clear Metadata")
    print("8. Exit")
end

local function showComparison()
    print("Metadata")
    -- print("Checksum: \t" .. md.readChecksum(metadataOriginal).. " -> " .. md.readChecksum(metadata))
    -- print("MetaVersion: \t" .. md.readVersion(metadataOriginal).. " -> " .. md.readVersion(metadata))
    -- print("EncoderUsed: \t" .. md.readEncoderUsed(metadataOriginal).. " -> " .. md.readEncoderUsed(metadata))
    -- print("EncoderFlags: \t" .. md.readEncoderFlags(metadataOriginal).. " -> " .. md.readEncoderFlags(metadata))
    -- print("UniqueID: \t" .. md.readUniqueID(metadataOriginal).. " -> " .. md.readUniqueID(metadata))
    -- print("FeatureFlags: \t" .. md.readFeatureFlags(metadataOriginal).. " -> " .. md.readFeatureFlags(metadata))
    print("Title: \t\t" .. md.readTitle(metadataOriginal).. " -> " .. md.readTitle(metadata))
    print("Artist: \t" .. md.readArtist(metadataOriginal).. " -> " .. md.readArtist(metadata))
    print("Album: \t\t" .. md.readAlbum(metadataOriginal).. " -> " .. md.readAlbum(metadata))
    print("Year: \t\t" .. md.readYear(metadataOriginal).. " -> " .. md.readYear(metadata))
    print("TrackNumber: \t" .. md.readTrackNumber(metadataOriginal).. " -> " .. md.readTrackNumber(metadata))
    print("GenreId: \t" .. md.readGenreId(metadataOriginal).. " -> " .. md.readGenreId(metadata))
    print("Genre: \t\t" .. md.readGenre(metadataOriginal).. " -> " .. md.readGenre(metadata))
    print("Comment: \t" .. md.readComment(metadataOriginal).. " -> " .. md.readComment(metadata))
    print("Duration: \t" .. md.readDuration(metadataOriginal).. " -> " .. md.readDuration(metadata))
end

local menu_action = {}
local edit_action = {}
local feature_action = {}

menu_action["1"] = function()
    showMetadata()

    pressAnyKey()
end

menu_action["2"] = function()
    -- term.clear()
    md.writeDuration(metadata, analyzer.analyzeTape())

    pressAnyKey()
end

menu_action["3"] = function()
    print("Select data to edit: ")
    print("1. Edit Title")
    print("2. Edit Artist")
    print("3. Edit Album")
    print("4. Edit Year")
    print("5. Edit Track number")
    print("6. Edit GenreId")
    print("7. Edit Genre")
    print("8. Edit Comment")
    print("9. Edit Duration")

    local choice = io.read()

    local action = edit_action[choice]

        if action then
            action()
        else
            print("Invalid selection")
        end
end

menu_action["4"] = function()
    print("Select Features to edit: ")
    print("1. Add/Edit Ascii art")
    print("2. Show Ascii art")
    print("3. Remove Ascii art")
    print("4. Add/Edit Lyrics")
    print("5. Show Lyrics")
    print("6. Remove Lyrics")

    local choice = io.read()

    local action = feature_action[choice]

        if action then
            action()
        else
            print("Invalid selection")
        end
end

menu_action["5"] = function()
    showDetailed()
    
    pressAnyKey()
end

menu_action["6"] = function()
    showComparison()

    -- TODO: Maybe this shouldnt be here idk
    writeTape()

    print("SAVED.")
    pressAnyKey()
end

menu_action["7"] = function()
    while true do
        print("Confirm clear entire metadata? [Y/n]")
        local input = io.read()
        if input == "Y" then
            clearMetadata()

            print("CLEARED.")
            pressAnyKey()

            return
        elseif input == "n" then return end
    end
end

menu_action["8"] = function()
    exit = true
end

-- EDIT ACTIONS --

edit_action["1"] = function()
    io.write("New title (Max 64 char): ")
    local title = io.read()
    md.writeTitle(metadata, title)
end

edit_action["2"] = function()
    io.write("New Artist (Max 64 char): ")
    local artist = io.read()
    md.writeArtist(metadata, artist)
end

edit_action["3"] = function()
    io.write("New Album (Max 64 char): ")
    local album = io.read()
    md.writeAlbum(metadata, album)
end

edit_action["4"] = function()
    io.write("New Year: ")
    local year = tonumber(io.read())
    md.writeYear(metadata, year)
end

edit_action["5"] = function()
    io.write("New Track Number: ")
    local trackNumber = tonumber(io.read())
    md.writeYear(metadata, trackNumber)
end

edit_action["6"] = function()
    io.write("New GenreId (0-255): ")
    local genreId = tonumber(io.read())
    md.writeYear(metadata, genreId)
end

edit_action["7"] = function()
    io.write("New Genre  (Max 24 char): ")
    local genre = io.read()
    md.writeAlbum(metadata, genre)
end

edit_action["8"] = function()
    io.write("New Comment (Max 320 char): ")
    local comment = io.read()
    md.writeAlbum(metadata, comment)
end

edit_action["9"] = function()
    io.write("New Duration: ")
    local comment = tonumber(io.read())
    md.writeDuration(metadata, comment)
end

--------------------------------------------------


-- FEATURES ACTIONS ------

feature_action["1"] = function()
    io.write("Enter path to Ascii art: ")
    local path = io.read()

    local ok, res = pcall(utils.read_text_file, path)
    if ok then
        local s = res:gsub("[\r\n]", "")

        for i = 0, 43 do
            local start = (80 * (i)) + 1
            io.write(s:sub(start, start + 79), "\n")
        end

        md.writeAsciiArt(metadata, s)
        md.toggleAsciiArt(metadata, true)
    else
        print(res)
    end

    pressAnyKey()
end

feature_action["2"] = function()
    if not md.hasAsciiArt(metadata) then
        print("Ascii art disabled")

        pressAnyKey()
        return
    end

    local s = metadata[18]

    for i = 0, 43 do
        local start = (80 * (i)) + 1
        io.write(s:sub(start, start + 79), "\n")
    end

    pressAnyKey()

end

feature_action["3"] = function()
    io.write("Ascii Art disabled")
    md.toggleAsciiArt(metadata, false)

    pressAnyKey()
end

feature_action["4"] = function()
    io.write("Enter path to Lyrics: ")
    local path = io.read()
    local ok, res = pcall(lyrics.readFromFile, path)
    if ok then
        print("ok")
        md.writeLyrics(metadata, lyrics.packData(res))
        md.toggleLyrics(metadata, true)
    else
        print(res)
    end

    pressAnyKey()
end

feature_action["5"] = function()
    if not md.hasLyrics(metadata) then
        print("Lyrics disabled")

        pressAnyKey()
        return
    end
    for _,value in pairs(lyrics.unpackData(metadata[19])) do
        print (value.time, value.text)
    end

    pressAnyKey()
end

feature_action["6"] = function()
    io.write("Lyrics disabled")
    md.toggleLyrics(metadata, false)

    pressAnyKey()
end

---------------------------------------

local function readTest()
    md.initializeTag(metadata)
    metadataOriginal = md.unpackMetadata(md.packMetadata(metadata)) -- Crude way to Deep copy this table object
end

local function main(isStandalone)
    -- readTest()
    term.clear()

    exit = false
    if not readTape() then return end

    while true do

        -- os.execute("cls")
        term.clear()
        show_menu()


        io.write("> ")
        local choice = io.read()

        local action = menu_action[choice]

        if action then
            term.clear()
            action()
        else
            print("Invalid selection")
        end

        print()

        if exit then break end
    end
end

function M.runEditor()
    main(false)

    return true
end

return M