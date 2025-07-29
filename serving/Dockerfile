FROM nginxinc/nginx-unprivileged:mainline-alpine3.22-perl

# Create necessary directories for nginx temp files
USER root
RUN mkdir -p /tmp/nginx_client_temp \
    /tmp/nginx_proxy_temp \
    /tmp/nginx_fastcgi_temp \
    /tmp/nginx_uwsgi_temp \
    /tmp/nginx_scgi_temp \
    /webroot/.well-known/acme-challenge \
    && chown -R nginx:nginx /tmp/nginx_* /webroot \
    && chmod -R 755 /webroot

# Switch back to nginx user
USER nginx

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 8080 (nginx running as unprivileged user)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

