# Profile Manager CLI

A command-line interface application written in Zig that manages profiles with names and passwords, storing them in JSON format.

## Features

- Add new profiles with name and password
- Remove existing profiles
- List all stored profiles
- Get specific profile details
- JSON-based storage for persistence
- Memory-safe implementation using Zig's allocator

## Prerequisites

- Zig 0.14.0 or later
- Windows operating system
- Visual Studio Code (optional, for development)

## Building

```powershell
# Build with debug information
zig build -Doptimize=Debug

# Build for release
zig build -Doptimize=ReleaseSafe
```

The executable will be created in `zig-out/bin/profiles.exe`

## Usage

```powershell
# Add a new profile
profiles.exe add <name> <password>

# Remove a profile
profiles.exe remove <name>

# List all profiles
profiles.exe list

# Get specific profile
profiles.exe get <name>
```

## Project Structure

```
.
├── src/
│   ├── main.zig       # Entry point and CLI handling
│   ├── profile.zig    # Profile management logic
│   └── operation.zig  # Operation type definitions
├── build.zig         # Build configuration
└── README.md
```

## Development

The project uses VS Code for development. Required extensions:
- Zig Language Server
- C/C++ Extension (for debugging)

Debug configuration is provided in `.vscode/` directory.

## License

MIT License - See LICENSE file for details
