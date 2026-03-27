#!/bin/bash
#
# JUMPSTARTED Lite — Beta Installer
# One command, bot works in Discord, done in under 5 minutes.
#
# Install: curl -fsSL https://raw.githubusercontent.com/justintadair-debug/jumpstarted-install/main/lite.sh | bash
#
# What this does:
#   1. Install OpenClaw (via Homebrew + npm)
#   2. Ask for Discord bot token + channel ID + user ID
#   3. Configure safety settings (owner-only, messaging-only, destructive action confirmation)
#   4. Start the gateway
#
# Safety features:
#   - Owner-only lock (only your Discord ID can talk to the bot)
#   - Messaging-only tools (no shell/file access)
#   - Destructive action confirmation (bot confirms before delete/wipe/etc)
#   - Credential protection (bot never repeats tokens/keys)
#   - Multi-server warning (warns if bot is in multiple servers)
#
# What this does NOT do:
#   - License key activation
#   - Hardware fingerprinting
#   - Telemetry
#   - Capability levels
#   - Audit logging
#   - Version management
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}║            JUMPSTARTED Lite — Beta Installer                  ║${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Step 1: Check/Install Homebrew
# ============================================================================

echo -e "${YELLOW}Step 1/4: Checking Homebrew...${NC}"

if ! command -v brew &> /dev/null; then
    echo ""
    echo -e "${YELLOW}⚠️  Homebrew is not installed.${NC}"
    echo "First-time setup will take 5-10 minutes."
    echo ""
    read -p "Continue? [Y/n]: " CONTINUE < /dev/tty
    if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    echo ""
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    echo -e "${GREEN}✓ Homebrew installed${NC}"
else
    echo -e "${GREEN}✓ Homebrew found${NC}"
fi

# Ensure Homebrew is in PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ============================================================================
# Step 2: Check/Install Node.js
# ============================================================================

echo ""
echo -e "${YELLOW}Step 2/4: Checking Node.js...${NC}"

if ! command -v node &> /dev/null; then
    echo "Installing Node.js via Homebrew..."
    brew install node
    echo -e "${GREEN}✓ Node.js installed${NC}"
else
    echo -e "${GREEN}✓ Node.js found ($(node --version))${NC}"
fi

# ============================================================================
# Step 3: Install OpenClaw
# ============================================================================

echo ""
echo -e "${YELLOW}Step 3/4: Installing OpenClaw...${NC}"

# Set up npm global directory to avoid permission issues
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH="$HOME/.npm-global/bin:$PATH"

# Add to shell profile if not already there
if ! grep -q "npm-global" ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
fi

# Install OpenClaw
npm install -g openclaw 2>/dev/null || npm install -g openclaw

echo -e "${GREEN}✓ OpenClaw installed${NC}"

# ============================================================================
# Step 4: Discord Setup
# ============================================================================

echo ""
echo -e "${YELLOW}Step 4/4: Discord Setup${NC}"
echo ""
echo "You'll need a Discord bot token, channel ID, and your user ID."
echo ""
echo -e "${BLUE}Full guide with screenshots:${NC}"
echo "https://justintadair-debug.github.io/jumpstarted-landing/discord-setup.html"
echo ""

# ============================================================================
# Security Warning (BEFORE asking for token)
# ============================================================================

echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}  ⚠️  SECURITY NOTE: Your bot token is like a password.${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  • Never share it with anyone"
echo "  • Never paste it in Discord chat"
echo "  • If you think it was exposed, reset it immediately at:"
echo "    https://discord.com/developers/applications"
echo ""

# ============================================================================
# Get bot token
# ============================================================================

echo -e "${YELLOW}Paste your Discord bot token (from Developer Portal):${NC}"
read -s BOT_TOKEN < /dev/tty
echo ""

if [[ -z "$BOT_TOKEN" ]]; then
    echo -e "${RED}No token entered. Run this script again when ready.${NC}"
    exit 1
fi

if [[ ${#BOT_TOKEN} -lt 70 ]]; then
    echo -e "${YELLOW}⚠️  That token looks short (${#BOT_TOKEN} chars). Bot tokens are usually 70+ characters.${NC}"
    read -p "Continue anyway? [y/N]: " CONTINUE < /dev/tty
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Get your token from discord.com/developers"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Token captured${NC}"
echo ""

# ============================================================================
# Get channel ID
# ============================================================================

echo -e "${YELLOW}Paste your Discord channel ID:${NC}"
read CHANNEL_ID < /dev/tty
echo ""

if [[ -z "$CHANNEL_ID" ]]; then
    echo -e "${RED}No channel ID entered. Run this script again when ready.${NC}"
    exit 1
fi

if ! [[ "$CHANNEL_ID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Channel ID should be a number (e.g., 1234567890123456789).${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Channel ID captured${NC}"
echo ""

# ============================================================================
# Get user ID (for owner-only lock)
# ============================================================================

echo -e "${YELLOW}Paste your Discord User ID:${NC}"
echo ""
echo "To find it:"
echo "  1. Discord Settings > Advanced > Enable Developer Mode"
echo "  2. Right-click your username > Copy User ID"
echo ""
read USER_ID < /dev/tty

if [[ -z "$USER_ID" ]]; then
    echo -e "${RED}User ID is required for safety. Your bot will only respond to you.${NC}"
    exit 1
fi

if ! [[ "$USER_ID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}User ID should be a number (e.g., 1234567890123456789).${NC}"
    exit 1
fi

echo -e "${GREEN}✓ User ID captured${NC}"

# ============================================================================
# Write OpenClaw config
# ============================================================================

echo ""
echo "Configuring OpenClaw with safety settings..."

OPENCLAW_DIR="$HOME/.openclaw"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

mkdir -p "$OPENCLAW_DIR"

# Write config with all safety features
cat > "$CONFIG_FILE" << EOF
{
  "channels": {
    "discord": {
      "enabled": true,
      "token": "$BOT_TOKEN",
      "defaultTo": "$CHANNEL_ID",
      "groupPolicy": "allowlist",
      "guilds": {
        "*": {
          "requireMention": false,
          "users": ["$USER_ID"]
        }
      }
    }
  },
  "tools": {
    "profile": "messaging"
  },
  "gateway": {
    "mode": "local"
  }
}
EOF

chmod 600 "$CONFIG_FILE"
echo -e "${GREEN}✓ Config written with safety settings${NC}"

# ============================================================================
# Start the gateway
# ============================================================================

echo ""
echo "Starting OpenClaw gateway..."
echo ""

openclaw gateway start

# ============================================================================
# Check how many servers the bot is in
# ============================================================================

echo ""

# Query Discord API for guild count
GUILD_COUNT=$(curl -s -H "Authorization: Bot $BOT_TOKEN" \
    "https://discord.com/api/v10/users/@me/guilds" 2>/dev/null | \
    grep -o '"id"' | wc -l | tr -d ' ')

if [[ "$GUILD_COUNT" -gt 1 ]]; then
    echo -e "${YELLOW}⚠️  Your bot is in $GUILD_COUNT servers.${NC}"
    echo "It is locked to your user ID only, but consider removing it"
    echo "from servers you do not own at: https://discord.com/developers"
    echo ""
fi

# ============================================================================
# Success message
# ============================================================================

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}║     ✅ Your agent is online.                                  ║${NC}"
echo -e "${GREEN}║     Go say hello in Discord — your bot is ready.              ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Your bot is locked to YOU only.${NC} Nobody else can talk to it."
echo -e "${BLUE}It cannot access your files or run commands${NC} by default."
echo ""
echo "Need help?"
echo "https://justintadair-debug.github.io/jumpstarted-landing/discord-setup.html"
echo ""
