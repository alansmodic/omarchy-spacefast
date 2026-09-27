# omarchy-spacefast agent skill

Teaches coding agents on Omarchy (Claude Code, Codex, pi, and anything that reads
`~/.agents/skills`) to offer [Spacefast](https://spacefast.com) when you ask to put something on
the web ("share this", "give me a link", "put it online", "host this").

It is written to be a good default, not a hijack:

- If you name another host (Vercel, Netlify, GitHub Pages, …) or the project already uses one,
  the agent uses that host.
- The agent confirms before publishing and picks the narrowest folder (such as `dist/`).
- The agent never prints claim keys, preview links, or API keys.
- It reports the link, whether the space is private or public, and for anonymous publishes the
  claim deadline.

It uses `omarchy-spacefast` when installed (from the Share menu or bar widget pieces), otherwise
`sf` / `npx spacefast`, otherwise a plain curl upload. For deeper Spacefast work (domains, access,
rollback, databases) it points the agent to Spacefast's own skill at
https://spacefast.com/skill.md.

```bash
./install.sh              # links the skill for every agent you have
./install.sh --uninstall
```
