#!/bin/bash

# Ghostarch README Generation
# Generate README.md for the project

generate_readme() {
    log_info "Generating README..."

    local readme_content="# Ghostarch: Custom Arch WSL2 with Selected BlackArch Tools

## Overview
Ghostarch is a streamlined setup for Arch Linux in WSL2, integrating selected bleeding-edge penetration testing tools from BlackArch without the full suite.

## User Configuration
- **User**: $TARGET_USER
- **Working Directory**: $WORKDIR

## Installation
1. Install Arch Linux in WSL2 using the official image.
2. Run \`./install-core.sh\` to set up zsh/oh-my-zsh and BlackArch repo.
3. Run \`./install-tools.sh\` to install tools and configure user.
4. (Optional) Run \`./install-nvidia.sh\` for GPU acceleration.

## Tools Installed
- **Basic Networking**: net-tools, iputils, openssh, curl, wget, bind-tools, socat, inetutils, tcpdump, openssl, speedtest-cli, netcat, whois.
- **Monitoring**: htop, iotop, iftop (system and network monitoring).
- **Programming Languages**: python, python-pip, python-virtualenv, go, ruby.
- **Pentest Tools**: nmap, ettercap, wireshark-cli.
- **Recon Tools**: theharvester, recon-ng, dnsrecon.
- **Additional Tools**: nikto, gobuster, metasploit, sqlmap, volatility.
- **GPU Tools** (via install-nvidia.sh): hashcat (with CUDA acceleration).

## WSL2 Limitations and Workarounds
- **Network Access**: No direct WiFi interface access. Use Windows Wireshark for host-level WiFi sniffing.
- **Scans**: SYN scans (-sS) may fail due to NAT; use connect scans (-sT).
- **GUI**: For Wireshark GUI, enable WSLg in Windows.
- **Raw Sockets**: Limited; tools work on virtual network only.

## Usage Examples
- Basic Networking: \`ping google.com\`, \`dig example.com\`, \`speedtest-cli\`, \`openssl s_client -connect example.com:443\`
- Monitoring: \`htop\` (system), \`iftop\` (network bandwidth), \`iotop\` (I/O)
- Languages: \`python3 script.py\`, \`pip install scapy\`, \`go run tool.go\`, \`ruby exploit.rb\`
- Pentest: Scan ports: \`nmap -sT -p 1-1000 target.com\`, Sniff: \`ettercap -T -i eth0\`, Capture: \`wireshark-cli\`
- Recon: Harvest data: \`theharvester -d example.com -b all\`, DNS enum: \`dnsrecon -d example.com\`, Framework: \`recon-ng\`
- Additional: Web scan: \`nikto -h http://example.com\`, Dir brute: \`gobuster dir -u http://example.com -w /usr/share/wordlists/dirb/common.txt\`, Exploit: \`msfconsole\`, SQL test: \`sqlmap -u http://example.com/vuln.php?id=1\`, Forensics: \`volatility -f memory.dump imageinfo\`
- GPU (install-nvidia.sh): \`hashcat -m 0 -a 3 hash.txt\` (GPU cracking)

## Updates
Run \`sudo pacman -Syu\` to update Arch and BlackArch packages.

## Troubleshooting
- **Signature Errors**: \`sudo pacman -S blackarch-keyring\`
- **Time Sync**: \`sudo hwclock -s\` (if clock issues)
- **GUI Issues**: Ensure WSLg is enabled in Windows Features.
- **Conflicts**: Use \`--overwrite='*'\` during updates if needed.

## Dual WSL Setup
- Ubuntu WSL2: For Docker/containers.
- Arch WSL2 (Ghostarch): For tools.

## Sniffing Docker Containers from Arch WSL2
- Run containers in Ubuntu WSL2 with \`--network host\` for host networking.
- In Arch WSL2, use \`sudo tcpdump -i eth0\` to capture packets from containers.
- Note: Default Docker bridge is isolated; host network allows sniffing on shared WSL adapter.

For full pentesting, consider a native Linux VM.
"

    echo "$readme_content" | sudo tee "$WORKDIR/README.md" >/dev/null
    sudo chown "$TARGET_USER:$TARGET_USER" "$WORKDIR/README.md"
}
