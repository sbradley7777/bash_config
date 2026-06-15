# Homebrew Setup on macOS (Fresh Install)

## 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On Apple Silicon (M1/M2/M3), Homebrew installs to `/opt/homebrew`. After installation, add it to your shell environment:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv bash)"' >> ~/.bash_profile
eval "$(/opt/homebrew/bin/brew shellenv bash)"
```

## 2. Update Homebrew

```bash
brew update
```

## 3. Install Packages

### Emacs (emacs-plus with native compilation)

The standard `brew install emacs` formula is minimal. The `emacs-plus` tap provides a more fully-featured build:

```bash
brew tap d12frosted/emacs-plus
brew trust d12frosted/emacs-plus
brew install emacs-plus@31 --with-native-comp
```

### CLI Tools

```bash
brew install bat glab gh aspell shellcheck marksman taplo pipx bash-completion@2
```

| Package | Purpose |
|---|---|
| `bat` | `cat` with syntax highlighting |
| `glab` | GitLab CLI |
| `gh` | GitHub CLI |
| `aspell` | Spell checker (used by Emacs flyspell) |
| `shellcheck` | Shell script linter |
| `marksman` | Markdown LSP server |
| `taplo` | TOML LSP / formatter |
| `pipx` | Install Python CLI tools in isolated envs |
| `bash-completion@2` | Enhanced bash tab completion |

After installing `bash-completion@2`, source it in your `~/.bash_profile` or `~/.bashrc`:

```bash
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && \
    source "/opt/homebrew/etc/profile.d/bash_completion.sh"
```

Add git completion (symlink from Xcode CLT):

```bash
ln -s /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash \
    /opt/homebrew/share/bash-completion/completions/git
```

### Google Cloud SDK

```bash
brew install --cask google-cloud-sdk
```

Add shell completion in your `~/.bash_profile` or `~/.bashrc`:

```bash
source /opt/homebrew/share/google-cloud-sdk/completion.bash.inc
source /opt/homebrew/share/google-cloud-sdk/path.bash.inc
```

### Linux Filesystem (anylinuxfs)

Allows mounting Linux filesystems on macOS:

```bash
brew tap nohajc/anylinuxfs
brew trust nohajc/anylinuxfs
brew install anylinuxfs
brew install fenio/tap/anylinuxfs-gui  # optional GUI frontend
```

### GUI Applications (Casks)

```bash
brew install --cask utm balenaetcher
```

| Cask | Purpose |
|---|---|
| `utm` | Virtual machines on Apple Silicon |
| `balenaetcher` | Flash OS images to USB drives |

## 4. Verify Installed Packages

```bash
brew list
```

## 5. Upgrade Packages

```bash
brew upgrade            # upgrade all
brew upgrade anylinuxfs # upgrade a specific package
```
