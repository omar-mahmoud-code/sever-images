#!/bin/bash

###########################################
# Let's Encrypt SSL Certificate Renewal Script
# Automatically renews SSL certificates and reloads Nginx
###########################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/var/log/letsencrypt-renewal.log"
CERTBOT_BIN=$(which certbot 2>/dev/null || echo "/usr/bin/certbot")
NGINX_BIN=$(which nginx 2>/dev/null || echo "/usr/sbin/nginx")
EMAIL="${SSL_EMAIL:-admin@arqaamtech.com}"
WEBROOT="${WEBROOT:-/var/www/html}"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        error "This script must be run as root"
        exit 1
    fi
}

check_certbot() {
    if ! command -v certbot &> /dev/null; then
        error "Certbot is not installed. Install it with: apt install certbot python3-certbot-nginx"
        exit 1
    fi
    success "Certbot found at $CERTBOT_BIN"
}

check_nginx() {
    if ! command -v nginx &> /dev/null; then
        error "Nginx is not installed"
        exit 1
    fi
    success "Nginx found at $NGINX_BIN"
}

test_nginx_config() {
    log "Testing Nginx configuration..."
    if $NGINX_BIN -t 2>&1 | tee -a "$LOG_FILE"; then
        success "Nginx configuration is valid"
        return 0
    else
        error "Nginx configuration test failed"
        return 1
    fi
}

reload_nginx() {
    log "Reloading Nginx..."
    if systemctl reload nginx 2>&1 | tee -a "$LOG_FILE"; then
        success "Nginx reloaded successfully"
        return 0
    else
        error "Failed to reload Nginx"
        return 1
    fi
}

renew_certificates() {
    log "Starting certificate renewal process..."
    
    # Dry run option
    if [ "$1" = "--dry-run" ]; then
        warning "Running in DRY RUN mode - no actual changes will be made"
        $CERTBOT_BIN renew --dry-run 2>&1 | tee -a "$LOG_FILE"
        return $?
    fi
    
    # Actual renewal
    if $CERTBOT_BIN renew --quiet --agree-tos 2>&1 | tee -a "$LOG_FILE"; then
        success "Certificate renewal completed successfully"
        return 0
    else
        error "Certificate renewal failed"
        return 1
    fi
}

show_certificate_status() {
    log "Current certificate status:"
    echo ""
    $CERTBOT_BIN certificates 2>&1 | tee -a "$LOG_FILE"
    echo ""
}

install_new_certificate() {
    local DOMAIN=$1
    
    if [ -z "$DOMAIN" ]; then
        error "Domain name is required for new certificate installation"
        echo "Usage: $0 --install <domain>"
        exit 1
    fi
    
    log "Installing new certificate for domain: $DOMAIN"
    
    # Check if nginx config exists for domain
    if [ ! -f "/etc/nginx/sites-available/$DOMAIN.conf" ]; then
        warning "Nginx config not found for $DOMAIN. Make sure to create it first."
    fi
    
    # Install certificate using nginx plugin
    $CERTBOT_BIN --nginx -d "$DOMAIN" -d "www.$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        --redirect 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        success "Certificate installed successfully for $DOMAIN"
        test_nginx_config && reload_nginx
    else
        error "Failed to install certificate for $DOMAIN"
        exit 1
    fi
}

setup_auto_renewal() {
    log "Setting up automatic renewal with cron..."
    
    # Create cron job for automatic renewal (twice daily at 2am and 2pm)
    CRON_JOB="0 2,14 * * * /bin/bash $(readlink -f "$0") --renew-only >> $LOG_FILE 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "renew-ssl.sh"; then
        warning "Cron job already exists"
    else
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        success "Cron job added successfully"
    fi
    
    # Also setup systemd timer as alternative
    if command -v systemctl &> /dev/null; then
        cat > /etc/systemd/system/certbot-renewal.timer <<EOF
[Unit]
Description=Let's Encrypt Certificate Renewal Timer

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

        cat > /etc/systemd/system/certbot-renewal.service <<EOF
[Unit]
Description=Let's Encrypt Certificate Renewal
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $(readlink -f "$0") --renew-only
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
EOF

        systemctl daemon-reload
        systemctl enable certbot-renewal.timer
        systemctl start certbot-renewal.timer
        success "Systemd timer configured"
    fi
}

show_help() {
    cat <<EOF
Let's Encrypt SSL Certificate Renewal Script

Usage: $0 [OPTIONS]

OPTIONS:
    --renew              Renew all certificates and reload Nginx
    --renew-only         Renew certificates without reloading (for cron)
    --dry-run            Test renewal without making changes
    --status             Show current certificate status
    --install <domain>   Install new certificate for domain
    --setup-auto         Setup automatic renewal (cron + systemd timer)
    --help               Show this help message

EXAMPLES:
    $0 --renew                          # Renew all certificates
    $0 --dry-run                        # Test renewal process
    $0 --status                         # Check certificate status
    $0 --install orcatrack.arqaamtech.com  # Install new certificate
    $0 --setup-auto                     # Setup automatic renewal

ENVIRONMENT VARIABLES:
    SSL_EMAIL    Email for Let's Encrypt notifications (default: admin@arqaamtech.com)
    WEBROOT      Webroot path for webroot authentication (default: /var/www/html)

EOF
}

# Main script
main() {
    log "=========================================="
    log "Let's Encrypt SSL Renewal Script Started"
    log "=========================================="
    
    case "${1:-}" in
        --renew)
            check_root
            check_certbot
            check_nginx
            show_certificate_status
            renew_certificates
            if [ $? -eq 0 ]; then
                test_nginx_config && reload_nginx
            fi
            ;;
        --renew-only)
            check_root
            check_certbot
            renew_certificates
            if [ $? -eq 0 ]; then
                test_nginx_config && reload_nginx
            fi
            ;;
        --dry-run)
            check_root
            check_certbot
            renew_certificates --dry-run
            ;;
        --status)
            check_root
            check_certbot
            show_certificate_status
            ;;
        --install)
            check_root
            check_certbot
            check_nginx
            install_new_certificate "$2"
            ;;
        --setup-auto)
            check_root
            setup_auto_renewal
            ;;
        --help|-h)
            show_help
            ;;
        *)
            error "Invalid option: ${1:-}"
            echo ""
            show_help
            exit 1
            ;;
    esac
    
    log "Script completed at $(date)"
    log "=========================================="
}

# Run main function
main "$@"
