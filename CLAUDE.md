# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**iTerm-PRISM** (**P**reset **R**endering **I**term **S**ession **M**anager) is a Python CLI utility for managing iTerm2 color presets. It provides commands to list, set, rotate through, and preview color schemes with visual color sample displays.

## Repository Structure

```
~/proj/arjuhe/iTerm-PRISM/
├── prism                           # Main Python script (~500 lines)
├── install.sh                      # Installation script (dual-mode: local & remote)
├── uninstall.sh                    # Uninstallation script
├── README.md                       # User documentation
├── CLAUDE.md                       # This file (developer guidance)
├── test/
│   └── presets/
│       └── TestPreset.itermcolors # Test color preset for development
├── .claude/                        # Private developer notes (git-ignored)
│   ├── plans/                      # Implementation plans and design docs
│   ├── decisions/                  # Architectural decisions
│   ├── bugs/                       # Bug tracking with RCA documentation
│   ├── skills/                     # Custom testing skills
│   ├── agents/                     # Custom agent definitions
│   └── settings.local.json
└── .git/                          # Git repository
```

## Script Architecture

The script is a single-file Python 3 application using the iTerm2 Python API.

### Key Components

**Core Functions:**
- `get_current_session()` - Get the active iTerm2 session
- `list_all_presets()` - Fetch all available presets from iTerm2
- `set_color_preset()` - Apply a preset to the current session
- `get_preset_colors()` - Extract RGB color values from a preset
- `get_next_preset()` - Rotate to next/previous/random preset

**Display Functions:**
- `hex_to_rgb()` - Convert hex colors to RGB tuples
- `create_color_block()` - Format colored block characters using ANSI codes
- `format_color_grid()` - Create a grid of color blocks
- `display_all_samples()` - Show all presets with color samples

**Session Tracking:**
- `get_session_id()` - Get iTerm2 session ID from environment
- `get_cached_preset()` - Retrieve cached current preset for a session
- `cache_preset()` - Store current preset in a temp file

**Main Entry:**
- `main_async()` - Async main function handling all commands
- `main()` - Argument parsing and execution

### Command Implementation

| Command | Function | Feature |
|---------|----------|---------|
| `--current` | Shows cached preset | Session tracking |
| `--list` | Lists all with marker | Green asterisk for current |
| `--set PRESET` | Applies preset | Color sample display |
| `--next` | Rotates forward | Color sample display |
| `--previous` | Rotates backward | Color sample display |
| `--random` | Picks random | Color sample display |
| `--sample` | Shows all with samples | Displays all 32 presets |

## Installation System

iTerm-PRISM includes a Homebrew-style installation system with dual-mode support:

**Local mode** (developers):
```bash
cd ~/proj/arjuhe/iTerm-PRISM && ./install.sh
```
Uses the local `prism` script from the repository.

**Remote mode** (end users, when published):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/USER/iTerm-PRISM/main/install.sh)"
```
Automatically downloads the `prism` script and installs it.

The installer handles:
- Prerequisite validation (Python 3.7+, macOS, iTerm2)
- Dependency installation (iterm2 package)
- Binary placement (~/.local/bin/prism)
- PATH configuration with user confirmation
- Installation verification

To uninstall:
```bash
./uninstall.sh  # or ~/.local/bin/uninstall.sh if installed remotely
```

## Common Development Tasks

### Testing a Command

```bash
python3 ~/proj/arjuhe/iTerm-PRISM/prism --help
python3 ~/proj/arjuhe/iTerm-PRISM/prism --list
python3 ~/proj/arjuhe/iTerm-PRISM/prism --set Andromeda
```

### Testing the Installer

```bash
# Clean install (local mode)
rm ~/.local/bin/prism
./install.sh

