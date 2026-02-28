# Railway Docker Ubuntu SSH Server

A Docker image designed for Railway deployment that provides an Ubuntu 22.04 base with SSH server enabled (SSHD). This allows you to connect to your Railway container via SSH for remote access and management.

## Features

- Ubuntu 22.04 base image
- SSH server (OpenSSH) pre-configured
- Password authentication enabled
- Root login disabled by default for security
- Created user has sudo permissions
- Network utilities included (ping, telnet, iproute2)

## ⚠️ Important Notice

**Railway runs Docker containers, not VPS!** Any data stored in the container will be **lost when redeploying**. This includes:
- Files created after deployment
- Installed packages
- Configuration changes
- User data

If you need persistent storage, consider using Railway's volume mounts or external storage solutions.

## Setup Instructions

### STEP 1: Configure SSH Credentials


#### Option 1: Modify ssh-user-config.sh

1. **Before deploying**, edit the `ssh-user-config.sh` file and change the default values:

   ```bash
   # Change these default values to your desired credentials
   : ${SSH_USERNAME:="myuser"}
   : ${SSH_PASSWORD:="mypassword"}
   ```

2. Commit and push your changes to your repository

3. **Then** deploy to Railway

#### Option 2: Use Railway Environment Variables

1. **Deploy** to Railway
2. Go to your project dashboard
3. Navigate to **Settings** → **Variables**:

   ![Environment Variables](assets/env-variables.png)

4. Add the following environment variables:
   - `SSH_USERNAME` - Your desired username
   - `SSH_PASSWORD` - Your desired password
   - `ROOT_PASSWORD` - Root password (optional, leave empty if root login is disabled)
   - `AUTHORIZED_KEYS` - SSH public keys for key-based authentication (optional)

5. Redeploy your project to apply the new environment variables:

   ![Environment Redeploy](assets/env-redeploy.png)

### STEP 2: Configure TCP Proxy

1. Go to your Railway project dashboard
2. Navigate to **Settings** → **Networking**:

   ![Railway Settings](assets/railway-settings.png)

3. Under **Public Networking**, click **TCP Proxy**
4. Enter the exposed port `22` (the default SSH port):

   ![TCP Port Configuration](assets/tcp-port.png)

5. Click **Add Proxy**

### STEP 3: Redeploy the Project

After configuring the TCP proxy, redeploy your project to apply the networking changes:

![Project Redeploy](assets/project-redeploy.png)

### STEP 4: Connect via SSH

1. Once deployed, Railway will provide you with a domain and port for TCP access:

   ![TCP Domain and Port](assets/tcp-domain-and-port.png)

2. Use the SSH command to connect:
   ```bash
   ssh {username}@{domain} -p {port}
   ```
   Example:
   ```bash
   ssh myuser@mainline.proxy.rlwy.net -p 30899
   ```

3. When prompted about the host authenticity, type `yes` to accept the new key pair
4. Enter the user password when prompted
5. You're now connected to your Railway container via SSH!

## Configuration Details

### Default Values

The current default values in `ssh-user-config.sh` are:
- `SSH_USERNAME=myuser`
- `SSH_PASSWORD=mypassword`

**⚠️ Important:** Change default values before deploying to production.

### Environment Variable Priority

The system checks for credentials in this order:
1. Railway environment variables (highest priority)
2. Values set directly in `ssh-user-config.sh` (default if no environment variables)

### Root Access

Root login is **disabled by default** for security reasons. If you need to enable root login, you can modify the Dockerfile by changing:

```dockerfile
&& echo "PermitRootLogin no" >> /etc/ssh/sshd_config
```

to:

```dockerfile
&& echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
```

**Note:** The created user already has sudo permissions and is added to the sudo group, so root access is typically unnecessary.

## Security Considerations

- **CRITICAL:** Always change the default SSH credentials in `ssh-user-config.sh` before deploying to production
- Root login is disabled by default
- Only password authentication is enabled by default
- The default user has sudo privileges for administrative tasks
- Consider using SSH keys (`AUTHORIZED_KEYS`) instead of passwords for better security
- When using `AUTHORIZED_KEYS`, password authentication is automatically disabled

## Container Limitations

- **No persistent storage:** All data is lost when redeploying.
- **Not a VPS:** This is a containerized environment, not a virtual private server
- **Temporary file system:** Any files created inside the image will be lost on restart/redeploy

**Important:** Conside using **Railway Volume Mount** for persistent storage

## Troubleshooting

- Ensure the TCP proxy is configured correctly on Railway
- Verify the correct domain and port are being used
- Check that the container is running and healthy
- Confirm firewall settings allow SSH connections
- Verify credentials are set correctly in `ssh-user-config.sh` or Railway environment variables
- Remember that data loss occurs on every redeploy

## License

This project is licensed under the terms included in the LICENSE file.
