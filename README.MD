# Ghostarch: Streamlined Arch Linux WSL2 for Pentesting

Ghostarch is an automated installer for Arch Linux in WSL2, designed for security professionals and enthusiasts. It provides a clean, modular setup with selected BlackArch tools, optimized for the WSL2 environment.

## 🚀 Key Features

- **Automated Setup**: One-command installation for core components.
- **Zsh Optimized**: pre-configured Zsh with Oh-My-Zsh, Powerlevel10k (optional), and essential plugins.
- **BlackArch Integration**: Seamlessly adds the BlackArch repository and provides a curated list of tools.
- **GPU Acceleration**: Built-in support for NVIDIA CUDA (hashcat, etc.) in WSL2.
- **Workspace Organization**: Creates a structured pentesting directory with dedicated subfolders for tools, exploits, and reports.
- **WSL2 Focused**: Configured to handle WSL2-specific networking and user defaults.

## 📂 Repository Structure

- `install-ghostarch.sh`: Main orchestrator (Run this first!).
- `install-core.sh`: Core system setup (Zsh, BlackArch repo).
- `install-tools.sh`: curated pentest tools and user workspace setup.
- `install-nvidia.sh`: GPU acceleration setup for NVIDIA users.
- `lib/common.sh`: Shared helper functions and logic.
- `templates/`: Configuration templates (e.g., `.zshrc`).
- `docs/`: Additional documentation.

## 🛠️ Installation

### Prerequisites

1.  **Windows 10/11** with WSL2 enabled.
2.  **Arch Linux** installed from the Microsoft Store or via `wsl --import`.
3.  Internet connectivity.

### Quick Start

Clone this repository and run the main installer:

```bash
git clone https://github.com/youruser/ghostarch.git
cd ghostarch
chmod +x *.sh
./install-ghostarch.sh
```

### Modular Installation

You can also run components individually:

- **Core Only**: `./install-core.sh`
- **Tools Only**: `./install-tools.sh`
- **NVIDIA GPU**: `./install-nvidia.sh`

## ⚙️ Configuration

Copy `config.sh.example` to `config.sh` to customize your installation:

```bash
cp config.sh.example config.sh
nano config.sh
```

## 📖 Usage

After installation, your workspace (default: `~/ghostarch`) will contain a curated `README.md` with usage examples for all installed tools, as well as WSL2-specific tips.

### Tool Categories Included:
- **Networking**: nmap, socat, tcpdump, etc.
- **Recon**: theharvester, dnsrecon, recon-ng.
- **Web**: nikto, gobuster, sqlmap.
- **Exploitation**: metasploit.
- **Forensics**: volatility.
- **Cracking**: hashcat (with GPU support).

## ⚠️ Important WSL2 Notes

- **Network**: WSL2 uses NAT; some network-heavy scans (like SYN scans) might require `-sT`.
- **Hardware**: Direct hardware access (like USB WiFi adapters) is limited in WSL2.
- **Default User**: The installer can configure WSL to log you in as your new user automatically. Restart WSL (`wsl --terminate ArchLinux`) to apply.

## 🤝 Contributing

Contributions are welcome! Please follow the guidelines in [AGENTS.md](AGENTS.md).

## 📜 License

This project is open-source. See individual tool licenses for their respective terms.
