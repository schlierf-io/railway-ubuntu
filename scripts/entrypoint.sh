#!/bin/bash
set -e

# Defaults
: ${SSH_USERNAME:="myuser"}
: ${SSH_PASSWORD:="mypassword"}
: ${ROOT_PASSWORD:=""}
: ${AUTHORIZED_KEYS:=""}

# Set root password if provided
if [ -n "$ROOT_PASSWORD" ]; then
    echo "root:$ROOT_PASSWORD" | chpasswd
    echo "Root password set"
else
    echo "Root password not set"
fi

# Validate required variables
if [ -z "$SSH_USERNAME" ] || [ -z "$SSH_PASSWORD" ]; then
    echo "Error: SSH_USERNAME and SSH_PASSWORD must be set." >&2
    exit 1
fi

# Create the user if it doesn't exist
if id "$SSH_USERNAME" &>/dev/null; then
    echo "User $SSH_USERNAME already exists"
else
    mkdir -p /data/home
    useradd -ms /bin/bash -d "/data/home/$SSH_USERNAME" "$SSH_USERNAME"
    echo "$SSH_USERNAME:$SSH_PASSWORD" | chpasswd
    usermod -aG sudo "$SSH_USERNAME"
    echo "User $SSH_USERNAME created and added to sudo group"
fi

# Configure SSH keys if provided
if [ -n "$AUTHORIZED_KEYS" ]; then
    mkdir -p "/data/home/$SSH_USERNAME/.ssh"
    echo "$AUTHORIZED_KEYS" > "/data/home/$SSH_USERNAME/.ssh/authorized_keys"
    chown -R "$SSH_USERNAME:$SSH_USERNAME" "/data/home/$SSH_USERNAME/.ssh"
    chmod 700 "/data/home/$SSH_USERNAME/.ssh"
    chmod 600 "/data/home/$SSH_USERNAME/.ssh/authorized_keys"
    echo "Authorized keys set for user $SSH_USERNAME"
    # Disable password authentication when keys are provided
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "Password authentication disabled (SSH keys configured)"
else
    echo "No authorized keys set — password authentication remains enabled"
fi

# Ensure SSH host keys exist
ssh-keygen -A

# Create supervisor log directory
mkdir -p /var/log/supervisor

# Start all services via supervisord
echo "Starting services via supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
