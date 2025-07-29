#!/bin/sh
#
# ACME Certificate Management Script
# Automatically issues and manages SSL certificates using acme.sh
#
set -e

# =============================================================================
# Configuration
# =============================================================================
DOMAINS=${DOMAINS:-""}
WEBROOT_PATH=${WEBROOT_PATH:-"/webroot"}
ACME_EMAIL=${ACME_EMAIL:-""}
ACME_ENV=${ACME_ENV:-"prod"}
LOG_DIR=${LOG_DIR:-"/logs"}
LOG_TO_FILE=${LOG_TO_FILE:-"false"}
LOG_FILE="$LOG_DIR/acme-$(date +%Y%m%d-%H%M%S).log"

# Convert comma-separated domains to space-separated for easier iteration
DOMAINS_LIST=$(echo "$DOMAINS" | tr ',' ' ')

# Load shared logging functions
. /scripts/logging.sh

# =============================================================================
# Validation
# =============================================================================
if [ -z "$DOMAINS" ]; then
    log_error "DOMAINS environment variable is required"
    exit 1
fi

if [ -z "$ACME_EMAIL" ]; then
    log_error "ACME_EMAIL environment variable is required"
    exit 1
fi

# =============================================================================
# Setup ACME Environment
# =============================================================================
log_info "Initializing ACME certificate management..."
if [ "$LOG_TO_FILE" = "true" ]; then
    log_info "Logging to file: $LOG_FILE"
else
    log_info "File logging disabled (LOG_TO_FILE=false)"
fi

if [ "$ACME_ENV" = "staging" ] || [ "$ACME_ENV" = "stag" ]; then
    log_info "Configuring Let's Encrypt STAGING environment"
    run_acme_cmd --set-default-ca --server letsencrypt_test
    ENV_INFO="STAGING"
else
    log_info "Configuring Let's Encrypt PRODUCTION environment"
    run_acme_cmd --set-default-ca --server letsencrypt
    ENV_INFO="PRODUCTION"
fi

log_info "Registering ACME account with email: $ACME_EMAIL [$ENV_INFO]"
run_acme_cmd --register-account -m "$ACME_EMAIL"

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
        echo "$DOMAINS_LIST" | grep -q "$BASE_DOMAIN" || {
            log_info "Removing unused certificate for: $CERT_DOMAIN"
            run_acme_cmd --remove -d "$BASE_DOMAIN" || log_warn "Failed to remove certificate for $CERT_DOMAIN"
        }
    fi
done

# Issue certificates for current domains
for DOMAIN in $DOMAINS_LIST; do
  log_info "Issuing certificate for: $DOMAIN"

  run_acme_cmd --issue -d "$DOMAIN" --webroot "$WEBROOT_PATH"

  log_info "Installing certificate for: $DOMAIN"
  run_acme_cmd --install-cert -d "$DOMAIN" \
      --cert-file      /acme.sh/$DOMAIN/cert.pem \
      --key-file       /acme.sh/$DOMAIN/key.pem \
      --fullchain-file /acme.sh/$DOMAIN/fullchain.pem \
      --reloadcmd     "/scripts/deploy.sh $DOMAIN"
done

# =============================================================================
# Certificate Renewal
# =============================================================================
log_info "Running certificate renewal check..."
run_acme_cmd --cron

# =============================================================================
# Completion
# =============================================================================
log_info "Certificate management completed successfully"
if [ "$LOG_TO_FILE" = "true" ]; then
    log_info "Log file saved to: $LOG_FILE"
fi
exit 0
