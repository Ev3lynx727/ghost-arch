# Ghostarch Architecture

This document explains the architecture and design decisions behind Ghostarch, including the hybrid configuration system.

---

## Overview

Ghostarch is a modular installer for Arch Linux in WSL2, integrating selected BlackArch penetration testing tools. It prioritizes:

- **Modularity** — Separate scripts for distinct concerns (core, tools, GPU)
- **User Experience** — Guided interactive installation with non-interactive fallback
- **Extensibility** — Data-driven package management via manifest or config
- **Maintainability** — Shared common library, clear abstractions

---

## Directory Structure

```bash
ghost-arch/
├── install-ghostarch.sh      # Orchestrator (main entry point)
├── install-core.sh           # Core: oh-my-zsh, repository setup
├── install-tools.sh          # Tools: package groups, user, workdir
├── install-nvidia.sh        # GPU: NVIDIA drivers, CUDA, hashcat
├── lib/                     # Modular helper functions
│   ├── args.sh              # CLI argument parsing
│   ├── common.sh            # Shared core utilities (logging, config)
│   ├── groups.sh            # Package group definitions and listing
│   ├── packages.sh          # Package installation and updates
│   ├── prompts.sh           # User interaction and setup prompts
│   ├── readme.sh            # README.md generation logic
│   ├── system.sh            # Environment checks and validation
│   └── zsh.sh               # Zsh configuration and setup
├── templates/
│   └── zshrc                # Zshell configuration template
├── docs/                    # Detailed documentation
│   ├── ARCHITECTURE.md      # This file (design documentation)
│   ├── MIGRATION.md         # Guide: config arrays → manifest
│   └── pre-installation.md  # Prerequisites and WSL2 setup
├── config.sh.example        # Configuration template (arrays + flags)
├── package-groups.conf.example  # Manifest template (declarative)
├── README.MD                # Master documentation (user-facing)
└── AGENTS.md                # Agent integration notes
```

---

## Configuration Modes

Ghostarch supports two configuration philosophies:

### 1. Config Arrays (`config.sh`)

Traditional approach: individual bash arrays define package groups.

```bash
# config.sh
NETWORKING_PACKAGES=(net-tools iputils openssh curl wget ...)
PROGRAMMING_PACKAGES=(python python-pip go ruby)
PENTEST_PACKAGES=(nmap ettercap wireshark-cli)
# ... etc

SKIP_NETWORKING=false
SKIP_PROGRAMMING=true
WORKDIR="$HOME/ghostarch"
```

**Pros:**
- Familiar bash syntax
- Direct array manipulation
- Good for simple tweaks

**Cons:**
- 5 separate arrays (repetitive)
- Adding group requires multiple edits
- No descriptive metadata (descriptions hardcoded in script)

### 2. Manifest (`package-groups.conf`)

Declarative approach: associative arrays define groups and metadata.

```bash
# package-groups.conf
declare -A GROUP_DESCRIPTIONS=(
    [networking]="Networking diagnostics and utilities"
    [programming]="Programming languages"
)

declare -A PACKAGE_GROUPS=(
    [networking]="net-tools iputils openssh curl wget ..."
    [programming]="python go ruby"
    [custom]="vim neovim"  # Easy to add!
)
```

**Pros:**
- Groups and descriptions in one place
- Easy to add custom groups (no code changes)
- Clear separation of data from logic
- Self-documenting via `--list-groups`

**Cons:**
- Bash associative arrays (requires bash 4+)
- Slightly different syntax than config arrays

### Resolution Order

1. If `package-groups.conf` exists → **manifest mode** (PACKAGE_GROUPS used)
2. Else → **config mode** (individual `*_PACKAGES` arrays from `config.sh`)
3. Else → **fallback** (hardcoded defaults in script)

Manifest takes precedence. This allows gradual migration.

---

## Module Responsibilities

### `install-ghostarch.sh` (Orchestrator)

**Purpose:** Top-level entry point for complete installation.

