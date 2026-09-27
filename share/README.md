# Share → Web (Omarchy menu)

Adds a **Web** submenu to Omarchy menu → Trigger → Share, next to LocalSend:

| Entry | Does |
|---|---|
| File | Pick files; publish them and copy a link (an HTML file becomes the page) |
| Folder | Pick a folder or built site; publish it and copy a link |
| Clipboard | Publish the clipboard: an image, HTML, or text |
| My Spaces | Open the Spacefast bar panel, or the dashboard if the widget is not installed |
| Sign in | Sign in with WordPress.com, so publishes are kept and you get share links |

```bash
./install.sh              # adds the menu entries and ~/.local/bin/omarchy-spacefast
./install.sh --uninstall  # removes exactly what it added
./install.sh --no-cli     # skip installing the sf CLI; publishing falls back to curl
```

The entries go into `~/.config/omarchy/extensions/omarchy-menu.jsonc` between
`>>> omarchy-spacefast` and `<<< omarchy-spacefast` markers. Nothing else in that file is
touched.

Not signed in? You still get a private preview link right away. Claim the space within about
33 hours (click the notification) to keep it and share it.
