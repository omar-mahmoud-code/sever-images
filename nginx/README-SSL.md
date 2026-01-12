# Let's Encrypt SSL Certificate Management

## Quick Start

### First Time Setup

1. **Install Certbot** (if not already installed):
```bash
apt update
apt install certbot python3-certbot-nginx -y
```

2. **Make script executable**:
```bash
chmod +x /path/to/renew-ssl.sh
```

3. **Install SSL for a domain**:
```bash
sudo ./renew-ssl.sh --install orcatrack.arqaamtech.com
```

4. **Setup automatic renewal**:
```bash
sudo ./renew-ssl.sh --setup-auto
```

## Usage

### Renew Certificates Manually
```bash
sudo ./renew-ssl.sh --renew
```

### Test Renewal (Dry Run)
```bash
sudo ./renew-ssl.sh --dry-run
```

### Check Certificate Status
```bash
sudo ./renew-ssl.sh --status
```

### Install New Certificate
```bash
sudo ./renew-ssl.sh --install yourdomain.com
```

### Setup Automatic Renewal
```bash
sudo ./renew-ssl.sh --setup-auto
```
This creates:
- Cron job running twice daily (2am and 2pm)
- Systemd timer as backup
- Logs to `/var/log/letsencrypt-renewal.log`

## Environment Variables

You can customize the script behavior:

```bash
# Set custom email for Let's Encrypt notifications
export SSL_EMAIL="your-email@example.com"

# Set custom webroot path
export WEBROOT="/var/www/html"

# Then run the script
sudo -E ./renew-ssl.sh --renew
```

## Certificate Locations

- **Certificates**: `/etc/letsencrypt/live/<domain>/`
  - `fullchain.pem` - Full certificate chain
  - `privkey.pem` - Private key
  - `cert.pem` - Domain certificate
  - `chain.pem` - Intermediate certificates

- **Logs**: 
  - Script logs: `/var/log/letsencrypt-renewal.log`
  - Certbot logs: `/var/log/letsencrypt/`

## Nginx Configuration

After installing a certificate, Certbot automatically updates your Nginx config. Manual example:

```nginx
server {
    listen 443 ssl http2;
    server_name orcatrack.arqaamtech.com;

    ssl_certificate /etc/letsencrypt/live/orcatrack.arqaamtech.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/orcatrack.arqaamtech.com/privkey.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # HSTS (optional but recommended)
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    # Your location blocks...
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name orcatrack.arqaamtech.com;
    return 301 https://$server_name$request_uri;
}
```

## Troubleshooting

### Certificate Renewal Failing

1. **Check logs**:
```bash
tail -f /var/log/letsencrypt-renewal.log
tail -f /var/log/letsencrypt/letsencrypt.log
```

2. **Run dry-run to test**:
```bash
sudo ./renew-ssl.sh --dry-run
```

3. **Verify Nginx config**:
```bash
nginx -t
```

4. **Check port 80 is accessible**:
```bash
curl -I http://yourdomain.com/.well-known/acme-challenge/test
```

### Rate Limits

Let's Encrypt has rate limits:
- 50 certificates per registered domain per week
- 5 duplicate certificates per week
- Always test with `--dry-run` first!

### Force Renewal

Certificates are only renewed if they expire in less than 30 days. To force renewal:

```bash
certbot renew --force-renewal
```

### Multiple Domains

Install certificate for multiple domains:

```bash
certbot --nginx -d domain1.com -d www.domain1.com -d domain2.com
```

## Monitoring

### Check Renewal Timer Status (Systemd)

```bash
systemctl status certbot-renewal.timer
systemctl list-timers | grep certbot
```

### Check Cron Job

```bash
crontab -l | grep renew-ssl
```

### View Recent Renewals

```bash
grep "Certificate renewed" /var/log/letsencrypt-renewal.log
```

## Certificate Expiry Alerts

Certbot automatically sends expiry warnings to the email address you provided during setup. Monitor these emails!

You can also manually check expiry:

```bash
sudo ./renew-ssl.sh --status
```

Or directly:

```bash
echo | openssl s_client -servername orcatrack.arqaamtech.com -connect orcatrack.arqaamtech.com:443 2>/dev/null | openssl x509 -noout -dates
```

## Best Practices

1. **Always test first**: Use `--dry-run` before actual renewal
2. **Monitor logs**: Check `/var/log/letsencrypt-renewal.log` regularly
3. **Backup certificates**: Keep backups of `/etc/letsencrypt/`
4. **Test after renewal**: Verify HTTPS works after renewal
5. **Set up monitoring**: Use external monitoring to check certificate expiry

## Manual Certbot Commands

### List all certificates
```bash
certbot certificates
```

### Revoke a certificate
```bash
certbot revoke --cert-path /etc/letsencrypt/live/domain.com/cert.pem
```

### Delete a certificate
```bash
certbot delete --cert-name domain.com
```

### Expand certificate (add more domains)
```bash
certbot --nginx -d existing.com -d new.com --expand
```

## Support

For issues with:
- **Certbot**: https://certbot.eff.org/docs/
- **Let's Encrypt**: https://letsencrypt.org/docs/
- **Rate Limits**: https://letsencrypt.org/docs/rate-limits/
