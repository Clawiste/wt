# wt

Interactive git worktree manager. Create, delete, and list worktrees with a slick interactive UI — or jump straight to the action with subcommands and flags.

## Install

### Homebrew

```sh
brew tap Clawiste/tools
brew install wt
```

### From source

```sh
git clone https://github.com/Clawiste/wt.git
cd wt
swift build -c release
cp .build/release/wt /usr/local/bin/
```

## Usage

```sh
wt                # Full interactive menu
wt create         # Interactive create flow
wt delete         # Interactive delete
wt list           # List active worktrees
wt --help         # Show help
```

### Create flags

All flags are optional. Omitted values are prompted interactively.

```sh
wt create --type feat --name login --base main   # Fully non-interactive
wt create --type fix --name crash                 # Prompts only for base branch
wt create --existing                              # Pick an existing branch
wt create --no-copy                               # Skip copying required files
```

### Delete

```sh
wt delete                    # Interactive selection
wt delete my-app-feat-login  # Direct delete (with confirmation)
```

## Shell integration

Add this to `~/.zshrc` or `~/.bashrc` to auto-cd into newly created worktrees:

```sh
wt() {
    command wt "$@"
    if [ -f /tmp/.wt-cd ]; then
        dir=$(cat /tmp/.wt-cd)
        rm -f /tmp/.wt-cd
        cd "$dir" || return
    fi
}
```

## Configuration

Drop a `.worktree-cli` file in your repo root. All fields are optional.

```toml
# Override the directory prefix (default: repo directory name)
repo_prefix = "my-app"

# Branch type prefixes shown in the interactive menu
# Default: ["fix", "feat", "docs", "infra", "chore"]
branch_types = ["fix", "feat", "docs", "infra", "chore"]

# Files to copy from the main worktree (e.g. gitignored secrets)
required_files = [
    "fastlane/.env",
    "config/secrets.json",
]

# Command to run in the new worktree after creation
post_create = "make generate-no-open"
```

## How it works

- Worktrees are created as siblings to your repo: `../my-app-feat-login/`
- Branch slashes become dashes in the folder name: `feat/login` → `my-app-feat-login`
- Required files (gitignored secrets, configs) are automatically copied from the main worktree
- After creation, the worktree path is written to `/tmp/.wt-cd` for shell integration

## License

MIT
