-- TPFY Metadata Tag
-- Version [1.1]

-- Metadata Format:
-- 8192 Bytes at the end of the tape
-- Small note: lua index start at 1, but we'll use 0-based indexing for clarity in comments
-- [1] 0..3 == 'TPFY' Tag (4 Bytes)
-- [2] 4..7 == Checksum Code (4 Bytes)
-- [3] 8..9 == Version (2 Bytes)
-- [4] 10 == Encoder Used (1 Byte)
-- [5] 11 == Encoding Flags (1 Byte)
-- [6] 12..19 == Unique ID (8 Bytes)
-- [7] 20..23 == Duration (4 Bytes) -- in bit
-- [8] 24 == Feature Flags (1 Bytes) -- 0x01: Ascii art, 0x02: Lyrics
-- [9] 25..31 == Unused (Future reserved) (7 Bytes)

-- [10] 32..95 == Title (64 Bytes)
-- [11] 96..159 == Artist (64 Bytes)
-- [12] 160..223 == Album (64 Bytes)
-- [13] 224..227 == Year (4 Bytes)
-- [14] 228..229 == Track Number (2 Bytes)
-- [15] 230..231 == GenreId (2 Bytes)
-- [16] 232..255 == Genre (24 Bytes)
-- [17] 256..575 == Comment (and future reserved) (320 Bytes)

-- Features:
-- | Ascii art |
-- 80x44 == 3520bytes

-- [18] 576..4095 == Ascii art block (3520 Bytes)

-- | Lyrics |
-- lyric count == 2 Bytes
-- encoding ==	1 Bytes
-- reserved ==	1 Bytes
-- lyric entries == remaining bytes (4092 Bytes)

-- [19] 4096..8191 == Lyrics block (4096 Bytes)

-- CONFIG SECTION START ------

local version = {1, 1} -- Major, Minor

-- CONFIG SECTION ENDS -------

local M = {}

local utils = require("utils")
local crc32 = require("crc32lua")

local function generateChecksum(t)
    if t == nil then
        return 0 
    end
    local bytesString = table.concat(t, "", 9) -- Exclude the first 8 bytes (Tag + Checksum)
    local checksum = crc32.crc32_string(bytesString)
    checksum = checksum % 2^32
    return checksum
end

-- READ SECTION START ------

function M.readChecksum(t)
    local str = string.unpack(">L", t[2])
    return str
end

function M.readVersion(t)
    return string.byte(t[3],1) .. "." .. string.byte(t[3],2)
end

function M.readEncoderUsed(t)
    return string.byte(t[4])
end

function M.readEncoderFlags(t)
    return string.byte(t[5])
end

function M.readUniqueID(t)
    return utils.uuid32toHex(t[6])
end

function M.readDuration(t)
    local str = string.unpack(">L", t[7])
    return str
end

function M.readFeatureFlags(t)
    local str = string.byte(t[8])
    return str
end

function M.readFutureReserved(t)
    local str = string.unpack(">I7", t[9])
    return str
end

function M.readTitle(t)
    return t[10]
end

function M.readArtist(t)
    return t[11]
end

function M.readAlbum(t)
    return t[12]
end

function M.readYear(t)
    local str = string.unpack(">L", t[13])
    return str
end

function M.readTrackNumber(t)
    local str = string.unpack(">H", t[14])
    return str
end

function M.readGenreId(t)
    local str = string.unpack(">H", t[15])
    return str
end

function M.readGenre(t)
    return t[16]
end

function M.readComment(t)
    return t[17]
end

function M.readAsciiArt(t)
    return t[18]
end

function M.readLyrics(t)
    return t[19]
end

-- READ SECTION ENDS -------

-- WRITE SECTION START ------

local function writeTag(t)
    t[1] = "TPFY"
end

local function writeChecksum(t)
    t[2] = string.pack(">I4", generateChecksum(t))
end

local function writeVersion(t)
    t[3] = string.char(table.unpack(version))
    writeChecksum(t)
end

function M.writeEncoderUsed(t, encoderUsed)
    t[4] = string.char(encoderUsed)
    writeChecksum(t)
end

function M.writeEncoderFlags(t, encoderFlags)
    t[5] = string.char(encoderFlags)
    writeChecksum(t)
end

local function writeUniqueID(t)
    t[6] = utils.uuid32()
    writeChecksum(t)
end

function M.writeDuration(t, duration)
    t[7] = string.pack(">L", duration)
    writeChecksum(t)
end

function M.writeFeatureFlags(t, featureFlags)
    t[8] = string.char(featureFlags)
    writeChecksum(t)
