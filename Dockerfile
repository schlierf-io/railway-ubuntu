FROM ubuntu:25.04

# Starting Ubuntu 25.04 official docker image has user ubuntu with UID/GID 1000
# Remove the default ubuntu user to free up UID/GID 1000
RUN userdel -r ubuntu 2>/dev/null || true

# Install dependencies with disable root login for security reasons
RUN apt-get update \
    && apt-get install -y iproute2 iputils-ping openssh-server telnet sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    # Disable root login
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Copy ssh user config to configure user's password and authorized keys
COPY ssh-user-config.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ssh-user-config.sh

# Create volume mount point
RUN mkdir -p /data

# Expose port 22
EXPOSE 22

# Start SSH server
CMD ["/usr/local/bin/ssh-user-config.sh"]