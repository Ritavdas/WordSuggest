# WordSuggest

A macOS application that provides intelligent word suggestions and synonyms for selected text. Simply select text anywhere on your system and press `Cmd+Shift+W` to get smart word suggestions powered by AI or built-in dictionaries.

## Features

- **System-wide text selection monitoring**: Works across all applications
- **Intelligent word suggestions**: Provides synonyms, alternatives, and related words
- **LLM integration**: Connect to OpenAI GPT for advanced suggestions
- **Built-in fallback**: Works offline with extensive built-in synonym dictionary
- **Beautiful floating UI**: Clean, modern interface that appears near selected text
- **One-click copying**: Click any suggestion to copy it to clipboard
- **Hotkey activation**: Press `Cmd+Shift+W` to trigger suggestions for selected text
- **Menu bar integration**: Discrete menu bar icon for easy access and controls

## Requirements

- macOS 10.15 (Catalina) or later
- Xcode 12.0 or later (for building from source)
- Accessibility permissions (required for text monitoring)

## Installation

### Building from Source

1. Clone or download this repository
2. Open `WordSuggest.xcodeproj` in Xcode
3. Build and run the project (`Cmd+R`)

### First Launch Setup

1. When you first launch WordSuggest, it will request **Accessibility permissions**
2. Go to `System Preferences > Security & Privacy > Privacy > Accessibility`
3. Click the lock to make changes and add WordSuggest to the allowed applications
4. This permission is required for the app to monitor text selection across all applications

## Usage

### Basic Usage

1. **Select text** in any application (TextEdit, Safari, Mail, etc.)
2. **Press `Cmd+Shift+W`** while the text is selected
3. **View suggestions** in the floating window that appears
4. **Click any suggestion** to copy it to your clipboard
5. **Paste the suggestion** wherever you need it

### OpenAI Integration (Optional)

For enhanced suggestions powered by GPT:

1. Get an OpenAI API key from [https://platform.openai.com](https://platform.openai.com)
2. Open `WordSuggestionService.swift`
3. Replace the empty `openAIAPIKey` string with your API key:

   ```swift
   private let openAIAPIKey = "your-api-key-here"
   ```

4. Rebuild the application

Without an API key, the app will use its built-in synonym dictionary.

### Menu Bar Controls

- **Right-click** the "WS" menu bar icon for options
- **About WordSuggest**: View app information
- **Quit WordSuggest**: Close the application

## How It Works

1. **Text Monitoring**: Uses macOS Accessibility APIs to detect text selection
2. **Hotkey Detection**: Global hotkey handler for `Cmd+Shift+W`
3. **Text Extraction**: Attempts to get selected text via Accessibility APIs, with clipboard fallback
4. **Suggestion Generation**: Queries OpenAI API or uses built-in dictionary
5. **UI Display**: Shows suggestions in a floating window near the selection
6. **Clipboard Integration**: Copies selected suggestions for easy pasting

## Suggestion Types

- **Synonyms**: Words with similar meanings
- **Alternatives**: Different words that could work in context
- **Related**: Conceptually related words
- **Creative**: Unique alternatives generated by AI

## Privacy & Security

- WordSuggest only processes text when you explicitly trigger it with `Cmd+Shift+W`
- Selected text is only sent to OpenAI if you've configured an API key
- No persistent storage of user data
- Accessibility permissions are used solely for text selection detection

## Troubleshooting

### Suggestions not appearing

- Ensure Accessibility permissions are granted
- Try selecting text and pressing `Cmd+Shift+W` again
- Check that the text is actually selected (highlighted)

### No OpenAI suggestions

- Verify your API key is correctly set in `WordSuggestionService.swift`
- Check your internet connection
- Ensure you have OpenAI API credits available

### App not launching

- Check macOS version compatibility (10.15+)
- Try rebuilding the project in Xcode
- Check Console.app for error messages

## Development

### Project Structure

```
WordSuggest/
├── main.swift                    # App entry point
├── AppDelegate.swift            # Application lifecycle and coordination
├── TextMonitor.swift            # Text selection detection and hotkey handling
├── WordSuggestionService.swift  # LLM integration and built-in suggestions
├── SuggestionWindow.swift       # Floating UI for displaying suggestions
├── Info.plist                  # App metadata and permissions
└── WordSuggest.xcodeproj       # Xcode project file
```

### Key Technologies

- **Swift**: Primary programming language
- **Cocoa**: macOS native UI framework
- **Accessibility APIs**: For text selection monitoring
- **Carbon Event Manager**: For global hotkey handling
- **Core Graphics**: For window positioning
- **URLSession**: For OpenAI API integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on different applications
5. Submit a pull request

## License

This project is open source. Feel free to use, modify, and distribute as needed.

## Acknowledgments

- Built for macOS using native Cocoa frameworks
- Inspired by the need for better writing assistance tools
- Uses OpenAI's GPT models for intelligent suggestions
