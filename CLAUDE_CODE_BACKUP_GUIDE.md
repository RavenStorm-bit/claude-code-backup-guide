# Claude Code Backup and Migration Guide

## Overview

This guide provides a comprehensive approach to backing up and migrating Claude Code installations, focusing exclusively on Claude Code configuration files and dependencies. This documentation is based on real-world experience migrating Claude Code between systems.

## What Needs to Be Backed Up

### Core Configuration Files

1. **`.claude.json`** (Required)
   - Location: `~/.claude.json`
   - Contains: User settings, MCP server configurations, oauth account info, project configurations
   - Size: Typically 500KB-1MB
   - Permissions: 644

2. **`.claude/` directory** (Required)
   - Location: `~/.claude/`
   - Contains:
     - `.credentials.json` - Authentication tokens (permission: 600)
     - `__store.db` - Conversation history and state
     - `settings.local.json` - Local environment settings
     - `projects/` - Project-specific configurations
     - `todos/` - Task management data
     - `statsig/` - Feature flags and analytics

### Modified System Files

3. **`cli.js`** (If customized)
   - Location: `$(npm root -g)/@anthropic-ai/claude-code/cli.js`
   - Purpose: Main CLI entry point (often modified for timeout adjustments)
   - Backup reason: Custom modifications like increased command timeouts

## Backup Process

### Step 1: Identify Claude Code Installation

```bash
# Find global npm root
npm root -g

# Typical locations:
# - /usr/lib/node_modules (system-wide)
# - ~/.nvm/versions/node/vX.X.X/lib/node_modules (nvm)
```

### Step 2: Create Backup Script

```bash
#!/bin/bash

# Claude Code Backup Script
BACKUP_DIR="claude_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup configuration files
cp ~/.claude.json "$BACKUP_DIR/"
cp -r ~/.claude "$BACKUP_DIR/"

# Backup modified cli.js if it exists
CLAUDE_PATH=$(npm root -g)/@anthropic-ai/claude-code
if [ -f "$CLAUDE_PATH/cli.js" ]; then
    mkdir -p "$BACKUP_DIR/modified"
    cp "$CLAUDE_PATH/cli.js" "$BACKUP_DIR/modified/"
fi

# Create backup info
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Claude Code Backup
Created: $(date)
Node Version: $(node --version)
NPM Version: $(npm --version)
Claude Version: $(claude --version 2>/dev/null || echo "Not available")
EOF

# Create tarball
tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "Backup created: ${BACKUP_DIR}.tar.gz"
```

### Step 3: Verify Backup Contents

```bash
# List backup contents
tar -tzf claude_backup_*.tar.gz

# Expected structure:
# claude_backup_TIMESTAMP/
# ├── .claude.json
# ├── .claude/
# │   ├── .credentials.json
# │   ├── __store.db
# │   ├── settings.local.json
# │   ├── projects/
# │   ├── todos/
# │   └── statsig/
# ├── modified/
# │   └── cli.js (if customized)
# └── backup_info.txt
```

## Migration Process

### Prerequisites on Target System

1. **Install Node.js** (v18.x or newer)
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. **Install Claude Code**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

### Restoration Steps

1. **Extract Backup**
   ```bash
   tar -xzf claude_backup_TIMESTAMP.tar.gz
   cd claude_backup_TIMESTAMP
   ```

2. **Restore Configuration Files**
   ```bash
   # Create .claude directory if it doesn't exist
   mkdir -p ~/.claude
   
   # Copy configuration files
   cp .claude.json ~/
   cp -r .claude/* ~/.claude/
   
   # Fix permissions
   chmod 600 ~/.claude/.credentials.json
   ```

3. **Replace Modified Files (if applicable)**
   ```bash
   # If cli.js was customized
   if [ -f modified/cli.js ]; then
       CLAUDE_PATH=$(npm root -g)/@anthropic-ai/claude-code
       cp "$CLAUDE_PATH/cli.js" "$CLAUDE_PATH/cli.js.original"
       cp modified/cli.js "$CLAUDE_PATH/cli.js"
   fi
   ```

## Important Considerations

### Authentication
- OAuth tokens in `.credentials.json` may expire
- You might need to re-authenticate after migration
- Run `claude` and follow prompts if authentication fails

### File Permissions
- `.credentials.json` must have 600 permissions
- Other files typically use 644 permissions
- Directories use 755 permissions

### Path Dependencies
- Some configurations may contain absolute paths
- Review `.claude.json` for path-specific settings
- Update paths if the username or directory structure differs

### Version Compatibility
- Ensure Node.js versions are compatible
- Claude Code version differences may affect configuration
- Test thoroughly after migration

## Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```
   Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'better-sqlite3'
   ```
   Solution: Reinstall Claude Code or specific packages
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **Permission Errors**
   ```
   Error: EACCES: permission denied
   ```
   Solution: Fix file permissions
   ```bash
   chmod 600 ~/.claude/.credentials.json
   chmod 755 ~/.claude
   ```

3. **Authentication Failures**
   - Delete `.credentials.json` and re-authenticate
   - Check network connectivity
   - Verify account status

### Verification Steps

1. **Check Installation**
   ```bash
   claude --version
   ```

2. **Verify Configuration**
   ```bash
   ls -la ~/.claude*
   ```

3. **Test Functionality**
   - Start Claude: `claude`
   - Check settings: `/config`
   - List projects: `/project`

## Best Practices

1. **Regular Backups**
   - Backup before major changes
   - Include in system backup routines
   - Store backups securely

2. **Documentation**
   - Document custom modifications
   - Keep backup logs
   - Note environment specifics

3. **Testing**
   - Test restoration process periodically
   - Verify in isolated environment first
   - Check all features after migration

## Security Considerations

- Never share `.credentials.json` publicly
- Encrypt backups containing sensitive data
- Use secure transfer methods (SSH/SCP)
- Regularly rotate authentication tokens

## Automation

### Backup Automation Script

```bash
#!/bin/bash
# Add to crontab for regular backups

BACKUP_DIR="/path/to/backups"
RETENTION_DAYS=30

# Create backup
./claude_backup.sh

# Move to backup directory
mv claude_backup_*.tar.gz "$BACKUP_DIR/"

# Clean old backups
find "$BACKUP_DIR" -name "claude_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
```

## Conclusion

Proper backup and migration of Claude Code requires attention to configuration files, permissions, and custom modifications. Following this guide ensures a smooth transition between systems while maintaining all settings and customizations.

For updates and contributions, visit: https://github.com/YOUR_USERNAME/claude-code-backup-guide