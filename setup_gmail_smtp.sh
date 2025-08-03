#!/bin/bash

LOGFILE="/var/log/postfix_gmail_setup.log"
touch "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

echo "-------------------------------------------"
echo "SMTP Setup Script Using Gmail on Ubuntu"
echo "-------------------------------------------"

# Prompt for Gmail credentials
read -p "Enter your Gmail address: " GMAIL_USER
read -s -p "Enter your Gmail App Password: " GMAIL_PASS
echo ""
read -p "Enter your server hostname (e.g. mail.example.com): " MAIL_HOSTNAME

# Update system
echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

# Preconfigure Postfix
echo "[+] Pre-configuring Postfix with hostname: $MAIL_HOSTNAME"
echo "postfix postfix/mailname string $MAIL_HOSTNAME" | sudo debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections

# Install packages
echo "[+] Installing Postfix and Mailutils..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix mailutils

# Configure Postfix main.cf
echo "[+] Configuring Postfix..."
sudo postconf -e "relayhost = [smtp.gmail.com]:587"
sudo postconf -e "smtp_use_tls = yes"
sudo postconf -e "smtp_sasl_auth_enable = yes"
sudo postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
sudo postconf -e "smtp_sasl_security_options = noanonymous"
sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"

# Create sasl_passwd
echo "[+] Creating authentication file..."
echo "[smtp.gmail.com]:587 $GMAIL_USER:$GMAIL_PASS" | sudo tee /etc/postfix/sasl_passwd > /dev/null

# Secure the credentials
echo "[+] Securing credentials..."
sudo postmap /etc/postfix/sasl_passwd
sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Restart Postfix
echo "[+] Restarting Postfix..."
sudo systemctl restart postfix

# Test mail
read -p "Enter recipient email address for test: " TEST_EMAIL
echo "This is a test email sent from your Ubuntu SMTP setup using Gmail." | mail -s "SMTP Test Email" "$TEST_EMAIL"

# Final check
echo "[+] Monitoring mail log. Press Ctrl+C to exit log view."
tail -f /var/log/mail.log
