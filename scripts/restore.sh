#!/bin/bash

# Claude Code Restore Script
# Restores Claude Code configuration from backup

set -e

echo "Claude Code Restore Script"
echo "========================="

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Extract backup to temporary directory
TEMP_DIR=$(mktemp -d)
echo "Extracting backup to temporary directory..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Find the backup directory (it should be the only directory in temp)
BACKUP_DIR=$(find "$TEMP_DIR" -type d -name "claude_backup_*" -print -quit)

if [ -z "$BACKUP_DIR" ]; then
    echo "Error: Could not find backup directory in archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Found backup directory: $(basename $BACKUP_DIR)"

# Check Node.js installation
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js first."
    echo "Run: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "     sudo apt-get install -y nodejs"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check Claude Code installation
if ! command -v claude &> /dev/null; then
    echo "Claude Code is not installed. Installing..."
    npm install -g @anthropic-ai/claude-code
fi

# Restore configuration files
echo "Restoring configuration files..."

# Create .claude directory if it doesn't exist
mkdir -p ~/.claude

# Restore .claude.json
if [ -f "$BACKUP_DIR/.claude.json" ]; then
    cp "$BACKUP_DIR/.claude.json" ~/
    echo "✓ Restored .claude.json"
else
    echo "⚠ .claude.json not found in backup"
fi

# Restore .claude directory
if [ -d "$BACKUP_DIR/.claude" ]; then
    cp -r "$BACKUP_DIR/.claude/"* ~/.claude/
    echo "✓ Restored .claude directory"
    
    # Fix permissions for credentials file
    if [ -f ~/.claude/.credentials.json ]; then
        chmod 600 ~/.claude/.credentials.json
        echo "✓ Fixed permissions for .credentials.json"
    fi
else
    echo "⚠ .claude directory not found in backup"
fi

# Restore modified cli.js if it exists
if [ -f "$BACKUP_DIR/modified/cli.js" ]; then
    echo "Found modified cli.js in backup"
    CLAUDE_PATH=$(npm root -g)/@anthropic-ai/claude-code
    
    if [ -d "$CLAUDE_PATH" ]; then
        # Backup original cli.js
        if [ -f "$CLAUDE_PATH/cli.js" ]; then
            cp "$CLAUDE_PATH/cli.js" "$CLAUDE_PATH/cli.js.original"
            echo "✓ Backed up original cli.js"
        fi
        
        # Restore modified cli.js
        cp "$BACKUP_DIR/modified/cli.js" "$CLAUDE_PATH/cli.js"
        echo "✓ Restored modified cli.js"
    else
        echo "⚠ Could not find Claude Code installation directory"
    fi
fi

# Display backup information
if [ -f "$BACKUP_DIR/backup_info.txt" ]; then
    echo ""
    echo "Backup Information:"
    echo "=================="
    cat "$BACKUP_DIR/backup_info.txt"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Restore completed successfully!"
echo "You can now run 'claude' to start Claude Code with your restored configuration."

# Version check
CURRENT_VERSION=$(claude --version 2>/dev/null || echo "Unknown")
echo ""
echo "Current Claude Version: $CURRENT_VERSION"
echo ""
echo "Note: If you experience any authentication issues, you may need to re-authenticate."
echo "Run 'claude' and follow the prompts if needed."