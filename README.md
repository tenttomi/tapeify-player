
# Tapeify Player
A simple tape player for OpenComputers that supports playback control, metadata management, and even lyrics display. Optionally, it can also show simple Ascii art as cover.


## Features

- Playback from tape drives (supports even GPU tier 1 with 50x16 resolution)
- Progress bar and playback controls
- Metadata editing (title, artist, album, year, track number, genre, comment)
- ASCII art display (requires GPU tier 3, 160x50 screen resolution)
- Lyrics display

### Key controls

```
[SPACE] Pause   [←/→] Seek   [R] Restart   [L] Loop   [M] Metadata   [E] Edit   [Q] Exit
```



## Requirement

- OpenComputers
- Tape Drive
- GPU: Tier 1 or higher for normal playback, Tier 3 recommended for ASCII art display
- Internet Card for installation
## Metadata requirements

- Encoding: All data assumes ASCII encoding. UTF-8 or other encodings may break playback.

- Metadata storage: All metadata is stored on the tape itself in a custom TPFY format.

- ASCII art: Must be 80x44. Put it into a text file and specify the path in the metadata editor.

- Lyrics: Can be obtained from lrclib.net. Copy the lyrics into a text file and specify the path in the metadata editor.
## Installation

You can use wget to directly download the installer.

```bash
wget https://raw.githubusercontent.com/tenttomi/tapeify-player/main/installer.lua installer.lua
```

Then just run the installer.lua
```bash
installer.lua
```
    
## Usage

Run the main program

```Bash
tapeify
```

If you want to directly open the editor instead (incase of tape corruption), you can use editor argument

```Bash
tapeify editor
```

On the Metadata Editor, run Analyze Tape to find the duration of the audio. Don't forget to save the metadata before exiting the editor


## Limitations & Known Issues

- Due to a limitation, the tape player may not detect a tape change if it happens instantly (e.g., holding a tape in inventory and swapping it with the one in tape driver slot). The tape drive needs to be empty for a fraction of a second to properly detect tape change.

- Again, All data assumes ASCII encoding. UTF-8 or other encodings may break playback.

- Expect bugs lmao.

## Motivation

Audio length aries, but tapes come in fixed sizes, like 4, 8, 16, 32, 64 minutes. This means that when you want to make the tape loops by making a simple script that loops when it ends, the tape driver won't know when the actual audio actually ends. It will only ends following the tape size.

Since tape is just a storage that stores bytes data, we can embed any data to the tape itself. at first I just want to embed the duration so that a player can read the data to know when it should loop. But then I thought, I might as well just embed more data, like title, artist, etc, just for fun, so it became just like mp3.

The metadata format itself is heavily inspired by ID3v1, an older metadata format for early mp3 days. While it was quickly suceeded by ID3v2 which is a more modular format, ID3v1 is very simple to understand and implement.
