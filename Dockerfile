FROM neilpang/acme.sh:3.1.1

# Install Azure CLI
RUN apk add --no-cache bash python3 py3-pip build-base python3-dev linux-headers pipx && \
    pipx install azure-cli && \
    pipx ensurepath

# Copy our scripts
COPY scripts/ /scripts/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /scripts/deploy.sh

# Environment variables
ENV PFX_PASS=MySuperSecret123
ENV DOMAINS="example.com"

# Override entrypoint to use our custom script
ENTRYPOINT ["/entrypoint.sh"]
