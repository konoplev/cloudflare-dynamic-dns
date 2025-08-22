# Cloudflare Dynamic DNS

A Docker container that automatically updates A records in Cloudflare DNS when your IP address changes. This is a Cloudflare version of the AWS Route 53 dynamic DNS solution.

## Purpose

I use Raspberry PI to run my pet projects. Sometimes I need them available on the Internet, but I don't want to pay for a dedicated IP address. This Docker image allows you to dynamically create (or update) an A record in a Cloudflare DNS zone.

## Prerequisites

1. A Cloudflare account with a domain
2. Docker installed on your system
3. A Cloudflare API Token with DNS editing permissions

## Setup

### 1. Get Your Cloudflare API Token

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Choose "Custom token" template
4. Set the following permissions:
   - **Zone** → **Zone** → **Read**
   - **Zone** → **DNS** → **Edit**
5. Set Zone Resources to "Include" → "Specific zone" → Select your domain
6. Click "Continue to summary" and then "Create Token"
7. Copy the token (you won't be able to see it again)

### 2. Find Your Zone ID

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your domain
3. The Zone ID is displayed on the right sidebar

### 3. Create Environment File

Copy the example environment file and fill in your details:

```bash
cp env.list.example env.list
```

Edit `env.list` with your actual values:

```bash
CLOUDFLARE_API_TOKEN=your_actual_api_token_here
ZONE_ID=your_actual_zone_id_here
RECORDSET=your_subdomain.example.com
```

### 4. Build the Docker Image

```bash
./build.sh
```

Or manually:

```bash
docker build -t cloudflare-dynamic-dns .
```

## Usage

### Run Once

```bash
docker run --env-file ./env.list --rm cloudflare-dynamic-dns
```

### Run Periodically

You can set up a cron job to run this periodically. For example, to run every 5 minutes:

```bash
# Add to crontab (crontab -e)
*/5 * * * * cd /path/to/cloudflare-dynamic-dns && docker run --env-file ./env.list --rm cloudflare-dynamic-dns
```

### Run as a Service

Create a systemd service file for automatic startup:

```bash
# /etc/systemd/system/cloudflare-dynamic-dns.service
[Unit]
Description=Cloudflare Dynamic DNS Updater
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --env-file /path/to/cloudflare-dynamic-dns/env.list --rm cloudflare-dynamic-dns
User=your_user

[Install]
WantedBy=multi-user.target
```

Then create a timer:

```bash
# /etc/systemd/system/cloudflare-dynamic-dns.timer
[Unit]
Description=Run Cloudflare Dynamic DNS every 5 minutes
Requires=cloudflare-dynamic-dns.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
sudo systemctl enable cloudflare-dynamic-dns.timer
sudo systemctl start cloudflare-dynamic-dns.timer
```

## How It Works

1. The script detects your current public IP address using OpenDNS
2. It checks if the IP has changed since the last run
3. If the IP has changed, it:
   - Checks if the DNS record already exists
   - If it exists, updates the record
   - If it doesn't exist, creates a new record
4. Logs all activities to `update-cloudflare.log`

## Configuration Options

You can modify the following variables in the script:

- `TTL`: Time-to-live for the DNS record (default: 300 seconds)
- `TYPE`: Record type (default: "A", can be "AAAA" for IPv6)
- `COMMENT`: Comment added to the DNS record

## Troubleshooting

### Check Logs

The script creates a log file at `scripts/update-cloudflare.log`. Check this file for any errors.

### Common Issues

1. **Invalid API Token**: Make sure your API token has the correct permissions
2. **Invalid Zone ID**: Verify the Zone ID in your Cloudflare dashboard
3. **Network Issues**: Ensure your system can reach the Cloudflare API and OpenDNS

### Testing

You can test the script manually:

```bash
cd cloudflare-dynamic-dns
docker run --env-file ./env.list --rm cloudflare-dynamic-dns
```

## Security Notes

- Keep your API token secure and never commit it to version control
- Use the minimum required permissions for your API token
- Consider using environment variables instead of files for sensitive data in production

## License

This project is based on the AWS Route 53 dynamic DNS solution and adapted for Cloudflare.
