# C1 Project Generator

![C1 Project Generator](https://img.shields.io/badge/Platform-macOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

A macOS utility for Koray Birand Studio that simplifies the creation of standardized project folder structures with integrated database support for Phase One Capture One.

## Features

- **Streamlined Project Creation**: Quickly create standardized project structures with a consistent folder hierarchy
- **Automated Folder Generation**: Automatically creates numbered folders (01, 02, 03, etc.) in the Capture directory
- **Database Integration**: Integrates with Capture One by creating and populating a session database file
- **User-Friendly Interface**: Simple and intuitive SwiftUI interface for easy project setup
- **Window State Persistence**: Remembers the last position and size of the application window

## Project Structure

Each generated project includes:

- **Capture**: Contains numbered folders (01, 02, 03, etc.) for organizing capture sessions
- **Output**: For exported files and deliverables
- **Selects**: For selected/approved images
- **Trash**: For rejected images

Additionally, a `.cosessiondb` file is created and populated with the folder structure information for seamless integration with Capture One.

## Requirements

- macOS 11.0 or later
- Xcode 13.0 or later (for development)
- Swift 5.0 or later

## Installation

1. Download the latest release from the [Releases](https://github.com/koraybirand/C1-Assist/releases) page
2. Move the application to your Applications folder
3. Launch the application

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/koraybirand/C1-Assist.git
```

2. Open the project in Xcode:
```bash
cd C1-Assist
open "C1 Assist.xcodeproj"
```

3. Build and run the application in Xcode

## Usage

1. Enter a project name
2. Specify the number of folders to create in the Capture directory
3. Select a location for the project
4. Click "Generate" to create the project structure

## Technical Details

The application is built using:

- **SwiftUI**: For the user interface
- **SQLite**: For database operations
- **AppKit integration**: For window state persistence

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Koray Birand Studio

---

*Note: This tool is specifically designed for Koray Birand Studio's workflow with Capture One. It may require customization for other workflows.*
