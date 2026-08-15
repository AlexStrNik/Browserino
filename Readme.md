# Browserino

![Browserino](images/browserino.png?v2)

Browserino is a tiny browser selector for MacOS written in SwiftUI. Just set as default browser, assign shortcuts, and now you can choose in which application you want to open the link.

Inspired by great [Browserosaurus](https://github.com/will-stone/browserosaurus), but a little bit faster and smaller thanks to native code, and fixes annoying Electron bug.

## Features

- **Default browser interceptor.** Set Browserino as the default handler for `http`/`https`. When anything opens a link, a picker appears next to the mouse so you can choose the app.
- **Keyboard shortcuts.** Assign a key per browser or app in Preferences. Press it in the picker to open immediately.
- **Private / incognito mode.** Hold Shift while clicking, or press Shift+Return, to open in a private window. Each browser can have its own private-mode argument (for example `--incognito`).
- **Auto-open rules.** Match the full URL with a case-insensitive regex and skip the picker, opening straight in the chosen app.
- **Host-matched apps.** Show extra apps in the picker for specific hosts (or for every URL). Optionally rewrite the URL scheme for Electron and similar apps.
- **Browser list.** Rescan installed browsers, reorder them, hide ones you do not want in the picker, and add extra search directories beyond `/Applications`.
- **Copy URL.** Copy the current link from the picker (`⌘⌥C`, or `⌘C` if you enable the alternative shortcut). Optionally close the picker after copying.
- **Menu bar extra.** Menu bar icon for Preferences and Quit. Can be hidden. Launch at login is optional.
- **Import / export.** Save and restore all settings as JSON. Reset restores defaults.

# Installation

```bash
brew tap AlexStrNik/Browserino
brew install browserino --no-quarantine
```

Or download Browserino from the [releases page](https://github.com/AlexStrNik/Browserino/releases).

If you want to support the app, you can buy it on [Gumroad](https://alexstrnik.gumroad.com/l/browserino).
