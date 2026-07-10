# AFFiNE Self-Hosted Setup

Personal AFFiNE instance for collaborative planning and knowledge management, backed by Docker Compose with automated OneDrive backups.

## Installation

AFFiNE runs automatically when the `work` profile is activated via chezmoi:

```bash
chezmoi apply
```

This will:
- Download the official AFFiNE docker-compose configuration
- Create required `.env` file with database credentials
- Start postgres, redis, and AFFiNE containers
- Schedule daily backups to OneDrive

## Access

- **Web UI**: http://localhost:13010
- **Admin panel**: http://localhost:13010/admin

## ✅ AFFiNE Backup to OneDrive

### What's automated:
- 📅 Daily backup at 2 PM (via macOS launchd)
- 💾 Backs up: postgres database, storage (files/images), and config
- 📦 Compressed: ~9-10MB tar.gz per backup
- 🗂️ Stored: `~/OneDrive/Backups/affine/affine-backup-YYYYMMDD-HHMMSS.tar.gz`
- 🧹 Auto-cleanup: Keeps only 7 days of backups (saves OneDrive space)
- 📝 Logging: All runs logged to `~/.local/share/affine/backup.log`

### Profile-aware:
- ✅ Only active when `profile: work` is set in chezmoi
- Automatically loads/unloads launchd service with `chezmoi apply`

### Monitor backups:
```bash
tail -f ~/.local/share/affine/backup.log
```

### Manually run backup:
```bash
bash ~/.local/bin/backup-affine.sh
```

### Restore from backup:
```bash
# Extract to a temporary location
tar -xzf ~/OneDrive/Backups/affine/affine-backup-YYYYMMDD-HHMMSS.tar.gz -C /tmp

# Stop AFFiNE
docker compose -f ~/.local/share/affine/docker-compose.yml down

# Restore data
cp -r /tmp/postgres ~/.local/share/affine/
cp -r /tmp/storage ~/.local/share/affine/

# Restart
docker compose -f ~/.local/share/affine/docker-compose.yml up -d
```

## Data Storage

All data is stored locally and persists in Docker volumes:
- **Database**: `~/.local/share/affine/postgres/`
- **Files/uploads**: `~/.local/share/affine/storage/`
- **Configuration**: `~/.local/share/affine/config/`
- **Docker config**: `~/.local/share/affine/.env` and `docker-compose.yml`

## Management

### View logs:
```bash
docker compose -f ~/.local/share/affine/docker-compose.yml logs -f affine
```

### Stop AFFiNE:
```bash
docker compose -f ~/.local/share/affine/docker-compose.yml down
```

### Restart:
```bash
docker compose -f ~/.local/share/affine/docker-compose.yml up -d
```

## Profile-specific behavior

This setup only activates when your chezmoi profile is set to `work`:

```bash
# View current profile
chezmoi data | grep profile

# Switch profiles
chezmoi init --data profile=work
```

When you switch to another profile, the backup service is automatically unloaded and AFFiNE will not be started by chezmoi scripts.