# Test idempotency
./install.sh  # Should skip already-installed components
```

### Adding a New Command

1. Create the async handler function (e.g., `async def my_feature()`)
2. Add argument to parser in `main()` function
3. Add conditional check in `main_async()` to call handler
4. Update help text epilog with example

### Color Display Format

Colors are displayed using ANSI true color (24-bit RGB):
```python
# Format: \033[38;2;{r};{g};{b}m{character}\033[0m
f"\033[38;2;{r};{g};{b}m■\033[0m"
```

The block character (■) represents one color. Multiple blocks in a grid show all 8 basic ANSI colors (0-7).

## Dependencies

- Python 3.7+
- `iterm2` library (async iTerm2 Python API)
  - Handles all iTerm2 connection and preset management
  - Provides ColorPreset class with `values` list of Color objects
  - Each Color has: key, red, green, blue, alpha properties

Install:
```bash
pip3 install iterm2
```

## Important Files & Locations

| File | Purpose |
|------|---------|
| `prism` | Main script entry point |
| `README.md` | User-facing documentation |
| `CLAUDE.md` | Development notes (this file) |
| `~/.prism_preset_{SESSION_ID}` | Runtime session cache (created by script) |

## Environment Variables Used

- `ITERM_SESSION_ID` - Set by iTerm2, identifies the current session
- Accessed via `os.environ.get('ITERM_SESSION_ID', 'unknown')`

## Git Configuration

If this becomes a git repository, consider:

```bash
git init
git add iterm2-color-manager README.md CLAUDE.md
git commit -m "Initial commit: iTerm2 color preset manager"
git remote add origin <github-url>
```

## Testing Checklist

Before committing changes:

```bash
# Test help
python3 prism --help

# Test basic commands
python3 prism --current
python3 prism --list
python3 prism --sample

# Test color changes
python3 prism --set Batman
python3 prism --next
python3 prism --random

# Test error handling
python3 prism --set NonExistentPreset

# Verify marker updates
python3 prism --list | grep '\*'
```

## Code Style & Conventions

- **Functions:** Async functions use `async def`, sync use `def`
- **Docstrings:** One-line docstrings for all functions
- **Type hints:** Used for function parameters and returns
- **Error handling:** Try-except blocks with graceful fallbacks
- **Output:** Use `print()` for normal output, `print(..., file=sys.stderr)` for errors
- **Color codes:** ANSI codes defined as module-level constants (GREEN, RESET)

## Plans and Decisions

All project documentation is stored in `.claude/` (git-ignored):

- **Plans** (`.claude/plans/`) - Implementation plans for completed and planned features
  - Context and motivation
  - Step-by-step implementation approach
  - Files to modify with specific locations
  - Verification steps for testing

- **Decisions** (`.claude/decisions/`) - Architectural and design decisions
  - The choice made and why
  - Rationale and implications
  - Alternatives that were considered
  - Related decisions and references

- **Bugs** (`.claude/bugs/`) - Bug reports with Root Cause Analysis (RCA)
  - See `.claude/bugs/README.md` for bug tracking system documentation
  - Each bug is documented with symptoms, root cause, and fix status
  - Use the template in `README.md` when adding new bugs

- **Skills** (`.claude/skills/`) - Custom testing and automation scripts

- **Agents** (`.claude/agents/`) - Specialized agent definitions for development tasks

These files are not committed to git, keeping development notes private and the repository lightweight.

## Future Enhancements

Possible improvements:
- Config file for favorite presets
- Custom color scheme creation
- Theme export/import
- Shell completion (bash/zsh)
- Watch mode to sync across sessions
- Integration with shell prompts

## Related Projects

The original script was created in `~/proj/home/sbin/iterm2-color-manager` and has been moved to this standalone project directory as **iTerm-PRISM** for better isolation and reusability.

**Reference scripts in ~/proj/home:**
- `sbin/iterm2_random_tabs` - Similar iTerm2 API usage patterns
- `sbin/color-display-*` - ANSI color display techniques
- `sbin/pass-sync` - CLI argument handling patterns
