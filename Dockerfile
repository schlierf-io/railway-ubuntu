FROM ubuntu:25.04

# Remove default ubuntu user to free up UID/GID 1000
RUN userdel -r ubuntu 2>/dev/null || true

# Install system packages
RUN apt-get update && apt-get install -y \
    # SSH & system
    openssh-server sudo \
    # Network utilities
    iproute2 iputils-ping nmap netcat-openbsd traceroute dnsutils mtr telnet \
    # Dev tools
    git curl wget vim htop tmux build-essential \
    # Python
    python3 python3-pip python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup SSH
RUN mkdir -p /run/sshd && chmod 755 /run/sshd
COPY config/sshd_config /etc/ssh/sshd_config

# Copy entrypoint
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create volume mount point
RUN mkdir -p /data

EXPOSE 22

CMD ["/usr/local/bin/entrypoint.sh"]
