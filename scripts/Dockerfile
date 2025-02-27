# Use RHEL 9 as the base image
FROM registry.access.redhat.com/ubi9/ubi:latest

# Install Python and dependencies
RUN dnf install -y python3 && \
    dnf clean all

# Set working directory
WORKDIR /app

# Copy Python scripts and entrypoint
COPY checkin_listener.py ssh_key_server.py entrypoint.sh ./

# Ensure scripts are executable
RUN chmod +x checkin_listener.py ssh_key_server.py entrypoint.sh

# Expose port 8080
EXPOSE 8080

# Default entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
