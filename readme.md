# PortalInviter

**PortalInviter** is a World of Warcraft Classic Era addon that automates and streamlines portal-selling by listening for chat triggers, automatically inviting customers, and facilitating trade checks and portal casting. It also provides a handy GUI to manage invited players and offers quick actions like targeting or trading with them.

---

## Features

- **Automatic Invites**  
  - Listens for configurable trigger words (e.g., "portal") in whispers and selected channels (Trade, LocalDefense, World).  
  - Automatically invites the requesting player to your group if the trigger is matched.

- **Invited Players List**  
  - Maintains a list of recently invited players and their requested destinations in a convenient AceGUI-based frame.  
  - Easily opened via a minimap icon (right-click) or automatically when a new player joins your group.

- **Secure Action Buttons**  
  - **Target Player**: Quickly target the invited player.  
  - **Trade Player**: Initiate a trade attempt with them (if they’re in range).  
  - **Cast Portal**: Cast the appropriate portal spell or any configured spell via a secure macro.

- **Trade Gold Monitoring**  
  - Watches for trade window events, notifying you when the customer has provided enough gold for your portal fee.  
  - Tells you how much gold you actually earned after the trade finalizes.

- **Test Commands**  
  - `/testportal <message>` to simulate receiving a whisper for a portal.  
  - `/testaddinvite <playerName> <destination>` to manually add an entry to the invited list.  
  - `/testtrade start|money|close` to simulate trade events for debugging.

- **Configuration**  
  - **Enabled/Disabled** toggle.  
  - **Debug Mode** for additional output.  
  - **Custom Chat Triggers** to recognize portal requests.  
  - **Whisper Template** for automated responses.  
  - **Minimap Icon** show/hide option.

---

## Installation

1. **Download or clone** the **PortalInviter** repository.
2. Copy the `PortalInviter` folder into your WoW Classic Era `Interface/AddOns/` directory.
3. **Restart** or **launch** WoW Classic Era.
4. In the character select screen, ensure **PortalInviter** is enabled in the AddOn List.

---

## Usage

1. **Right-click the minimap icon** to open the invited players window.  
2. **Left-click the minimap icon** to toggle the addon on/off.  
3. **Listen for triggers** in whispers or channels; the addon automatically invites.  
4. **Use slash commands**:  
   - `/testportal`: Simulate receiving a "portal" whisper from "Testplayer."  
   - `/testaddinvite`: Add a player/destination manually to test the GUI.  
   - `/testtrade`: Simulate trade events for testing gold checks.

---

## Known Limitations

- **Cannot fully automate trades or spell casting** due to Blizzard’s security restrictions. The user must click secure action buttons or confirm trades manually.
- Zone detection uses `/who`, which may be throttled or unavailable for cross-realm players.

---

## Contributing

Feel free to submit pull requests or file issues for feature requests and bugs. If you’d like to contribute directly:

1. Fork the repository.
2. Make changes in a feature branch.
3. Submit a pull request describing your enhancements or fixes.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

**Enjoy your automated portal-selling with PortalInviter!**