end

function M.writeFutureReserved(t, futureReserved)
    t[9] = string.pack(">I7", futureReserved)
    writeChecksum(t)
end

function M.writeTitle(t, title)
    t[10] = utils.fitString(title, 64)
    writeChecksum(t)
end

function M.writeArtist(t, artist)
    t[11] = utils.fitString(artist, 64)
    writeChecksum(t)
end

function M.writeAlbum(t, album)
    t[12] = utils.fitString(album, 64)
    writeChecksum(t)
end

function M.writeYear(t, year)
    t[13] = string.pack(">L", year)
    writeChecksum(t)
end

function M.writeTrackNumber(t, trackNumber)
    t[14] = string.pack(">H", trackNumber)
    writeChecksum(t)
end

function M.writeGenreId(t, genreId)
    t[15] = string.pack(">H", genreId)
    writeChecksum(t)
end

function M.writeGenre(t, genre)
    t[16] = utils.fitString(genre, 24)
    writeChecksum(t)
end

function M.writeComment(t, comment)
    t[17] = utils.fitString(comment, 320)
    writeChecksum(t)
end

function M.writeAsciiArt(t, asciiArt)
    t[18] = utils.fitString(asciiArt, 3520)
    writeChecksum(t)
end

function M.writeLyrics(t, lyrics)
    t[19] = utils.fitString(lyrics, 4096)
    writeChecksum(t)
end

-- WRITE SECTION ENDS -------

-- FEATURES SECTION ---------- (NEEDS FIX)

function M.hasAsciiArt(t)
    return utils.has_flag(M.readFeatureFlags(t), 0x01)
end

function M.hasLyrics(t)
    return utils.has_flag(M.readFeatureFlags(t), 0x02)
end

function M.toggleAsciiArt(t, bool)
    if bool then
        M.writeFeatureFlags(t, utils.set_flag(M.readFeatureFlags(t), 0x01))
    else
        M.writeFeatureFlags(t, utils.clear_flag(M.readFeatureFlags(t), 0x01))
    end
end

function M.toggleLyrics(t, bool)
    if bool then
        M.writeFeatureFlags(t, utils.set_flag(M.readFeatureFlags(t), 0x02))
    else
        M.writeFeatureFlags(t, utils.clear_flag(M.readFeatureFlags(t), 0x02))
    end
end

-- FEATURES SECTION ENDS ------------

function M.initializeTag(t)

    M.writeEncoderUsed(t, 1) -- Tapeify
    M.writeEncoderFlags(t, 0)
    M.writeDuration(t, 974848) -- 3:58 in bytes at 32768 bitrate
    M.writeFeatureFlags(t, 0)
    M.writeFutureReserved(t, 0)

    M.writeTitle(t, "")
    M.writeArtist(t, "")
    M.writeAlbum(t, "")
    M.writeYear(t, 2026)
    M.writeTrackNumber(t, 1)
    M.writeGenreId(t, 0)
    M.writeGenre(t, "")
    M.writeComment(t, "")

    writeTag(t)
    writeVersion(t)
    writeUniqueID(t)

    writeChecksum(t)
end

function M.packMetadata(t)
    return table.concat(t)
end

function M.unpackMetadata(bytes)
    local t = {}

    t[1] = bytes:sub(1, 4) -- Tag
    t[2] = bytes:sub(5, 8) -- Checksum
    t[3] = bytes:sub(9, 10) --  Version
    t[4] = bytes:sub(11, 11) -- Encoder Used
    t[5] = bytes:sub(12, 12) -- Encoder Flags
    t[6] = bytes:sub(13, 20) -- Unique ID
    t[7] = bytes:sub(21, 24) -- Duration
    t[8] = bytes:sub(25, 25) -- Feature Flags
    t[9] = bytes:sub(26, 32) -- Future Reserved
    t[10] = bytes:sub(33, 96) -- Title
    t[11] = bytes:sub(97, 160) -- Artist
    t[12] = bytes:sub(161, 224) -- Album
    t[13] = bytes:sub(225, 228) -- Year
    t[14] = bytes:sub(229, 230) -- Track Number
    t[15] = bytes:sub(231, 232) -- GenreId
    t[16] = bytes:sub(233, 256) -- Genre
    t[17] = bytes:sub(257, 576) -- Comment
    t[18] = bytes:sub(577, 4096) -- Ascii art
    t[19] = bytes:sub(4097, 8192) -- Lyrics

    return t
end

function M.tagExist(bytes)
    if (bytes:sub(1,4)) == "TPFY" then
        return true
    else
        return false
    end
end

return M