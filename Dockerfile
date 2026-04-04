FROM ubuntu:25.04

# Create volume mount point
RUN mkdir -p /data

# Remove default ubuntu user to free up UID/GID 1000
RUN userdel -r ubuntu 2>/dev/null || true

RUN apt-get update && \
    apt-get install -y unminimize && \
    yes | unminimize

# Install system packages
RUN apt-get update && apt-get install -y \
    openssh-server sudo supervisor cron gettext-base \
    iproute2 iputils-ping nmap netcat-openbsd traceroute dnsutils mtr telnet \
    git curl wget vim htop tmux build-essential xauth chromium-browser ssh-askpass \
    python3 python3-pip python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm, Claude Code CLI, and Gemini CLI
RUN npm install -g pnpm @anthropic-ai/claude-code @google/gemini-cli

# Install opencode
RUN curl -fsSL https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install | bash

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Rustup (available to all users via shared RUSTUP_HOME/CARGO_HOME)
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="/usr/local/cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path

# Install Homebrew (must not run as root)
RUN useradd -m -s /bin/bash linuxbrew \
    && mkdir -p /home/linuxbrew/.linuxbrew \
    && chown -R linuxbrew:linuxbrew /home/linuxbrew
USER linuxbrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
USER root
RUN chmod o+x /home/linuxbrew \
    && chmod -R o+rx /home/linuxbrew/.linuxbrew \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /etc/profile.d/homebrew.sh \
    && chmod +x /etc/profile.d/homebrew.sh

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV NODE_PATH=/data
ENV TERM=xterm-256color
ENV SSH_ASKPASS=/usr/bin/ssh-askpass
ENV SSH_ASKPASS_REQUIRE=prefer
ENV COLORTERM=truecolor

# Setup SSH
RUN mkdir -p /run/sshd && chmod 755 /run/sshd
COPY config/sshd_config /etc/ssh/sshd_config
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22

CMD ["/usr/local/bin/entrypoint.sh"]
