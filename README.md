# claude-setup

A shared Claude Code setup: team conventions (`CLAUDE.md`) and skills, installed with one command on macOS or Windows.

## What you get

- **`CLAUDE.md`**: shared instructions loaded into every Claude Code session. Right now: run `/code-review` and `/security-review` before every push.
- **Skills** (as the `claude-setup` plugin):
  - `frontend-design`: guidance for distinctive, intentional UI design (by Anthropic, Apache-2.0, see [NOTICE](NOTICE)).
- **`code-review`** plugin from Anthropic's official marketplace, which the `CLAUDE.md` rule relies on.

## Install

You need [git](https://git-scm.com) and [Claude Code](https://code.claude.com).

### macOS / Linux

```bash
git clone https://github.com/dandoonian/claude-setup.git ~/claude-setup
cd ~/claude-setup
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/dandoonian/claude-setup.git $HOME\claude-setup
cd $HOME\claude-setup
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Restart Claude Code afterwards. Run `/memory` to confirm the shared `CLAUDE.md` is loaded, and `/plugin` to see the plugins.

## Update

Run the installer again. It pulls the latest version first.

```bash
./install.sh                                              # macOS / Linux
powershell -ExecutionPolicy Bypass -File .\install.ps1    # Windows
```

Skills also update on their own through the plugin marketplace.

## What the installer changes

- Copies `CLAUDE.md` to `~/.claude/claude-setup/CLAUDE.md`.
- Links it from your own `~/.claude/CLAUDE.md`. If you don't have one, it's created. If you do, the installer asks what to do:
  - **Merge** (recommended): keeps your file and adds one line, `@~/.claude/claude-setup/CLAUDE.md`, which loads the shared notes alongside yours.
  - **Replace**: backs up your file as `CLAUDE.md.backup-<date>` and uses only the shared notes.
  - **Diff**: shows your file next to the shared notes, then asks again.
  - **Abort**: changes nothing.

  It also warns if your file already contains some of the shared notes, so you can remove the duplicates.
- Adds this repo and Anthropic's official marketplace, and installs the `claude-setup` and `code-review` plugins.

To skip the question (for scripts), pass the choice up front:

```bash
./install.sh --merge          # or --replace / --abort
```
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Mode merge    # or replace / abort
```

Without a terminal to ask in, the installer merges.

To uninstall: remove that line from `~/.claude/CLAUDE.md`, delete `~/.claude/claude-setup/`, and run `/plugin` to uninstall the plugins.

## Only want the skills?

Inside Claude Code:

```
/plugin marketplace add dandoonian/claude-setup
/plugin install claude-setup@dandoonian
```

## For organization admins

To push the skills to everyone in a Claude Team or Enterprise organization, add this to **Organization settings → Claude Code → Managed settings**:

```json
{
  "extraKnownMarketplaces": {
    "dandoonian": {
      "source": { "source": "github", "repo": "dandoonian/claude-setup" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "claude-setup@dandoonian": true,
    "code-review@claude-plugins-official": true
  }
}
```

For the Claude app (chat and Cowork), owners can upload each skill folder as a `.zip` under **Organization settings → Skills**.

## Repo layout

```
CLAUDE.md                          shared instructions
install.sh / install.ps1           installers
.claude-plugin/marketplace.json    marketplace catalog
plugins/claude-setup/              the plugin
  .claude-plugin/plugin.json
  skills/<skill-name>/SKILL.md
```

## Contributing

Suggestions welcome: open an issue or a pull request. To add a skill, create `plugins/claude-setup/skills/<name>/SKILL.md` and bump `version` in `plugin.json`.

## License

MIT for everything in this repo, except third-party skills, which keep their own license (see [NOTICE](NOTICE)).
