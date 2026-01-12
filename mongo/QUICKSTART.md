# MongoDB Docker Setup - Quick Start Guide

## 📦 What's Included

Your MongoDB setup now includes:

```
mongo/
├── docker-compose.yml          # Main configuration
├── mongod.conf                 # MongoDB server config
├── .env.example               # Environment template
├── mongo-init/                # Initialization scripts
│   └── 01-init-users.js       # User creation script
├── manage.sh                  # Quick management commands ⭐
├── backup.sh                  # Automated backup script
├── restore.sh                 # Restore from backup
├── healthcheck.sh             # Health monitoring
├── README.md                  # Full documentation
└── PRODUCTION-CHECKLIST.md    # Deployment guide
```

## 🚀 Quick Start (3 Steps)

### 1. First-Time Setup (5 minutes)

```bash
cd /Users/omar/Desktop/dev/sever-images/mongo

# Create network
docker network create central-net

# Configure passwords (IMPORTANT!)
cp .env.example .env
nano .env  # Change ALL passwords

# Update init script passwords
nano mongo-init/01-init-users.js
```

### 2. Start MongoDB

```bash
# Option A: MongoDB only
./manage.sh start

# Option B: MongoDB + Web Admin UI
./manage.sh start-admin
```

### 3. Verify It Works

```bash
# Run health check
./manage.sh health

# Open MongoDB shell
./manage.sh shell
```

## 🎯 Common Commands

```bash
./manage.sh start          # Start MongoDB
./manage.sh stop           # Stop everything
./manage.sh restart        # Restart MongoDB
./manage.sh logs           # View logs
./manage.sh status         # Check status
./manage.sh health         # Run health check
./manage.sh shell          # MongoDB shell
./manage.sh backup         # Backup all databases
./manage.sh backup mydb    # Backup specific database
./manage.sh restore file   # Restore from backup
```

## 🔌 Connection Strings

### From Your Application
```bash
# Use this in your .env or config
mongodb://orcatrack_app:YOUR_PASSWORD@localhost:27017/orcatrack?authSource=orcatrack
```

### For Admin Access
```bash
mongodb://root:YOUR_PASSWORD@localhost:27017/admin?authSource=admin
```

### From Docker Container
```bash
# If your app is in Docker on central-net
mongodb://orcatrack_app:YOUR_PASSWORD@mongodb:27017/orcatrack?authSource=orcatrack
```

## 🛡️ Security Checklist

Before going to production:

- [ ] Changed all passwords in `.env`
- [ ] Updated passwords in `mongo-init/01-init-users.js`
- [ ] Port bound to `127.0.0.1` (not exposed publicly)
- [ ] Removed or secured Mongo Express
- [ ] Set up automated backups
- [ ] Configured monitoring/alerts
- [ ] Tested restore procedure

See [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md) for full list.

## 📊 What's Different From Basic Setup?

### ✅ Production Features Added

| Feature | Basic | Production |
|---------|-------|------------|
| **Version Pinning** | `mongo:latest` ❌ | `mongo:7.0.14` ✅ |
| **Health Checks** | None ❌ | Automated ✅ |
| **Resource Limits** | None ❌ | CPU/Memory limits ✅ |
| **Security** | Basic ❌ | Hardened ✅ |
| **Backups** | Manual ❌ | Automated scripts ✅ |
| **Monitoring** | None ❌ | Health checks + metrics ✅ |
| **Logging** | Default ❌ | Configured + rotation ✅ |
| **Performance** | Default ❌ | Tuned cache/connections ✅ |
| **User Roles** | Root only ❌ | 4 roles (app/backup/monitoring) ✅ |
| **Init Scripts** | None ❌ | Automated user creation ✅ |

## 🔧 Key Configuration Files

### docker-compose.yml
- Pinned MongoDB version (7.0.14)
- Health checks enabled
- Resource limits (2 CPU, 2GB RAM)
- Log rotation configured
- Security options enabled
- Localhost-only binding

### mongod.conf
- WiredTiger cache optimized (1.5GB)
- Connection pooling configured
- Slow query profiling (>100ms)
- Compression enabled
- Journal optimized
- Security settings

### Users Created Automatically
1. **root** - Full admin (use sparingly)
2. **orcatrack_app** - Application access (use this!)
3. **backup_user** - Backup operations only
4. **monitoring_user** - Metrics collection

## 💾 Backup Strategy

### Automated Backups (Recommended)

```bash
# Set up daily backup at 2 AM
crontab -e

# Add this line:
0 2 * * * /Users/omar/Desktop/dev/sever-images/mongo/backup.sh >> /var/log/mongodb-backup.log 2>&1
```

### Manual Backups

```bash
# Backup everything
./manage.sh backup

# Backup specific database
./manage.sh backup orcatrack

# Backups saved to: /backups/mongodb/
# Retention: 7 days (configurable in backup.sh)
```

### Restore

```bash
./manage.sh restore /backups/mongodb/backup_20260112.tar.gz
```

## 📈 Monitoring

### Quick Health Check
```bash
./manage.sh health
```

This shows:
- ✓ Container running
- ✓ MongoDB responding
- ✓ Authentication working
- Server uptime
- Current connections
- Disk usage
- Database sizes
- Recent slow queries

### Web Interface (Development Only)
```bash
./manage.sh start-admin
# Open: http://localhost:8081
```

### Resource Usage
```bash
./manage.sh status
```

## 🚨 Troubleshooting

### Container won't start?
```bash
# Check logs
./manage.sh logs

# Ensure network exists
docker network create central-net

# Reset everything (⚠️ deletes data)
./manage.sh reset
./manage.sh start
```

### Can't connect?
```bash
# 1. Check if running
./manage.sh status

# 2. Test from container
docker exec -it mongodb mongosh --eval "db.adminCommand('ping')"

# 3. Check credentials match
cat .env
```

### Out of disk space?
```bash
# Check usage
df -h

# Clean old backups
find /backups/mongodb -type f -mtime +30 -delete

# Compact database
./manage.sh shell
use mydb
db.runCommand({compact: 'collection_name'})
```

## 📚 Full Documentation

- [README.md](README.md) - Complete setup guide with all details
- [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md) - Pre-deployment checklist
- [MongoDB Docs](https://docs.mongodb.com/manual/)

## 🎓 Next Steps

1. **Review Security**: Change all default passwords
2. **Test Backup**: Run `./manage.sh backup` and verify file created
3. **Test Restore**: Restore backup to verify it works
4. **Configure Monitoring**: Set up alerts for disk space, connections
5. **Set Up Cron**: Automate daily backups
6. **Document**: Update team wiki with connection details

## 💡 Pro Tips

- Use `orcatrack_app` user in your application (NOT root)
- Keep `.env` out of version control (it's gitignored)
- Test backups regularly - backups you can't restore are useless
- Monitor slow queries: `./manage.sh shell` → `db.system.profile.find()`
- Check health before deployments: `./manage.sh health`
- Bind to `127.0.0.1` in production (not `0.0.0.0`)

## 🆘 Need Help?

1. Check logs: `./manage.sh logs`
2. Run health check: `./manage.sh health`
3. Review [README.md](README.md) for detailed troubleshooting
4. Check MongoDB docs: https://docs.mongodb.com

---

**Setup by**: Docker Compose
**Last updated**: 2026-01-12
**MongoDB version**: 7.0.14
**Ready for**: Development ✅ Staging ✅ Production ✅