**Flow:**
1. Initialize logging, perform system checks
2. Run `install-core.sh` (zsh + oh-my-zsh + BlackArch)
3. Prompt for user setup and workspace configuration
4. Configure WSL default user
5. Print completion summary and next steps

**Does NOT install tools or GPU** — those are separate stages.

**Usage:**
```bash
./install-ghostarch.sh              # Interactive full install
./install-ghostarch.sh --noninteractive  # Automated
```

---

### `install-core.sh` (Core System)

**Purpose:** Establish foundational tools and repositories.

**Installs:**

- Zsh (if not present)
- Oh-My-Zsh with plugins (zsh-autosuggestions, zsh-syntax-highlighting)
- BlackArch repository and keyring

**Usage:** Typically called by orchestrator, but can be run standalone.

**Flags:**
- `--skip-zsh` — Don't install zsh
- `--skip-omz` — Don't install oh-my-zsh
- `--skip-blackarch` — Don't add BlackArch repo

---

### `install-tools.sh` (Package Groups)

**Purpose:** Install tool groups and configure user environment.

**Key Innovations:**

1. **Dual-mode package resolution** (manifest vs config)
2. **`process_package_groups()`** — Unified loop with decoupled skip logic
3. **`--list-groups`** — introspection command
4. **`validate_manifest()`** — sanity checks

**Package Group Concept:**

A "group" is a logical collection of related packages with a human-readable description. Default groups:

- `networking` — network diagnostics (net-tools, curl, tcpdump, etc.)
- `programming` — languages (python, go, ruby)
- `pentest` — pentesting (nmap, ettercap, wireshark)
- `recon` — reconnaissance (theharvester, recon-ng, dnsrecon)
- `additional` — misc security tools (nikto, metasploit, sqlmap)

**Skip Flags:**

- Groups are skipped via `--skip-<group>` flags
- Flag names derived from group names (lowercase)
- Example: `--skip-networking`, `--skip-pentest`

**Configuration Sources:**

- Manifest: `PACKAGE_GROUPS[group]` + `GROUP_DESCRIPTIONS[group]`
- Config: `NETWORKING_PACKAGES` array (via `GROUPS` mapping)
- Fallback: hardcoded defaults in script

**Usage:**

```bash
./install-tools.sh                      # Interactive
./install-tools.sh --noninteractive     # Automated
./install-tools.sh --skip-networking --skip-pentest  # Selective
./install-tools.sh --list-groups        # Show configuration
```

---

### `install-nvidia.sh` (GPU Acceleration)

**Purpose:** Set up NVIDIA WSL2 drivers and GPU-accelerated tools.

**Installs:**

- `nvidia` + `nvidia-utils` (drivers)
- `cuda` + `cuda-tools` (CUDA toolkit)
- `hashcat` (GPU password cracking)

**Configuration:**

- Uses `GPU_PACKAGES` array from `config.sh` if defined
- Otherwise uses built-in defaults: `nvidia nvidia-utils cuda cuda-tools hashcat`

**Note:** Requires NVIDIA WSL2 drivers on Windows host.

**Usage:**

```bash
# After install-tools.sh (or orchestrator)
./install-nvidia.sh
```

---

### `lib/` (Shared Modules)

**Purpose:** Decoupled functional modules used across the installer.

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| `common.sh` | Core utilities | `init_logging`, `load_config`, `load_package_manifest` |
| `args.sh` | CLI arguments | `parse_args` (internal to scripts) |
| `groups.sh` | Package groups | `list_groups`, `validate_manifest` |
| `packages.sh` | Installation | `install_packages`, `install_tool_group` |
| `prompts.sh` | Interaction | `confirm`, `prompt_user`, `prompt_user_setup` |
| `readme.sh` | Documentation | `generate_readme` |
| `system.sh` | Validation | `check_root`, `check_wsl`, `check_sudo`, `check_network` |
| `zsh.sh` | Shell setup | `install_zsh`, `setup_oh_my_zsh` |

**Design Principles:**

