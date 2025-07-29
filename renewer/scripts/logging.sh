#!/bin/sh
#
# Shared logging functions for ACME scripts
#

# =============================================================================
# Logging Configuration
# =============================================================================
LOG_DIR=${LOG_DIR:-"/logs"}
LOG_TO_FILE=${LOG_TO_FILE:-"false"}

# Initialize log file if not already set
if [ -z "$LOG_FILE" ]; then
    LOG_FILE="$LOG_DIR/acme-$(date +%Y%m%d-%H%M%S).log"
fi

# Create log directory if it doesn't exist and file logging is enabled
if [ "$LOG_TO_FILE" = "true" ]; then
    mkdir -p "$LOG_DIR"
fi

# =============================================================================
# Logging Functions
# =============================================================================
log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [INFO] $1"
    echo "$message"
    if [ "$LOG_TO_FILE" = "true" ]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

log_warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [WARN] $1"
    echo "$message"
    if [ "$LOG_TO_FILE" = "true" ]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [ERROR] $1"
    echo "$message" >&2
    if [ "$LOG_TO_FILE" = "true" ]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

# Function to execute acme.sh commands with logging
run_acme_cmd() {
    local exit_code
    if [ "$LOG_TO_FILE" = "true" ]; then
        # Capture both stdout and stderr, display on console and log to file
        {
            acme.sh "$@" 2>&1 | while IFS= read -r line; do
                local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                echo "[$timestamp] [ACME] $line"
                echo "[$timestamp] [ACME] $line" >> "$LOG_FILE"
            done
        }
        exit_code=${PIPESTATUS[0]}
    else
        # Just run normally if file logging is disabled
        acme.sh "$@"
        exit_code=$?
    fi
    return $exit_code
}

# Function to execute any command with logging
run_cmd() {
    local cmd_name="$1"
    shift
    local exit_code
    
    if [ "$LOG_TO_FILE" = "true" ]; then
        # Capture both stdout and stderr, display on console and log to file
        {
            "$@" 2>&1 | while IFS= read -r line; do
                local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                echo "[$timestamp] [$cmd_name] $line"
                echo "[$timestamp] [$cmd_name] $line" >> "$LOG_FILE"
            done
        }
        exit_code=${PIPESTATUS[0]}
    else
        # Just run normally if file logging is disabled
        "$@"
        exit_code=$?
    fi
    return $exit_code
}
