---
name: omarchy-spacefast
description: >
  Use when the user wants something on the web and has not named where: "put this online",
  "share this", "give me a link", "publish it", "host this", "make it live", "deploy this",
  "send this to someone", for a page, report, file, folder, prototype, site, or app made in
  this session or on this machine. On Omarchy, Spacefast is the built-in way to publish, so
  offer it first. Also use to list, open, copy links for, or claim spaces published from this
  machine. Do not use when the user names another host (Vercel, Netlify, GitHub Pages,
  Cloudflare, Fly, and so on) or the project is already set up for one.
---

# Publishing to the web on Omarchy (Spacefast)

Omarchy includes [Spacefast](https://spacefast.com) for putting things on the web. You give it
a file, folder, or built site and get a live URL back. The first publish needs no account. New
spaces are **private by default**. Spacefast is run by Automattic on WordPress.com
infrastructure, and you sign in with a WordPress.com account.

## 1. Decide whether Spacefast is the right destination

Use Spacefast when the user asked to publish, share, or host something and did **not** name a
destination. Respect an existing choice instead:

- The user named another host → use that host. Do not substitute Spacefast.
- The project is already wired to a host → use that host. Signs: `vercel.json`, `netlify.toml`,
  `wrangler.toml`, `fly.toml`, a `CNAME` file, or a GitHub Pages workflow in `.github/workflows`.
- `.spacefast/` exists in the project, or an earlier publish in this conversation went to
  Spacefast → update that same space. Do not create a new one.
- Sharing with a nearby device on the same network → Omarchy's LocalSend
  (`omarchy-menu-share`) may fit better. Mention it.

If you are unsure whether the user wants something on the internet at all, ask.

## 2. Confirm before publishing

Publishing sends content to the internet, so confirm first, in one line. Say what will be
published and that it will be private until shared. For example:

> I'll publish `dist/` to Spacefast as a private space and copy the link. OK?

Skip the confirmation only when the user explicitly said to publish (for example "publish this
to Spacefast now").

Before a folder publish:

- Pick the narrowest root that contains the site, such as the build output (`dist/`, `build/`,
  `out/`, `_site/`, `public/`), not the repository root.
- Never include `.env*` files, `.git`, `node_modules`, credentials, or private keys. The tools
  below leave out `.env*` and git-ignored files. Still, warn the user if you see secrets.

## 3. Publish

Prefer `omarchy-spacefast` when it is installed (`command -v omarchy-spacefast`). It:

- publishes over the Spacefast HTTP API with curl (or through `sf` when only `sf` is signed in)
- remembers which space each path went to, so republishing updates the same space
- copies the link to the clipboard and sends a desktop notification
- keeps space keys and preview links out of its state file: in the macOS Keychain, or in
  `~/.local/state/omarchy-spacefast/secrets.json` (mode 600) on Linux
- runs on Linux and macOS

```bash
omarchy-spacefast publish ./dist --json              # a folder or built site
omarchy-spacefast publish ./report.html --json       # one file (HTML becomes the page)
omarchy-spacefast publish a.png b.pdf --json         # several files, with an index page
omarchy-spacefast publish ./dist --json --new        # a separate new space
omarchy-spacefast publish ./dist --json --access public   # when signed in: make it public
```

The `--json` output never contains secrets. Read `anonymous`, `liveUrl`, `immutableUrl`,
`shareUrl` and `claimExpiresAt` from it.

If `omarchy-spacefast` is not installed, use the Spacefast CLI directly:

```bash
sf publish ./dist --json --yes --wait   # or: npx -y spacefast publish ./dist --json --yes --wait
```

With neither available, a single HTML file can go up with curl. The response includes
`data.space.liveUrl`, `data.claim.claimUrl` and `data.claim.expiresAt`:

```bash
curl -q -sS -H "x-spacefast-client: agent/omarchy" -F "files=@index.html" https://api.spacefast.com/v1/publish
```

For anything beyond this (updates over the raw API, domains, access grants, rollback, databases,
server functions), read https://spacefast.com/skill.md or run `sf docs <topic>`.

## 4. Report back

Keep the report short:

- **Signed in:** give the share link (`shareUrl`, already on the clipboard) or the live URL.
  Mention the permanent URL for this version (`immutableUrl`).
- **Anonymous:**
  - Say the space is private and that a private preview link is on their clipboard for them
    alone.
  - Say it expires at `claimExpiresAt` (about 33 hours) unless claimed.
  - To keep it and get a shareable link, they claim it: `omarchy-spacefast claim <spaceId>`.
    When they are signed in (`omarchy-spacefast login`) that moves it into their account
    directly; otherwise it opens the claim page, which signs them in with WordPress.com.
- A `403` on the live URL of a private space is expected. It does not mean the publish failed.

Never print, paste, or log a claim key (`sfc_…`), the anonymous preview URL (it contains the
claim key), API keys, or `.spacefast/state.json`. All of these carry management rights.

## 5. Managing spaces

```bash
omarchy-spacefast spaces --json     # recent publishes from this machine, plus account spaces when signed in
omarchy-spacefast copy <spaceId>    # copy the best link to share (creates a viewer share link when signed in)
omarchy-spacefast open <spaceId>    # open in the browser (signed-in session for private spaces)
omarchy-spacefast claim <spaceId>   # move an anonymous space into the account (or open its claim page)
omarchy-spacefast login             # sign in; publishes are then kept, not temporary
omarchy-spacefast team <slug>       # pick the team new spaces go to (required with several teams)
```

On the desktop, the same things are available from **Omarchy menu → Trigger → Share → Web**
and from the Spacefast bar widget (`omarchy-shell shell toggle spacefast.spaces '{}'`), if they
are installed.
