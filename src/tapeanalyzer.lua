local component = require("component")

local M = {}

local tape = component.tape_drive
local bitrate = 32768


function M.analyzeTape()
    local tapeSize = tape.getSize()
    local maxduration = (tapeSize / (bitrate / 8)) - 2 -- Decrement 2 because metadata uses 2 second of data (8192 bytes)

    local firstZeroIndex = 0
    local zeroesLength = 0

    tape.seek(-math.huge)

    for i=1, maxduration do

        local byte = tape.read()

        if byte == 0 then
            if zeroesLength == 0 then
                firstZeroIndex = i
            end
            zeroesLength = zeroesLength + 1
        else
            zeroesLength = 0
        end

        -- io.write(i," | ",tape.getPosition() - 1," | ",byte,"\n")
        io.write(string.format("\rProgress: %d/%d", i, maxduration))
        io.flush()
        tape.seek(4095)
    end

    if (firstZeroIndex  <= 0) then
        io.write("\nSeems like the song is either fit or longer than the tape size\n")

        return tapeSize - 8192
    else
        io.write("\nLongest sequence of zeroes starts at ", firstZeroIndex, " and is ", zeroesLength, " bytes long.\n")
        local stopbit = (firstZeroIndex + 2) * 4096

        if stopbit > tapeSize - 8192 then
            stopbit = tapeSize - 8192
        end

        io.write("Saved stop bit for tape: ", stopbit, "\n")

        return stopbit
    end
end

return M