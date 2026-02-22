# Migration Guide: Config Arrays → Manifest

This guide helps you transition from the traditional `config.sh` array approach to the new `package-groups.conf` manifest system.

---

## Why Migrate?

The manifest system offers:
- **Single source of truth** for package groups (associative array)
- **Easier customization** — add custom groups without editing code
- **Better organization** — descriptions and packages together
- **Future-proof** — new features will prioritize manifest compatibility

**Backward compatibility is maintained:** If `package-groups.conf` doesn't exist, the installer falls back to `config.sh` arrays automatically.

---

## Migration Steps

### Step 1: Copy the Example Manifest

```bash
cd /path/to/ghost-arch
cp package-groups.conf.example package-groups.conf
```

### Step 2: Translate Your Config Arrays

If you have a `config.sh` with custom package arrays, convert them:

**Before (`config.sh`):**
```bash
NETWORKING_PACKAGES=(
    net-tools iputils openssh curl wget
    bind-tools socat inetutils tcpdump openssl
    speedtest-cli htop iotop iftop netcat whois p7zip
)

PROGRAMMING_PACKAGES=(
    python python-pip python-virtualenv go ruby
)

PENTEST_PACKAGES=(
    nmap ettercap wireshark-cli
)
# ... etc
```

**After (`package-groups.conf`):**
```bash
declare -A GROUP_DESCRIPTIONS=(
    [networking]="Networking diagnostics and utilities"
    [programming]="Programming languages and package managers"
    [pentest]="Penetration testing tools"
    [recon]="Reconnaissance and OSINT"
    [additional]="Additional security tools"
)

declare -A PACKAGE_GROUPS=(
    [networking]="net-tools iputils openssh curl wget bind-tools socat inetutils tcpdump openssl speedtest-cli htop iotop iftop netcat whois p7zip"
    [programming]="python python-pip python-virtualenv go ruby"
    [pentest]="nmap ettercap wireshark-cli"
    [recon]="theharvester recon-ng dnsrecon"
    [additional]="nikto gobuster metasploit sqlmap volatility"
)
```

### Step 3: Add Custom Groups (Optional)

One of the manifest's biggest advantages: easily add your own groups.

```bash
# In package-groups.conf:

declare -A GROUP_DESCRIPTIONS=(
    # ... default groups ...
    [custom]="My personal tools"
    [dev]="Development utilities"
)

declare -A PACKAGE_GROUPS=(
    # ... default groups ...
    [custom]="vim neovim bat ripgrep fd"
    [dev]="docker kubernetes-cli helm terraform"
)
```

Install with: `./install-tools.sh --skip-custom` or let it install normally.

### Step 4: Test Your Manifest

```bash
# See what groups are defined
./install-tools.sh --list-groups

# Expected output:
#   networking
#     Description: Networking diagnostics and utilities
#     Packages: net-tools iputils ...
#     Skip flag: SKIP_NETWORKING
#   ...
```

### Step 5: Remove or Rename `config.sh` (Optional)

Once you're satisfied with `package-groups.conf`, you can:

- **Keep** `config.sh` for other settings (WORKDIR, TARGET_USER, etc.)
- **Rename** it to avoid confusion: `mv config.sh config.sh.backup`
- **Delete** it if you've moved all settings to manifest (but note: WORKDIR, USER config still need place)

**Important:** The manifest only handles **package groups**. Other configuration (WORKDIR, TARGET_USER, NONINTERACTIVE, etc.) still uses `config.sh` or command-line flags.

---

## Side-by-Side Comparison

| Feature | Config Arrays | Manifest |
|---------|---------------|----------|
| Group definitions | 5 separate arrays | 1 associative array |
| Descriptions | Hardcoded in script | `GROUP_DESCRIPTIONS` mapping |
| Custom groups | Edit script code | Add to manifest |
| Add group | 3+ places (array, description, skip) | 2 places (description + packages) |
| Skip flags | Hardcoded if-blocks | Convention: `SKIP_<GROUP>` |
| See all groups | Read code or config | `--list-groups` |
| Clarity | Medium | High (groups together) |

---

## Advanced: Hybrid Mode

You can use **both** `config.sh` and `package-groups.conf` simultaneously:

- `package-groups.conf` defines **which groups** exist and their packages
- `config.sh` can still set **flags** (SKIP_NETWORKING, NONINTERACTIVE, WORKDIR, etc.)

This gives you the best of both:
- Manifest for package data (declarative)
- Config for installation behavior (procedural)

---

## Reverting to Config Arrays

If you encounter issues with the manifest:

```bash
# Temporarily disable manifest
mv package-groups.conf package-groups.conf.disabled

# Installer will fall back to config.sh automatically
./install-tools.sh
```

If you want to permanently revert:
- Delete or rename `package-groups.conf`
- Ensure your `config.sh` has the `*_PACKAGES` arrays defined
- No code changes needed — the installer detects the absence of manifest

---

## Troubleshooting

### "Manifest does not define PACKAGE_GROUPS"
Make sure you have:
```bash
declare -A PACKAGE_GROUPS=( ... )
```
in your manifest. It must be an associative array.

### Group not appearing in `--list-groups`
- Check spelling of group keys in both `PACKAGE_GROUPS` and `GROUP_DESCRIPTIONS`
- Ensure manifest is at project root (same directory as `install-tools.sh`)
- Verify manifest has correct bash syntax: `bash -n package-groups.conf`

### Skip flag not working
Skip flags follow the convention: `--skip-<group>` where `<group>` is the group name **as defined in the manifest**.

Example:
```bash
# Manifest group: [networking]
./install-tools.sh --skip-networking   # Works
./install-tools.sh --skip-NETWORKING   # Won't work

# Manifest group: [mycustom]
./install-tools.sh --skip-mycustom     # Works
```

### Custom group not installing
- Is the group name in `PACKAGE_GROUPS`? 
- Is `GROUP_DESCRIPTIONS[$group]` set? (Not required, but good practice)
- Are you using `--skip-<group>` that accidentally matches your custom group?
- Check logs: `tail -f ~/.ghostarch/install.log`

### Want to see what's actually being used?
Add `-d` (debug) flag:
```bash
./install-tools.sh -d --list-groups
```
Shows mode detection and array resolution.

---

## Future Compatibility

Going forward, **manifest mode will be the recommended approach**:
- New features will be tested with manifest first
- Documentation examples will use `package-groups.conf`
- `config.sh` arrays will be considered legacy but still supported

**Recommended:** Migrate to manifest when convenient. The hybrid approach lets you migrate gradually.

---

## Questions?

Open an issue at: https://github.com/Ev3lynx727/ghost-arch/issues
