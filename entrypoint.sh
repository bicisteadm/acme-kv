#!/bin/sh
#
# ACME Certificate Management Script
# Automatically issues and manages SSL certificates using acme.sh
#

# Start nginx in background
echo "[INFO] Starting nginx..."
nginx

set -e

# =============================================================================
# Configuration
# =============================================================================
DOMAINS=${DOMAINS:-"example.com"}
WEBROOT_PATH=${WEBROOT_PATH:-"/webroot"}
ACME_EMAIL=${ACME_EMAIL:-"admin@example.com"}
ACME_ENV=${ACME_ENV:-"prod"}

# =============================================================================
# Functions
# =============================================================================
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# =============================================================================
# Setup ACME Environment
# =============================================================================
log_info "Initializing ACME certificate management..."

if [ "$ACME_ENV" = "staging" ] || [ "$ACME_ENV" = "stag" ]; then
    log_info "Configuring Let's Encrypt STAGING environment"
    acme.sh --set-default-ca --server letsencrypt_test
    ENV_INFO="STAGING"
else
    log_info "Configuring Let's Encrypt PRODUCTION environment"
    acme.sh --set-default-ca --server letsencrypt
    ENV_INFO="PRODUCTION"
fi

log_info "Registering ACME account with email: $ACME_EMAIL [$ENV_INFO]"
acme.sh --register-account -m "$ACME_EMAIL"

# =============================================================================
# Certificate Management
# =============================================================================
log_info "Starting certificate management for domains: $DOMAINS"

# Remove certificates for domains no longer needed
log_info "Checking for unused certificates..."
for CERT_DIR in /acme.sh/*/; do
    if [ -d "$CERT_DIR" ]; then
        CERT_DOMAIN=$(basename "$CERT_DIR")
        
        # Skip system directories
        case "$CERT_DOMAIN" in
            "ca"|"account.conf"|"http.header"|"dnsapi")
                continue
                ;;
        esac
        
        # Extract base domain name (remove _ecc suffix if present)
        BASE_DOMAIN=$(echo "$CERT_DOMAIN" | sed 's/_ecc$//')
        
        # Check if this domain is still needed
        echo "$DOMAINS" | grep -q "$BASE_DOMAIN" || {
            log_info "Removing unused certificate for: $CERT_DOMAIN"
            acme.sh --remove -d "$BASE_DOMAIN" || log_warn "Failed to remove certificate for $CERT_DOMAIN"
        }
    fi
done

# Issue certificates for current domains
for DOMAIN in $DOMAINS; do
    CONF_PATH="/acme.sh/$DOMAIN/$DOMAIN.conf"

    if [ ! -f "$CONF_PATH" ]; then
        log_info "No certificate found for domain: $DOMAIN"
        log_info "Issuing new certificate for: $DOMAIN"

        acme.sh --issue -d "$DOMAIN" --webroot "$WEBROOT_PATH"

        log_info "Installing certificate for: $DOMAIN"
        acme.sh --install-cert -d "$DOMAIN" \
            --cert-file      /acme.sh/$DOMAIN/cert.pem \
            --key-file       /acme.sh/$DOMAIN/key.pem \
            --fullchain-file /acme.sh/$DOMAIN/fullchain.pem \
            --reloadcmd     "/scripts/deploy.sh $DOMAIN"
    else
        log_info "Certificate for domain '$DOMAIN' already exists - skipping issuance"
    fi
done

# =============================================================================
# Certificate Renewal
# =============================================================================
log_info "Running certificate renewal check..."
acme.sh --cron

# =============================================================================
# Completion
# =============================================================================
log_info "Certificate management completed successfully"
