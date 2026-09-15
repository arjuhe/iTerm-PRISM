# iTerm-PRISM

**P**reset **R**endering **I**term **S**ession **M**anager — A command-line utility to manage, preview, and rotate through iTerm2 color presets with visual color samples.

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

### One-Liner Installation (End Users)

Once published to GitHub, install with a single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/USER/iTerm-PRISM/main/install.sh)"
```

This will automatically:
- Check prerequisites (Python 3.7+, macOS, iTerm2)
- Download the iTerm-PRISM script
- Install the `iterm2` Python package
- Copy `prism` to `~/.local/bin/`
- Configure your PATH

After installation, reload your shell:
```bash
source ~/.bash_profile  # or ~/.zshrc
prism --help
```

### Local Installation (Developers)

Clone and install from source:

```bash
cd ~/proj/arjuhe/iTerm-PRISM
./install.sh
```

This uses the local `prism` script in your repository instead of downloading.

### Manual Installation

If you prefer to set up manually:

1. Install the iTerm2 Python library:
```bash
pip3 install --user iterm2
```

2. Copy the script to your bin directory:
```bash
mkdir -p ~/.local/bin
cp prism ~/.local/bin/
chmod +x ~/.local/bin/prism
```

3. Add to PATH (if not already configured):
```bash
echo 'export PATH="${HOME}/.local/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

### Uninstall

To remove iTerm-PRISM:

```bash
~/.local/bin/uninstall.sh
```

Or if you have the source repository:

```bash
./uninstall.sh
```

### Troubleshooting

**"command not found: prism"**

Ensure `~/.local/bin` is in your PATH:

```bash
echo $PATH | grep ".local/bin"
```

If missing, add to your shell profile and reload:

```bash
echo 'export PATH="${HOME}/.local/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

**"iterm2 Python library not found"**

Install manually:

```bash
pip3 install --user iterm2
```

## Usage

### Basic Commands

Show current color preset:
```bash
prism --current
```

List all available presets (32 total):
```bash
prism --list
```

Set a specific preset:
```bash
prism --set Andromeda
# Output:
# Color preset changed to: Andromeda
# Color sample:           ■ ■ ■ ■ ■ ■ ■ ■
```

Rotate to next preset (alphabetical):
```bash
prism --next
```

Rotate to previous preset:
```bash
prism --previous
```

Apply a random preset:
```bash
prism --random
```

Browse all presets with color samples:
```bash
prism --sample
```

Show version and build info:
```bash
prism --version
```

### Short Flags

All commands support short flags:
```bash
prism -c       # --current
prism -l       # --list
prism -s PRESET # --set PRESET
prism -n       # --next
prism -p       # --previous
prism -r       # --random
prism -sa      # --sample
prism -v       # --version
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
~/proj/arjuhe/iTerm-PRISM/
├── prism                    # Main script
├── install.sh               # Installation script (local & remote)
├── uninstall.sh             # Uninstallation script
├── README.md                # This file
└── CLAUDE.md               # Development notes
```

## Development

### Running from source

```bash
python3 ~/proj/arjuhe/iTerm-PRISM/prism --help
```

### Testing the installer

For development/testing:

```bash
# Clean install
rm ~/.local/bin/prism
./install.sh

# Test idempotency (run again)
./install.sh
```

### Adding to shell profile

For bash:
```bash
export PATH="~/proj/arjuhe/iTerm-PRISM:$PATH"
source ~/.bash_profile
```

For zsh:
```bash
export PATH="~/proj/arjuhe/iTerm-PRISM:$PATH"
source ~/.zshrc
```

Then you can use `prism` from anywhere.

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
