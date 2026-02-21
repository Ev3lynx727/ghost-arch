# Agent Guidelines for Ghostarch

This is a shell script project for WSL2 Arch Linux installation with BlackArch tools.

## Project Structure

```
ghost-arch/
├── lib/
│   └── common.sh           # Shared helper functions
├── docs/
│   └── pre-installation.md # Pre-installation guide
├── install-ghostarch.sh   # Main orchestrator
├── install-core.sh        # First-time setup (zsh, repos)
├── install-tools.sh       # Post-install (tools, user config)
├── install-nvidia.sh      # GPU acceleration
├── config.sh.example      # Configuration template
└── README.md              # Generated documentation
```

## Commands

### Linting

Run ShellCheck on all scripts:
```bash
shellcheck lib/common.sh install-*.sh
```

Check a single script:
```bash
shellcheck install-core.sh
```

### Formatting

Scripts use standard bash formatting. Run ShellCheck with auto-fix where possible:
```bash
shellcheck -f diff lib/common.sh
```

### Dry Run Mode

Test scripts without making changes:
```bash
# Add dry-run logic to scripts or simulate with:
NONINTERACTIVE=1 ./install-tools.sh --skip-networking --skip-user --skip-workdir
```

### Testing

There are no formal tests. Manual testing is done in WSL2:
1. Fresh Arch Linux WSL2 instance
2. Run pre-installation steps from docs/pre-installation.md
3. Clone this repo
4. Run: `./install-ghostarch.sh`
5. Verify all tools installed: `pacman -Q | grep -E "nmap|metasploit|sqlmap"`

## Code Style Guidelines

### Shell Script Standards

- **Shebang**: Use `#!/bin/bash` for all scripts
- **Strict mode**: Begin all scripts with `set -euo pipefail`
- **Executable**: All main scripts must be executable (`chmod +x`)

### Naming Conventions

- **Scripts**: `install-*.sh` (kebab-case)
- **Functions**: `snake_case` (e.g., `check_network`, `install_packages`)
- **Variables**: `UPPER_SNAKE_CASE` for constants, `lower_snake_case` for locals
- **Constants**: Define at top of file (e.g., `GHOSTARCH_VERSION`, `LOG_FILE`)

### Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Max 120 characters
- **Functions**: Declare with `local` for all variables inside
- **Commands**: Use long-form flags when available (e.g., `--noconfirm` not `-y`)

### Error Handling

- Use `set -euo pipefail` for fail-fast behavior
- Check return codes for critical commands: `if ! command; then ... fi`
- Provide meaningful error messages with `log_error`
- Use `trap cleanup EXIT` for cleanup on failure
- Exit with code 1 on errors

### Functions

Follow this template:
```bash
function_name() {
    local arg1="${1:-default}"
    local arg2="${2:-}"
    
    # Guard clauses
    if [[ -z "$arg1" ]]; then
        log_error "arg1 is required"
        return 1
    fi
    
    # Main logic
    log_info "Doing something with $arg1"
    
    return 0
}
```

### Logging

Use the built-in logging functions:
- `log_info "message"` - Normal operations
- `log_warn "message"` - Non-critical issues
- `log_error "message"` - Errors that may continue
- `log_debug "message"` - Verbose debug (requires DEBUG=1)

### Color Output

Use defined color variables for user-facing output:
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

echo -e "${GREEN}Success${NC}"
```

### Configuration

- External config in `config.sh` (see `config.sh.example`)
- Source config after lib/common.sh: `source "${SCRIPT_DIR}/lib/common.sh"`
- Use `${VARIABLE:-default}` for optional overrides

### User Interaction

- Always confirm before destructive operations
- Support `--noninteractive` / `-n` flag for CI/automation
- Use `confirm "Prompt?" "Y"` for yes/no prompts
- Use `prompt_user "Enter value" "default" var_name` for input

### Security

- Never hardcode credentials or API keys
- Validate user input before using
- Use `--noconfirm` only for pacman, not for user confirmation
- Verify downloads with checksums when available

### Dependencies

Document required external tools in comments:
```bash
# Requires: curl, git, sudo
```

### Documentation

- Comment complex logic
- Use here-doc for usage/help functions
- Keep README updated when adding features

## Git Conventions

- Commit messages: imperative mood, max 72 chars
- Branch naming: `feature/description` or `fix/description`
- Create PRs for review before merging
