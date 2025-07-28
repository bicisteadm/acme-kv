FROM alpine:3.21

# Create non-root user first
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

# Install system packages
RUN apk --no-cache add -f \
  openssl \
  openssh-client \
  coreutils \
  bind-tools \
  curl \
  sed \
  socat \
  tzdata \
  oath-toolkit-oathtool \
  tar \
  libidn \
  jq \
  cronie \
  bash \
  python3 \
  py3-pip \
  build-base \
  python3-dev \
  linux-headers \
  pipx

# Install Azure CLI globally
RUN pipx install azure-cli && \
    pipx ensurepath && \
    chmod -R 755 /root/.local && \
    ln -s /root/.local/bin/az /usr/local/bin/az

# Set up directories for appuser (don't create .acme.sh - let installer do it)
RUN mkdir -p /acme.sh /scripts && \
    chown -R appuser:appgroup /home/appuser /acme.sh /scripts

# Switch to appuser for installation
USER appuser
WORKDIR /home/appuser

# Install acme.sh as appuser (download from internet)
RUN curl https://get.acme.sh | sh

# Switch back to root for system changes
USER root

# Create symlinks and wrapper commands
RUN ln -sf /home/appuser/.acme.sh/acme.sh /usr/local/bin/acme.sh && \
    for verb in help version install uninstall upgrade issue signcsr deploy install-cert renew renew-all revoke remove list info showcsr install-cronjob uninstall-cronjob cron toPkcs toPkcs8 update-account register-account create-account-key create-domain-key createCSR deactivate deactivate-account set-notify set-default-ca set-default-chain; do \
        printf -- "%b" "#!/usr/bin/env sh\n/home/appuser/.acme.sh/acme.sh --${verb} --config-home /acme.sh \"\$@\"" >/usr/local/bin/--${verb} && \
        chmod +x /usr/local/bin/--${verb}; \
    done

# Copy our scripts
COPY scripts/ /scripts/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /scripts/deploy.sh && \
    chown -R appuser:appgroup /scripts /entrypoint.sh

# Environment variables
ENV LE_CONFIG_HOME=/acme.sh
ENV AUTO_UPGRADE=1
ENV PFX_PASS=MySuperSecret123

# Expose HTTP port for ACME challenges
EXPOSE 80

# Switch to non-root user
USER appuser

# Override entrypoint to use our custom script
ENTRYPOINT ["/entrypoint.sh"]
