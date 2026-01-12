# MongoDB Production Setup

Production-ready MongoDB Docker Compose setup with security hardening, monitoring, backup/restore capabilities, and performance optimization.

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Security](#security)
- [Backup & Restore](#backup--restore)
- [Monitoring](#monitoring)
- [Performance Tuning](#performance-tuning)
- [Troubleshooting](#troubleshooting)

## ✨ Features

- **Production-ready configuration** with security best practices
- **Health checks** for container orchestration
- **Resource limits** to prevent resource exhaustion
- **Automated backups** with retention policy
- **User initialization** with role-based access control
- **Performance tuning** for optimal operation
- **Logging** with rotation
- **Mongo Express** for optional web-based administration

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Create external network (if not exists)
docker network create central-net

# Copy environment file
cp .env.example .env

# IMPORTANT: Edit .env and change all passwords
nano .env

# Make scripts executable
chmod +x backup.sh restore.sh healthcheck.sh

# Update initialization scripts with your passwords
nano mongo-init/01-init-users.js
```

### 2. Start MongoDB

```bash
# Start MongoDB only
docker-compose up -d mongodb

# Start MongoDB + Mongo Express (admin UI)
docker-compose --profile admin up -d

# Check logs
docker-compose logs -f mongodb

# Wait for initialization (first start takes ~30 seconds)
sleep 30
```

### 3. Verify Installation

```bash
# Run health check
./healthcheck.sh

# Connect to MongoDB shell
docker exec -it mongodb mongosh -u root -p Admin@2014 --authenticationDatabase admin

# Test connection from host
mongosh "mongodb://root:Admin@2014@localhost:27017/admin"
```

## ⚙️ Configuration

### Environment Variables

Key environment variables in `.env`:

```bash
MONGO_ROOT_USERNAME=root
MONGO_ROOT_PASSWORD=CHANGE_THIS_STRONG_PASSWORD
MONGO_APP_USERNAME=orcatrack_app
MONGO_APP_PASSWORD=CHANGE_THIS_APP_PASSWORD
WIREDTIGER_CACHE_SIZE_GB=1.5
MAX_CONNECTIONS=1000
```

### MongoDB Configuration File

`mongod.conf` provides fine-grained control:

- **Network**: Binding, ports, compression
- **Security**: Authentication, authorization
- **Storage**: WiredTiger cache, journal, compression
- **Logging**: Verbosity, rotation
- **Performance**: Connection pooling, profiling

Edit `mongod.conf` and restart: `docker-compose restart mongodb`

### Resource Limits

Adjust in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
```

## 🔒 Security

### Initial Security Checklist

- [ ] Change all default passwords in `.env` and init scripts
- [ ] Review user roles in `mongo-init/01-init-users.js`
- [ ] Ensure port binding is `127.0.0.1:27017` (not exposed publicly)
- [ ] Remove or secure Mongo Express in production
- [ ] Enable TLS/SSL for external connections
- [ ] Configure firewall rules
- [ ] Regular security updates: `docker-compose pull && docker-compose up -d`

### User Roles

| User | Role | Purpose |
|------|------|---------|
| `root` | Root | Full admin access (use sparingly) |
| `orcatrack_app` | readWrite, dbAdmin | Application database access |
| `backup_user` | backup, restore | Backup operations only |
| `monitoring_user` | clusterMonitor | Monitoring tools access |

### Connection Strings

```bash
# Application (use this in your app)
mongodb://orcatrack_app:PASSWORD@localhost:27017/orcatrack?authSource=orcatrack

# Admin (for maintenance)
mongodb://root:PASSWORD@localhost:27017/admin?authSource=admin

# Backup (for backup scripts)
mongodb://backup_user:PASSWORD@localhost:27017/admin?authSource=admin
```

## 💾 Backup & Restore

### Automated Backups

Set up cron job for automated backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/mongo/backup.sh >> /var/log/mongodb-backup.log 2>&1

# Add weekly full backup on Sunday at 3 AM
0 3 * * 0 /path/to/mongo/backup.sh >> /var/log/mongodb-backup.log 2>&1
```

### Manual Backup

```bash
# Backup all databases
./backup.sh

# Backup specific database
./backup.sh orcatrack

# Backups stored in /backups/mongodb/
ls -lh /backups/mongodb/
```

### Restore from Backup

```bash
# Restore all databases
./restore.sh /backups/mongodb/all_databases_20260112_020000.tar.gz

# Restore specific database
./restore.sh /backups/mongodb/orcatrack_20260112_020000.tar.gz orcatrack
```

### Backup to Cloud Storage

Uncomment in `backup.sh`:

```bash
# AWS S3
aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "s3://your-bucket/mongodb-backups/"

# Google Cloud Storage
gsutil cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "gs://your-bucket/mongodb-backups/"
```

## 📊 Monitoring

### Health Check

```bash
# Run comprehensive health check
./healthcheck.sh

# Docker health status
docker inspect --format='{{.State.Health.Status}}' mongodb
```

### Performance Metrics

```bash
# Connect to MongoDB shell
docker exec -it mongodb mongosh -u root -p Admin@2014 --authenticationDatabase admin

# Server status
db.serverStatus()

# Current operations
db.currentOp()

# Database statistics
db.stats()

# Collection statistics
db.collection_name.stats()

# Index usage
db.collection_name.aggregate([{$indexStats: {}}])

# Slow queries
db.system.profile.find().pretty()
```

### Mongo Express (Web UI)

Access at: http://localhost:8081

- Only available with `--profile admin` flag
- **Never expose to public internet** (localhost binding)
- Protected with basic auth
- Useful for development/staging

```bash
# Start with admin UI
docker-compose --profile admin up -d

# Stop admin UI
docker-compose stop mongo-express
```

### External Monitoring Tools

Connect with:
- **MongoDB Compass**: `mongodb://root:PASSWORD@localhost:27017`
- **Prometheus MongoDB Exporter**: Use `monitoring_user` credentials
- **Grafana**: Import MongoDB dashboard templates

## 🚄 Performance Tuning

### WiredTiger Cache

Default: 1.5GB (configured in `docker-compose.yml` and `mongod.conf`)

Rule of thumb: (RAM - 1GB) / 2

```bash
# For 8GB RAM server
--wiredTigerCacheSizeGB=3.5

# For 16GB RAM server
--wiredTigerCacheSizeGB=7.5
```

### Connection Pooling

- Max connections: 1000 (adjust based on your workload)
- Connection timeout: 30 seconds
- Pool size per host: 200

### Indexes

```javascript
// Create compound index
db.collection.createIndex({ field1: 1, field2: -1 })

// Background index creation (non-blocking)
db.collection.createIndex({ field: 1 }, { background: true })

// Check index usage
db.collection.aggregate([{$indexStats: {}}])

// Remove unused indexes
db.collection.dropIndex("index_name")
```

### Profiling

Configured to log queries slower than 100ms:

```javascript
// View slow queries
db.system.profile.find({ millis: { $gt: 100 } }).sort({ ts: -1 }).limit(10)

// Change profiling level
db.setProfilingLevel(2) // Log all operations (use carefully)
db.setProfilingLevel(1, { slowms: 50 }) // Log operations > 50ms
db.setProfilingLevel(0) // Disable profiling
```

## 🔧 Troubleshooting

### Common Issues

#### Container won't start

```bash
# Check logs
docker-compose logs mongodb

# Verify network exists
docker network ls | grep central-net
docker network create central-net

# Check permissions
docker-compose down -v
docker-compose up -d
```

#### Authentication failures

```bash
# Verify credentials in .env match init scripts
cat .env
cat mongo-init/01-init-users.js

# Rebuild with fresh database
docker-compose down -v
docker-compose up -d
```

#### Performance issues

```bash
# Check resource usage
docker stats mongodb

# Increase cache size in mongod.conf
# Adjust ulimits in docker-compose.yml
# Check slow query log

# Verify indexes
docker exec -it mongodb mongosh -u root -p PASSWORD --authenticationDatabase admin
db.collection.getIndexes()
```

#### Connection refused

```bash
# Check if container is healthy
docker ps
./healthcheck.sh

# Verify port binding
netstat -tuln | grep 27017

# Test local connection
docker exec -it mongodb mongosh --eval "db.adminCommand('ping')"
```

### Logs

```bash
# View real-time logs
docker-compose logs -f mongodb

# View MongoDB logs inside container
docker exec mongodb tail -f /var/log/mongodb/mongod.log

# Export logs
docker-compose logs mongodb > mongodb-logs.txt
```

### Reset Everything

```bash
# ⚠️ WARNING: This deletes ALL data

# Stop and remove containers + volumes
docker-compose down -v

# Remove network (if needed)
docker network rm central-net

# Start fresh
docker network create central-net
docker-compose up -d
```

## 📚 Additional Resources

- [MongoDB Production Notes](https://docs.mongodb.com/manual/administration/production-notes/)
- [Security Checklist](https://docs.mongodb.com/manual/administration/security-checklist/)
- [Performance Best Practices](https://docs.mongodb.com/manual/administration/analyzing-mongodb-performance/)
- [Backup Methods](https://docs.mongodb.com/manual/core/backups/)

## 📝 License

This configuration is provided as-is for production use.

## 🤝 Contributing

Improvements and suggestions welcome! Test thoroughly before deploying to production.
