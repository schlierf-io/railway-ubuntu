#!/bin/bash
set -e

# Defaults
: ${SSH_USERNAME:="jschlier"}
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

USER_HOME="/data/$SSH_USERNAME"

# Create the user if it doesn't exist
if id "$SSH_USERNAME" &>/dev/null; then
    echo "User $SSH_USERNAME already exists"
else
    mkdir -p /data
    useradd -ms /bin/bash -d "$USER_HOME" "$SSH_USERNAME"
    echo "$SSH_USERNAME:$SSH_PASSWORD" | chpasswd
    usermod -aG sudo "$SSH_USERNAME"
    echo "User $SSH_USERNAME created and added to sudo group"
fi

# Ensure home directory exists (volume may be empty on first boot)
mkdir -p "$USER_HOME"
chown "$SSH_USERNAME:$SSH_USERNAME" "$USER_HOME"

# Configure SSH keys if provided
if [ -n "$AUTHORIZED_KEYS" ]; then
    mkdir -p "$USER_HOME/.ssh"
    echo "$AUTHORIZED_KEYS" > "$USER_HOME/.ssh/authorized_keys"
    chown -R "$SSH_USERNAME:$SSH_USERNAME" "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    echo "Authorized keys set for user $SSH_USERNAME"
    # Disable password authentication when keys are provided
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "Password authentication disabled (SSH keys configured)"
else
    echo "No authorized keys set — password authentication remains enabled"
fi

# Configure npm prefix for user (on persistent volume)
NPM_GLOBAL="$USER_HOME/.npm-global"
mkdir -p "$NPM_GLOBAL"
chown "$SSH_USERNAME:$SSH_USERNAME" "$NPM_GLOBAL"
su - "$SSH_USERNAME" -c "npm config set prefix '$NPM_GLOBAL'"

# Add npm global bin to user's PATH
BASHRC="$USER_HOME/.bashrc"
if ! grep -q '.npm-global/bin' "$BASHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$BASHRC"
    chown "$SSH_USERNAME:$SSH_USERNAME" "$BASHRC"
fi

# Ensure SSH host keys exist
ssh-keygen -A

# Create supervisor log directory
mkdir -p /var/log/supervisor

# Start all services via supervisord
echo "Starting services via supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