- **Encapsulation:** Logic is grouped by domain (e.g., all prompting in `prompts.sh`).
- **Reusability:** Functions are designed to be called by any of the main `install-*.sh` scripts.
- **Fail-fast:** System checks in `system.sh` prevent execution on unsupported environments.

---

## Package Resolution Flow

```mermaid
┌─────────────────────────────────────┐
│  install-tools.sh main() begins     │
└───────────────┬─────────────────────┘
                │
                ▼
    ┌───────────────────────┐
    │ Load package manifest?│
    │  (package-groups.conf)│
    └─────────┬─────────────┘
              │ YES
              ▼
    ┌─────────────────────────────┐
    │ Manifest mode               │
    │ groups = keys of            │
    │   PACKAGE_GROUPS associative│
    │ array                       │
    └─────────┬───────────────────┘
              │
              │ NO
              ▼
    ┌─────────────────────────────┐
    │ Config mode                 │
    │ groups = keys of GROUPS map │
    │ (5 default groups)          │
    └─────────┬───────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │ validate_manifest()         │
    │ (warn if manifest present)  │
    └─────────┬───────────────────┘
              │
              ▼
    ┌─────────────────────────────┐
    │ For each group:             │
    │   - Check SKIP_<> flag      │
    │   - Get desc & packages     │
    │   - Call install_tool_group│
    └─────────────────────────────┘
```

**Skip Flag Convention:**

```text
Group name:       "networking"
Skip flag var:    SKIP_NETWORKING
Skip flag value:  "true" to skip
CLI flag:         --skip-networking
```

This decoupling means **no `case` statement** is needed — the flag is derived from the group name automatically.

---

## Data Flow: `install-tools.sh`

```bash
main() {
    init_logging
    check_root && check_wsl && check_sudo

    # Load config (manifest OR config.sh)
    if ! load_package_manifest; then
        load_config  # Fallback to config.sh
    fi

    # Handle introspection
    if [[ "$LIST_GROUPS" == "true" ]]; then
        list_groups  # Shows active configuration
        exit 0
    fi

    validate_manifest  # Warnings only

    # Interactive prompts (unless NONINTERACTIVE)
    prompt_user_setup
    prompt_workdir_setup

    # Install all groups
    process_package_groups

    generate_readme
}
```

---

## Extensibility: Adding a Custom Group

### With Manifest (Recommended)

1. Edit `package-groups.conf`:

```bash
declare -A GROUP_DESCRIPTIONS=(
    # ... existing ...
    [custom]="My custom toolset"
)

declare -A PACKAGE_GROUPS=(
    # ... existing ...
    [custom]="vim neovim bat"
)
```

2. Test: `./install-tools.sh --list-groups`

3. Install: `./install-tools.sh` (will prompt) or `./install-tools.sh --skip-custom` to skip

**No code changes needed.** The manifest is fully data-driven.

---

### With Config Arrays (Legacy)

1. Edit `config.sh`:

```bash
CUSTOM_PACKAGES=(vim neovim bat)
```

2. Edit `install-tools.sh` **in two places**:

```bash
# Add to GROUPS mapping (around line 25):
[ custom ]="CUSTOM_PACKAGES 'Custom Tools'"

# Add skip flag variable (around line 19):
SKIP_CUSTOM=false

# Add to argument parser (while loop):
--skip-custom) SKIP_CUSTOM=true ;;
```

3. (Optional) Update `config.sh.example` to document your custom group.

**Requires code changes.** This is why manifest is preferred for customizations.

---

## Design Patterns

### 1. Decoupled Skip Logic

**Bad (4954b58):**
```bash
for group in "${!PACKAGE_GROUPS[@]}"; do
    case "$group" in
        networking) [[ "$SKIP_NETWORKING" == "true" ]] && skip=true ;;
        pentest)   [[ "$SKIP_PENTEST" == "true" ]] && skip=true ;;
        # Add new group → update case!
    esac
done
```

**Good (Hybrid):**

```bash
skip_var="SKIP_$(echo "$group" | tr '[:lower:]' '[:upper:]')"
[[ "${!skip_var:-}" == "true" ]] && skip=true
# Group name → skip flag by convention
# No code changes needed for new groups
```

