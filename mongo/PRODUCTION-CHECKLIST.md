# MongoDB Production Deployment Checklist

## Pre-Deployment

### Security
- [ ] Change all default passwords in `.env` file
  - [ ] `MONGO_ROOT_PASSWORD`
  - [ ] `MONGO_APP_PASSWORD`
  - [ ] `MONGO_BACKUP_PASSWORD`
  - [ ] `MONGO_MONITORING_PASSWORD`
  - [ ] `MONGOEXPRESS_PASSWORD`
- [ ] Update passwords in `mongo-init/01-init-users.js`
- [ ] Review and adjust user roles/permissions
- [ ] Verify port binding is `127.0.0.1:27017` (not `0.0.0.0`)
- [ ] Disable or properly secure Mongo Express (remove `--profile admin`)
- [ ] Configure firewall rules (UFW/iptables)
- [ ] Enable TLS/SSL if exposing externally
- [ ] Set up VPN/SSH tunnel for remote access

### Configuration
- [ ] Review `mongod.conf` settings
- [ ] Adjust WiredTiger cache size based on available RAM
- [ ] Set appropriate connection limits
- [ ] Configure logging verbosity
- [ ] Set up log rotation
- [ ] Review and adjust resource limits in `docker-compose.yml`
  - [ ] CPU limits
  - [ ] Memory limits
  - [ ] Disk I/O limits

### Network
- [ ] Ensure `central-net` network exists
- [ ] Verify network isolation
- [ ] Configure proper DNS resolution
- [ ] Test connectivity from application servers

### Storage
- [ ] Verify volume mount points
- [ ] Ensure sufficient disk space (minimum 20GB, recommended 100GB+)
- [ ] Set up disk monitoring alerts
- [ ] Configure volume backup strategy
- [ ] Test volume permissions

## Deployment

### Initial Setup
```bash
# 1. Create network
docker network create central-net

# 2. Copy and configure environment
cp .env.example .env
nano .env

# 3. Update initialization scripts
nano mongo-init/01-init-users.js

# 4. Start MongoDB
./manage.sh start

# 5. Wait for initialization (30-60 seconds)
sleep 60

# 6. Run health check
./manage.sh health

# 7. Test connection
./manage.sh shell
```

### Verification
- [ ] Health check passes
- [ ] Can connect with root user
- [ ] Can connect with application user
- [ ] All databases created successfully
- [ ] Indexes created correctly
- [ ] Test application connectivity
- [ ] Verify authentication works
- [ ] Check resource usage is within limits

## Post-Deployment

### Monitoring Setup
- [ ] Configure automated health checks
- [ ] Set up monitoring dashboard (Grafana/Prometheus)
- [ ] Configure alerting (disk space, connections, memory)
- [ ] Set up log aggregation (ELK/Loki)
- [ ] Configure uptime monitoring
- [ ] Set up performance monitoring

### Backup Configuration
- [ ] Test manual backup: `./manage.sh backup`
- [ ] Verify backup file created
- [ ] Test restore process on copy
- [ ] Set up automated backups (cron)
  ```bash
  crontab -e
  # Daily at 2 AM
  0 2 * * * /path/to/mongo/backup.sh >> /var/log/mongodb-backup.log 2>&1
  ```
- [ ] Configure backup retention policy
- [ ] Set up offsite backup storage (S3/GCS)
- [ ] Test backup notifications
- [ ] Document restore procedure

### Security Hardening
- [ ] Run security audit: `docker scan mongodb`
- [ ] Enable audit logging if required
- [ ] Configure IP whitelisting
- [ ] Set up intrusion detection
- [ ] Review and lock down user permissions
- [ ] Disable unnecessary features
- [ ] Configure rate limiting
- [ ] Set up SSL/TLS certificates

### Documentation
- [ ] Document connection strings (securely)
- [ ] Create runbook for common operations
- [ ] Document troubleshooting procedures
- [ ] Create incident response plan
- [ ] Document backup/restore procedures
- [ ] Create disaster recovery plan
- [ ] Update team wiki/knowledge base

### Performance Tuning
- [ ] Run baseline performance tests
- [ ] Configure appropriate indexes
- [ ] Enable query profiling
- [ ] Review slow query log
- [ ] Optimize WiredTiger cache
- [ ] Adjust connection pool settings
- [ ] Configure read preferences
- [ ] Test under load

## Ongoing Maintenance

### Daily
- [ ] Check health status
- [ ] Review logs for errors
- [ ] Monitor resource usage
- [ ] Verify backups completed

### Weekly
- [ ] Review performance metrics
- [ ] Check slow query log
- [ ] Verify backup integrity
- [ ] Review security logs
- [ ] Check disk space trends

### Monthly
- [ ] Test restore procedure
- [ ] Review and optimize indexes
- [ ] Update documentation
- [ ] Review user permissions
- [ ] Plan capacity upgrades
- [ ] Security patches review

### Quarterly
- [ ] Full disaster recovery test
- [ ] Performance audit
- [ ] Security audit
- [ ] Review and update procedures
- [ ] Team training/knowledge transfer
- [ ] Capacity planning review

## Emergency Procedures

### If MongoDB Won't Start
```bash
# 1. Check logs
docker-compose logs mongodb

# 2. Check disk space
df -h

# 3. Check permissions
ls -la /var/lib/docker/volumes/

# 4. Try safe mode
docker-compose down
docker-compose up -d

# 5. If still failing, restore from backup
```

### If Performance Degrades
```bash
# 1. Check current operations
./manage.sh shell
db.currentOp()

# 2. Kill slow operations if needed
db.killOp(<opid>)

# 3. Check indexes
db.collection.getIndexes()

# 4. Review slow queries
db.system.profile.find().sort({ts:-1}).limit(10)
```

### If Disk Space Critical
```bash
# 1. Check database sizes
./manage.sh shell
db.adminCommand("listDatabases")

# 2. Compact collections if needed
db.runCommand({compact: 'collection_name'})

# 3. Remove old logs
docker exec mongodb find /var/log/mongodb -type f -mtime +7 -delete

# 4. Clean old backups
find /backups/mongodb -type f -mtime +30 -delete
```

## Rollback Procedure

If deployment fails:

```bash
# 1. Stop new deployment
docker-compose down

# 2. Restore previous configuration
git checkout HEAD~1 docker-compose.yml mongod.conf

# 3. Restore from backup if needed
./restore.sh /backups/mongodb/last_good_backup.tar.gz

# 4. Start with old configuration
docker-compose up -d

# 5. Verify functionality
./manage.sh health
```

## Support Contacts

- **Team Lead**: [Name/Email]
- **DBA**: [Name/Email]
- **DevOps**: [Name/Email]
- **On-Call**: [Phone/Pager]

## Additional Resources

- [MongoDB Production Checklist](https://docs.mongodb.com/manual/administration/production-checklist-operations/)
- [Security Checklist](https://docs.mongodb.com/manual/administration/security-checklist/)
- Internal Wiki: [Link]
- Runbook: [Link]
- Monitoring Dashboard: [Link]

---

**Last Updated**: 2026-01-12
**Version**: 1.0.0
**Reviewed By**: [Name]
