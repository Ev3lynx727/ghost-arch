#!/bin/bash

# Ghostarch Tools Installation Script
# Post-installation: tools, user configuration, working directory
# Run this after install-core.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/users.sh"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Ghostarch Tools Installation - Post-installation setup

OPTIONS:
    -h, --help              Show this help message
    -n, --noninteractive   Run in non-interactive mode
    -d, --debug            Enable debug output
    --skip-networking      Skip networking tools
    --skip-programming     Skip programming languages
    --skip-pentest         Skip pentest tools
    --skip-recon           Skip recon tools
    --skip-additional      Skip additional tools
    --skip-user            Skip user configuration
    --skip-workdir         Skip working directory setup

EXAMPLES:
    $0                      # Interactive installation with user prompts
    $0 --noninteractive     # Non-interactive with defaults
    $0 --skip-user          # Skip user creation prompts

EOF
    exit 0
}

SKIP_NETWORKING=false
SKIP_PROGRAMMING=false
SKIP_PENTEST=false
SKIP_RECON=false
SKIP_ADDITIONAL=false
SKIP_USER=false
SKIP_WORKDIR=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -n|--noninteractive) NONINTERACTIVE=1 ;;
        -d|--debug) DEBUG=1 ;;
        --skip-networking) SKIP_NETWORKING=true ;;
        --skip-programming) SKIP_PROGRAMMING=true ;;
        --skip-pentest) SKIP_PENTEST=true ;;
        --skip-recon) SKIP_RECON=true ;;
        --skip-additional) SKIP_ADDITIONAL=true ;;
        --skip-user) SKIP_USER=true ;;
        --skip-workdir) SKIP_WORKDIR=true ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

install_tool_group() {
    local group_name="$1"
    shift
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_info "=== Installing $group_name ==="
    
    local install_now=true
    if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
        echo "Packages to install: ${packages[*]}"
        install_now=$(confirm "Install $group_name packages?" "Y")
    fi
    
    if [[ "$install_now" == "0" ]]; then
        log_warn "Skipping $group_name"
        return 0
    fi
    
    install_packages "${packages[@]}"
    log_info "$group_name installation complete"
}

main() {
    log_info "Starting Ghostarch Tools Installation"
    
    init_logging
    
    check_root
    check_wsl
    load_config
    
    echo
    log_info "Ghostarch Tools Installation"
    echo "=============================="
    echo
    
    if [[ "$NONINTERACTIVE" != "1" ]]; then
        echo "This will install:"
        echo "  - Networking tools"
        echo "  - Programming languages"
        echo "  - Penetration testing tools"
        echo "  - Reconnaissance tools"
        echo "  - Additional tools"
        echo
        confirm "Continue?" "Y" || exit 0
    fi
    
    prompt_user_setup
    prompt_workdir_setup
    
    echo
    log_info "=== Installing Tools ==="
    
    if [[ "$SKIP_NETWORKING" != "true" ]]; then
        install_tool_group "Networking Tools" "${NETWORKING_PACKAGES[@]:-net-tools iputils openssh curl wget bind-tools socat inetutils tcpdump openssl speedtest-cli htop iotop iftop netcat whois p7zip}"
    fi
    
    if [[ "$SKIP_PROGRAMMING" != "true" ]]; then
        install_tool_group "Programming Languages" "${PROGRAMMING_PACKAGES[@]:-python python-pip python-virtualenv go ruby}"
    fi
    
    if [[ "$SKIP_PENTEST" != "true" ]]; then
        install_tool_group "Pentest Tools" "${PENTEST_PACKAGES[@]:-nmap ettercap wireshark-cli}"
    fi
    
    if [[ "$SKIP_RECON" != "true" ]]; then
        install_tool_group "Recon Tools" "${RECON_PACKAGES[@]:-theharvester recon-ng dnsrecon}"
    fi
    
    if [[ "$SKIP_ADDITIONAL" != "true" ]]; then
        install_tool_group "Additional Tools" "${ADDITIONAL_PACKAGES[@]:-nikto gobuster metasploit sqlmap volatility}"
    fi
    
    generate_readme
    
    log_info "=== Tools Installation Complete ==="
    echo
    echo "Summary:"
    echo "  User: $TARGET_USER"
    echo "  Working Directory: $WORKDIR"
    echo
    echo "Next steps:"
    echo "  - Run ./install-nvidia.sh for GPU acceleration (optional)"
    echo "  - Check $WORKDIR for your tools"
    echo
}

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
2. Run \`install-core.sh\` to set up zsh/oh-my-zsh and BlackArch repo.
3. Run \`install-tools.sh\` to install tools and configure user.
4. (Optional) Run \`install-nvidia.sh\` for GPU acceleration.

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
Run \`pacman -Syu\` to update Arch and BlackArch packages.

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
    
    echo "$readme_content" | sudo tee "$WORKDIR/README.md" > /dev/null
    sudo chown "$TARGET_USER:$TARGET_USER" "$WORKDIR/README.md"
}

main "$@"
