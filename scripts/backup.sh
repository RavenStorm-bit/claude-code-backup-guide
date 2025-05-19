#!/bin/bash

# Claude Code Backup Script
# Creates a complete backup of Claude Code configuration

set -e

echo "Claude Code Backup Script"
echo "========================"

# Create backup directory with timestamp
BACKUP_DIR="claude_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in: $BACKUP_DIR"

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo "Warning: Claude Code command not found in PATH"
fi

# Backup configuration files
echo "Backing up configuration files..."
if [ -f ~/.claude.json ]; then
    cp ~/.claude.json "$BACKUP_DIR/"
    echo "✓ Backed up .claude.json"
else
    echo "⚠ .claude.json not found"
fi

if [ -d ~/.claude ]; then
    cp -r ~/.claude "$BACKUP_DIR/"
    echo "✓ Backed up .claude directory"
else
    echo "⚠ .claude directory not found"
fi

# Backup modified cli.js if it exists
echo "Checking for modified cli.js..."
CLAUDE_PATH=$(npm root -g 2>/dev/null)/@anthropic-ai/claude-code
if [ -f "$CLAUDE_PATH/cli.js" ]; then
    mkdir -p "$BACKUP_DIR/modified"
    cp "$CLAUDE_PATH/cli.js" "$BACKUP_DIR/modified/"
    echo "✓ Backed up cli.js"
else
    echo "⚠ Claude Code cli.js not found at expected location"
fi

# Create backup information file
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Claude Code Backup Information
==============================
Created: $(date)
Hostname: $(hostname)
User: $USER
Node Version: $(node --version 2>/dev/null || echo "Not available")
NPM Version: $(npm --version 2>/dev/null || echo "Not available")
Claude Version: $(claude --version 2>/dev/null || echo "Not available")

Files included:
$(cd "$BACKUP_DIR" && find . -type f | sort)
EOF

# Create tarball
echo "Creating backup archive..."
tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "✓ Backup completed successfully!"
echo "Backup file: ${BACKUP_DIR}.tar.gz"
echo "Size: $(du -h ${BACKUP_DIR}.tar.gz | cut -f1)"