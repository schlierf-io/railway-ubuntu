FROM ubuntu:25.04

# Remove default ubuntu user to free up UID/GID 1000
RUN userdel -r ubuntu 2>/dev/null || true

RUN apt-get update && \
    apt-get install -y unminimize && \
    yes | unminimize

# Install system packages
RUN apt-get update && apt-get install -y \
    openssh-server sudo supervisor cron gettext-base \
    iproute2 iputils-ping nmap netcat-openbsd traceroute dnsutils mtr telnet \
    git curl wget vim htop tmux build-essential xauth \
    python3 python3-pip python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install openclaw, Claude Code CLI, and global tools
RUN npm i -g openclaw clawhub mcporter @steipete/summarize @google/gemini-cli pnpm @anthropic-ai/claude-code \
    && which openclaw && openclaw --version

# Install Tailscale CLI
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install Homebrew (must not run as root)
RUN useradd -m -s /bin/bash linuxbrew \
    && mkdir -p /home/linuxbrew/.linuxbrew \
    && chown -R linuxbrew:linuxbrew /home/linuxbrew
USER linuxbrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
USER root
RUN chmod -R o+rx /home/linuxbrew/.linuxbrew \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /etc/profile.d/homebrew.sh \
    && chmod +x /etc/profile.d/homebrew.sh

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV NODE_PATH=/data
ENV TERM=xterm-256color

# Setup SSH
RUN mkdir -p /run/sshd && chmod 755 /run/sshd
COPY config/sshd_config /etc/ssh/sshd_config
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy openclaw config template
COPY config/openclaw.json.template /etc/openclaw/openclaw.json.template

# Copy entrypoint
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create volume mount point
RUN mkdir -p /data

EXPOSE 22

CMD ["/usr/local/bin/entrypoint.sh"]
