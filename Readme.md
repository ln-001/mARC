# mARC

A native macOS IRC client built with Swift and SwiftUI, inspired by the classic mIRC for Windows.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Native macOS app** — Built with SwiftUI for a modern, native experience
- **SSL/TLS support** — Secure connections on port 6697
- **Multiple channels** — Join and manage multiple channels simultaneously
- **Private messaging** — Double-click a user to open a DM
- **User list** — See who's in each channel with op (@) and voice (+) status
- **Topic display** — Channel topics shown at the top
- **Unread indicators** — Badge shows unread message count per channel
- **Nick and mode tracking** — Real-time updates when users change nicks or get op/voice

## Screenshots
<img width="2102" height="1197" alt="Scherm­afbeelding 2025-12-29 om 19 37 08" src="https://github.com/user-attachments/assets/ade73ebf-da25-49af-ba33-61bbedf9c38d" />
<img width="2102" height="1197" alt="Scherm­afbeelding 2025-12-29 om 19 36 51" src="https://github.com/user-attachments/assets/2ca24a99-aaf4-42a1-9bee-d7e87c777afa" />

## Installation

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mARC.git
   cd mARC
   ```

2. Open the project in Xcode:
   ```bash
   open mARC.xcodeproj
   ```

3. Build and run (⌘R)

## Usage

### Connecting

1. Enter the server hostname (e.g., `irc.libera.chat`)
2. Enter the port (`6667` for plain, `6697` for SSL)
3. Toggle SSL if using a secure connection
4. Enter your desired nickname
5. Click **Connect**

### Commands

| Command | Description |
|---------|-------------|
| `/join #channel` | Join a channel |
| `/j #channel` | Join a channel (shortcut) |
| `/part` | Leave current channel |
| `/part #channel` | Leave specified channel |
| `/quit [message]` | Disconnect from server |
| `/msg nick message` | Send private message |
| `/me action` | Send action message |
| `/nick newnick` | Change your nickname |
| `/topic` | View channel topic |
| `/topic new topic` | Set channel topic (requires op) |
| `/mode +o nick` | Give op status (requires op) |
| `/mode +v nick` | Give voice status (requires op) |
| `/kick nick [reason]` | Kick user from channel (requires op) |
| `/raw command` | Send raw IRC command |

### Keyboard Shortcuts

- **Enter** — Send message
- **Click channel** — Switch to channel
- **Double-click user** — Open private message

## Project Structure

```
mARC/
├── mARCApp.swift        # App entry point
├── ContentView.swift    # Main UI
├── IRCClient.swift      # IRC protocol & networking
├── IRCMessage.swift     # Message model & parser
├── Channel.swift        # Channel model
├── MessageView.swift    # Message display component
└── UserListView.swift   # User list component
```

## IRC Networks

Some popular networks to try:

| Network | Server | SSL Port |
|---------|--------|----------|
| Libera.Chat | irc.libera.chat | 6697 |
| OFTC | irc.oftc.net | 6697 |
| EFNet | irc.efnet.org | 6697 |
| IRCnet | open.ircnet.net | 6697 |

## Roadmap

- [ ] Nick highlighting/mentions
- [ ] Auto-reconnect

## Privacy Note

By default, IRC servers expose your IP address or hostname to other users. To protect your privacy:

1. **Use a VPN** — Easiest solution
2. **Register your nick** — Some networks (like Libera.Chat) provide hostname cloaking for registered users
3. **Use SASL** — Authenticate before joining channels (coming soon)

## Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [mIRC](https://www.mirc.com/), the classic Windows IRC client
- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) and Apple's [Network framework](https://developer.apple.com/documentation/network)
