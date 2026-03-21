#!/bin/bash
#
# JUMPSTARTED Bootstrap Installer
# Downloads and installs JUMPSTARTED with one command
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/justintadair-debug/jumpstarted-install/main/bootstrap.sh | bash
#

set -e

# Configuration
VERSION="1.7.4"
GITHUB_REPO="justintadair-debug/jumpstarted-install"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/OPERATOR-${VERSION}.tar.gz"
TEMP_DIR=$(mktemp -d)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║${NC}   ${BLUE}JUMPSTARTED${NC} Bootstrap Installer                              ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}   Your AI team, running 24/7.                                ${BOLD}║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: JUMPSTARTED requires macOS${NC}"
    echo "Linux support coming soon."
    exit 1
fi

# UX FIX 4: Check Homebrew early and warn about install time
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠️  Heads up — Homebrew isn't installed.${NC}"
    echo -e "${YELLOW}   First-time setup will take 5-10 minutes to install it.${NC}"
    echo ""
    read -p "Continue? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Setup cancelled. Install Homebrew manually: https://brew.sh"
        exit 0
    fi
fi

# Check Python 3.9+
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not installed.${NC}"
    echo "Install it with: brew install python@3.12"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [[ "$PYTHON_MAJOR" -lt 3 ]] || [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 9 ]]; then
    echo -e "${RED}Error: Python 3.9+ is required (found $PYTHON_VERSION)${NC}"
    echo "Install it with: brew install python@3.12"
    exit 1
fi
echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION"

# Check curl
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} curl"

# Download JUMPSTARTED
echo ""
# UX FIX 6: Show download time estimate
echo -e "${BLUE}Downloading JUMPSTARTED v${VERSION}...${NC}"
echo -e "  (this may take 10-15 seconds on slow connections)"
cd "$TEMP_DIR"

TARBALL="OPERATOR-${VERSION}.tar.gz"
CHECKSUM_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${TARBALL}.sha256"

# UX FIX 6: Show progress bar
if ! curl -fSL --progress-bar -o "$TARBALL" "$DOWNLOAD_URL"; then
    echo -e "${RED}Error: Failed to download JUMPSTARTED${NC}"
    echo "URL: $DOWNLOAD_URL"
    exit 1
fi
echo -e "${GREEN}✓${NC} Downloaded ${TARBALL}"

# Verify SHA-256 integrity
echo -e "${BLUE}Verifying integrity...${NC}"
if curl -fsSL -o "${TARBALL}.sha256" "$CHECKSUM_URL" 2>/dev/null; then
    if ! shasum -a 256 --check "${TARBALL}.sha256" --status 2>/dev/null; then
        echo -e "${RED}Error: SHA-256 checksum verification failed!${NC}"
        echo -e "${RED}The downloaded file may be corrupted or tampered with.${NC}"
        echo "Expected checksum:"
        cat "${TARBALL}.sha256"
        echo "Actual checksum:"
        shasum -a 256 "$TARBALL"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} SHA-256 checksum verified"
else
    echo -e "${YELLOW}⚠${NC} Checksum file not available — skipping verification"
    echo -e "${YELLOW}  For production use, verify manually from release notes${NC}"
fi

# Extract
echo -e "${BLUE}Extracting...${NC}"
tar -xzf "$TARBALL"
cd "OPERATOR-${VERSION}"
echo -e "${GREEN}✓${NC} Extracted"

# Ensure npm-global is in PATH for installer
export PATH="$HOME/.npm-global/bin:$PATH"

# Show installer source URL before running
echo ""
echo -e "${BLUE}Running installer...${NC}"
echo -e "  Installer source: ${BLUE}https://github.com/${GITHUB_REPO}/blob/main/installer/install.sh${NC}"
echo ""
bash install.sh

echo ""
echo -e "${GREEN}${BOLD}JUMPSTARTED installed successfully!${NC}"
echo ""
echo -e "Start your AI team:  ${BLUE}jmp start${NC}"
echo ""

# Remind user to restart shell if PATH was updated
if [[ -d "$HOME/.npm-global/bin" ]]; then
    echo -e "${YELLOW}Note: If 'jmp' command is not found, restart your terminal or run:${NC}"
    echo -e "  ${BLUE}source ~/.zshrc${NC}  (or ~/.bash_profile)"
    echo ""
fi
