# Pre-Installation Guide

## Prerequisites

Before running the Ghostarch installer, ensure your system is prepared.

## 1. Install Base Dependencies

```bash
pacman -S base-devel git
```

This installs:
- **base-devel**: Essential build tools (make, gcc, etc.)
- **git**: For cloning repositories

## 2. Verify WSL2

Ensure you are running WSL2:

```bash
wsl -l -v
```

If using WSL1, upgrade:

```bash
wsl --set-version Ubuntu 2
```

## 3. Install Arch Linux

### Option A: Official Microsoft Store
1. Install "Arch Linux" from Microsoft Store
2. Launch and complete initial setup

### Option B: Manual Setup
1. Download Arch Linux rootfs
2. Extract and import:
   ```bash
   wsl --import ArchLinux <path> <archlinux-rootfs.tar.gz>
   wsl -d ArchLinux
   ```

## 4. Initial System Setup

After launching Arch Linux for the first time:

```bash
# Update package database
pacman -Sy

# Install base dependencies
pacman -S base-devel git

# Set timezone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime

# Generate locale
sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen
```

## 5. Clone Ghostarch

```bash
git clone https://github.com/sst/ghost-arch.git
cd ghost-arch
```

## Next Steps

Run the installation:

```bash
# Full installation
./install-ghostarch.sh

# Or step by step
./install-core.sh
./install-tools.sh
```

See [README.md](../README.md) for full documentation.
