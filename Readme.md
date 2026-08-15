# Browserino

![Browserino](images/browserino.png?v2)

Browserino is a tiny browser selector for MacOS written in SwiftUI. Just set as default browser, assign shortcuts, and now you can choose in which application you want to open the link.

Inspired by great [Browserosaurus](https://github.com/will-stone/browserosaurus), but a little bit faster and smaller thanks to native code, and fixes annoying Electron bug.

## Features

- **Default browser interceptor.** Set Browserino as the default handler for `http`/`https`. When anything opens a link, a picker appears next to the mouse so you can choose the app.
- **Keyboard shortcuts.** Assign a key per browser or app in Preferences. Press it in the picker to open immediately.
- **Private / incognito mode.** Hold Shift while clicking, or press Shift+Return, to open in a private window. Each browser can have its own private-mode argument (for example `--incognito`).
- **Move current tab.** Move the frontmost browser tab to another browser. See [Move current tab](#move-current-tab).
- **Auto-open rules.** Match the full URL with a case-insensitive regex and skip the picker, opening straight in the chosen app.
- **Host-matched apps.** Show extra apps in the picker for specific hosts (or for every URL). Optionally rewrite the URL scheme for Electron and similar apps.
- **Browser list.** Rescan installed browsers, reorder them, hide ones you do not want in the picker, and add extra search directories beyond `/Applications`.
- **Copy URL.** Copy the current link from the picker (`⌘⌥C`, or `⌘C` if you enable the alternative shortcut). Optionally close the picker after copying.
- **Menu bar extra.** Menu bar icon for Preferences and Quit. Can be hidden. Launch at login is optional.
- **Import / export.** Save and restore all settings as JSON. Reset restores defaults.

## Move current tab

Move a tab from one browser to another: Browserino reads the current tab URL, you pick a destination in the same picker, then the URL opens there. The original tab is closed only after that open succeeds (and only if **Close the original tab after opening the destination** is on, which is the default). Canceling the picker leaves the source tab open.

### How to trigger it

- **Menu bar:** **Move Current Tab…** (the menu bar extra must be enabled).
- **Global shortcut:** record one under **Preferences → General → Tab switching**. There is no default shortcut.

The shortcut captures the frontmost app at key-down, before Browserino comes forward. The menu item uses the last app you were in, then on-screen window order, so clicking the status item does not steal the source.

The source must be a browser in your configured **Browsers** list. If that front app is a listed browser that cannot expose tabs (for example Firefox), you get an error instead of silently using a browser behind it. Hidden browsers are not offered as destinations; the source browser is omitted from the list. Host-matched **Apps** are hidden in this picker. The caption shows `Moving from …`. Shift / Shift+Return still opens the destination in private mode.

If there is no other visible browser to move to, Browserino alerts instead of showing an empty picker.

### Supported browsers

The active tab of **window 1** is read and closed via Apple Events:

- Safari, Safari Technology Preview
- Chrome (stable, Beta, Dev, Canary)
- Brave (stable, Beta, Nightly)
- Microsoft Edge (stable, Beta, Dev, Canary)
- Opera, Opera GX, Vivaldi, Arc, Chromium

Firefox and other apps are not supported.

These tabs cannot be moved: empty URLs and start pages, browsers with no windows, and internal pages (`about:`, `chrome:`, `edge:`, `brave:`, `safari:`, `opera:`, `vivaldi:`, `chrome-extension:`, `edge-extension:`).

Cookies, history, and the rest of the session stay in the original browser. Only the URL is transferred.

### Permissions

macOS asks for Automation permission the first time Browserino controls each browser (**System Settings → Privacy & Security → Automation**). If access is denied, an alert offers to open those settings. That permission is required to read and close the source tab. Opening the destination still uses Launch Services, so the destination browser does not need Automation access.

# Installation

```bash
brew tap AlexStrNik/Browserino
brew install browserino --no-quarantine
```

Or download Browserino from the [releases page](https://github.com/AlexStrNik/Browserino/releases).

If you want to support the app, you can buy it on [Gumroad](https://alexstrnik.gumroad.com/l/browserino).