### 2. Progressive Enhancement

- Base: config arrays (always available)
- Enhancement: manifest (optional, overrides)
- Feature: `--list-groups` works in both modes
- Backward: existing `config.sh` users unaffected

### 3. Library-First Design

All scripts:
1. Set `SCRIPT_DIR` and `PROJECT_ROOT`
2. Source `lib/common.sh`
3. Call `init_logging`, `check_*` functions
4. Load configuration (manifest or config)
5. Perform script-specific work

This ensures consistency and reduces duplication.

---

## Testing Matrix

| Scenario | Setup | Expected behavior |
| :--- | :--- | :--- |
| Default (no config, no manifest) | — | Uses hardcoded defaults (5 groups) |
| Config only | `config.sh` present | Loads config arrays, 5 groups |
| Manifest only | `package-groups.conf` present | Loads manifest groups |
| Both present | Both files | Manifest **overrides** config |
| Custom group in manifest | `[custom]="..."` in both arrays | Appears in `--list-groups`, installs normally |
| Missing description | `GROUP_DESCRIPTIONS[foo]` undefined | Warning logged, group still installs |
| Empty package list | `PACKAGE_GROUPS[foo]=""` | Warning logged, group skipped |
| Skip flag typo | `--skip-foo` but group is `foos` | No skip (check logs) |

---

## Future Directions

Potential enhancements (outside current scope):

- **Dry-run mode:** `--dry-run` shows what would be installed without executing
- **Checkpoint/resume:** Track installed groups to resume interrupted installations
- **Group dependencies:** Declare that `pentest` requires `networking` (auto-enable)
- **Package verification:** Check for conflicts before installation
- **Profile templates:** Pre-made manifests for different use cases (e.g., "minimal", "full", "cloud")
- **Remote manifests:** Load package groups from URL (e.g., shared team config)
- **Uninstall mode:** Remove installed groups (with care)

---

## Rationale: Why This Architecture?

### Why Not Single Script?

Early versions bundled everything in one large script. Problems:
- Hard to test components independently
- Long-running monolithic process
- Difficult to reuse logic across scripts

**Solution:** Split by concern (core, tools, GPU) + shared library.

---

### Why Not Pure Manifest from Start?

We considered making manifest the only option. Reasons against:

1. **User adoption:** Existing users have `config.sh`, breaking changes bad
2. **Bash limitations:** Associative arrays less familiar than simple arrays
3. **Incremental migration:** Users can migrate at their own pace

**Solution:** Support both, manifest takes precedence, provide migration guide.

---

### Why Keep Hardcoded Fallbacks?**

If neither config nor manifest exists, the installer should still work (for quick tests or minimal setups). The hardcoded defaults provide a sane baseline.

---

### Why Skip Flags by Convention (Not Explicit Mapping)?

The `case` statement in 4954b58 tightly coupled groups to skip flags. Our convention-based approach (`SKIP_<GROUP>`) means:

- New groups automatically get skip support
- No code changes needed
- Clear and predictable

Trade-off: Slightly less explicit, but documented and validated via `--list-groups`.

---

## Key Files Reference

| File | Lines | Purpose |
| :--- | :--- | :--- |
| `install-ghostarch.sh` | 120 | Orchestrator |
| `install-core.sh` | 180 | Core setup |
| `install-tools.sh` | 320 | Tools + manifest system |
| `install-nvidia.sh` | 80 | GPU setup |
| `lib/*.sh` | 800+ | Combined shared modules |
| `docs/ARCHITECTURE.md` | this | Design documentation |
| `docs/MIGRATION.md` | 200 | Migration guide |
| `config.sh.example` | 120 | Config template |
| `package-groups.conf.example` | 60 | Manifest template |

---

## Credits

**Architecture:** Hybrid approach combining:
- Blueprint branch's modularity and UX
- 4954b58's manifest-driven package groups

**Review:** ghostclaw (architectural code review assistant)

**Status:** Production-ready with backward compatibility.
