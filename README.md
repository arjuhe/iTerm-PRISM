# iTerm2 Color Manager

A command-line utility to manage, preview, and rotate through iTerm2 color presets with visual color samples.

## Features

- **List presets** - View all available color presets with a marker showing the current one
- **Set specific preset** - Change to a named color preset instantly
- **Rotate presets** - Cycle through presets (next, previous, random)
- **View current** - Show which preset is currently active
- **Color samples** - Visual preview of preset colors:
  - Automatic sample display when changing presets
  - Browse all 32 presets with `--sample` flag
- **Fast & responsive** - Real-time color changes using iTerm2 Python API

## Installation

### Prerequisites
- iTerm2 (macOS)
- Python 3.7+
- iTerm2 Python library

### Setup

1. Install the iTerm2 Python library:
```bash
pip3 install iterm2
```

2. Copy the script to your bin directory:
```bash
cp iterm2-color-manager ~/bin/
chmod +x ~/bin/iterm2-color-manager
```

Or add the project directory to your PATH:
```bash
export PATH="~/proj/iterm2-color-manager:$PATH"
```

## Usage

### Basic Commands

Show current color preset:
```bash
iterm2-color-manager --current
```

List all available presets (32 total):
```bash
iterm2-color-manager --list
```

Set a specific preset:
```bash
iterm2-color-manager --set Andromeda
# Output:
# Color preset changed to: Andromeda
# Color sample:           ■ ■ ■ ■ ■ ■ ■ ■
```

Rotate to next preset (alphabetical):
```bash
iterm2-color-manager --next
```

Rotate to previous preset:
```bash
iterm2-color-manager --previous
```

Apply a random preset:
```bash
iterm2-color-manager --random
```

Browse all presets with color samples:
```bash
iterm2-color-manager --sample
```

### Short Flags

All commands support short flags:
```bash
iterm2-color-manager -c       # --current
iterm2-color-manager -l       # --list
iterm2-color-manager -s PRESET # --set PRESET
iterm2-color-manager -n       # --next
iterm2-color-manager -p       # --previous
iterm2-color-manager -r       # --random
iterm2-color-manager -sa      # --sample
```

## Available Presets (32 total)

AlienBlood, Andromeda, Arthur, Batman, BirdsOfParadise, Breeze, Chalk, Dark Background, Django, ForestBlue, High Contrast, IC_Green_PPL, IC_Orange_PPL, Idea, Light Background, MonaLisa, OneHalfDark, Pastel (Dark Background), Pro, Regular, Relaxed, Shaman, SleepyHollow, Smoooooth, Solarized, Solarized Dark, Solarized Light, Spacedust, Tango Dark, Tango Light, UnderTheSea, Zenburn

## How It Works

### Color Sample Display

When you set a preset using `--set`, `--next`, `--previous`, or `--random`, a color sample is automatically displayed showing the first 8 ANSI colors (0-7) from the preset:

```
Color preset changed to: Batman
Color sample:           ■ ■ ■ ■ ■ ■ ■ ■
```

Each colored block represents one of the 8 basic terminal colors in the preset.

### Session Tracking

The script tracks the currently active preset per iTerm2 session using environment variables and temporary cache files (`~/.iterm2_color_preset_*`). This allows the `--list` command to show which preset is currently active with a green asterisk marker.

### Real-time Updates

Changes are applied instantly using the iTerm2 Python API. No restart required.

## Technical Details

- **Language:** Python 3
- **API:** iTerm2 Python library (async)
- **Color Format:** ANSI true color (24-bit RGB)
- **Display:** Unicode block characters (■) with ANSI escape codes
- **Preset Format:** iTerm2 `.itermcolors` (XML plist format)

## Project Structure

```
~/proj/iterm2-color-manager/
├── iterm2-color-manager     # Main script
├── README.md                # This file
└── CLAUDE.md               # Development notes
```

## Development

### Running from source

```bash
python3 ~/proj/iterm2-color-manager/iterm2-color-manager --help
```

### Adding to shell profile

For bash:
```bash
export PATH="~/proj/iterm2-color-manager:$PATH"
source ~/.bash_profile
```

For zsh:
```bash
export PATH="~/proj/iterm2-color-manager:$PATH"
source ~/.zshrc
```

Then you can use `iterm2-color-manager` from anywhere.

## Dependencies

- Python 3.7+
- iterm2 (Python library)
  - Requires: protobuf, websockets

Install all dependencies:
```bash
pip3 install iterm2 protobuf websockets
```

## Error Handling

- **iTerm2 not running:** "Error: Could not connect to iTerm2. Is iTerm2 running?"
- **Preset not found:** "Error: Color preset 'X' not found."
- **Missing library:** "Error: iterm2 Python library not found. Install it with: pip3 install iterm2"

## License

Personal utility script. Free to use and modify.

## Author

Created as a utility for iTerm2 color preset management on macOS.
