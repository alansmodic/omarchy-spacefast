# Spacefast bar widget for Omarchy

**An SF in your bar.** A bar button for [Spacefast](https://spacefast.com). Click it to see
your spaces, and publish something new in two clicks.

[![omarchy × spacefast: Tile it. Ship it.](https://raw.githubusercontent.com/alansmodic/omarchy-spacefast/main/docs/banner.png)](https://spacearchy.view.fast/)

**[See it live at spacearchy.view.fast →](https://spacearchy.view.fast/)** That page was
published with the same tool. The widget is one of three pieces: for the Omarchy menu entry
(Share → Web) and the agent skill ("put this online"), see
[omarchy-spacefast](https://github.com/alansmodic/omarchy-spacefast).

- **Left click:** the panel. It lists your recent publishes (and your account's spaces when
  signed in). From there you can:
  - open a space
  - copy a share link
  - claim an anonymous space before it expires (it turns red in its last 6 hours)
  - publish a folder, a file, or the clipboard
- **Right click:** publish a folder.
- **Middle click:** refresh.

It refreshes on its own when you publish from the Share menu or an agent.

## Keys in the panel

`j`/`k` or arrows to move · `enter` open · `c` copy link · `a` claim · `d` dashboard ·
`r` refresh · `esc` close.

Publishing and signing in are click-only on purpose: the panel takes keyboard focus when it
opens, and a stray keystroke should never publish anything.

## Install

```bash
omarchy plugin add https://github.com/alansmodic/omarchy-spacefast-plugin.git --enable
# or, from a checkout of this folder:
./install.sh
```

For signing in and listing your account's spaces, it uses the `sf` CLI when present, falling back
to `npx spacefast`. `./install.sh` installs `sf` through `omarchy-mise-install`. Without either,
the widget still publishes anonymously with curl and lists what you published from this machine.

## Settings

In the widget's entry in `~/.config/omarchy/shell.json`:

- `refreshIntervalSec` (default 300).
- `brandAccent` (default `true`): the lime offset on the SF mark. Set it to `false` for a
  plain monochrome icon.

The bar icon is Spacefast's "SF" mark, drawn natively (`SpacefastIcon.qml`) from the paths in
the dashboard favicon, so it stays crisp at bar size and follows your theme's icon color.

## IPC

```bash
omarchy-shell shell toggle spacefast.spaces '{}'
omarchy-shell spacefast.spaces refresh
omarchy-shell spacefast.spaces publishFolder    # also publishFile, publishClipboard
```

All Spacefast work goes through the bundled `bin/omarchy-spacefast`, so the QML never handles
credentials.
