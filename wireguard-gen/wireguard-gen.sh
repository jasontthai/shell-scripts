#!/bin/bash
set -e

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with superuser privileges. Please use 'sudo' to run it."
  exit 1
fi

# Function to generate WireGuard key pair
generate_keys() {
  private_key=$(wg genkey)
  public_key=$(echo $private_key | wg pubkey)
  echo "Private Key: $private_key"
  echo "Public Key: $public_key"
}

# Function to generate server configuration
generate_server_config() {
  cat <<EOF > /etc/wireguard/server.conf
[Interface]
PrivateKey = $server_private_key
Address = $server_tunnel_ip
ListenPort = $listen_port

[Peer]
PublicKey = $client_public_key
AllowedIPs = $client_tunnel_ip
EOF
}

# Function to generate client configuration
generate_client_config() {
  cat <<EOF > client.conf
[Interface]
PrivateKey = $client_private_key
Address = $client_tunnel_ip
DNS = $client_dns

[Peer]
PublicKey = $server_public_key
AllowedIPs = $server_tunnel_ip
Endpoint = $server_public_ip:$listen_port
PersistentKeepalive = 25
EOF
}

# Function to detect the server's public IPv4 address
detect_server_ipv4() {
  server_public_ip=$(curl -s -4 ifconfig.co)
  echo "Detected server's public IPv4: $server_public_ip"
}

# Function to enable and start the WireGuard server
enable_and_start_wireguard() {
  systemctl enable wg-quick@server.service
  systemctl start wg-quick@server.service
  echo "WireGuard server is enabled and started."
}

# Main script
echo "Generating WireGuard server key pair:"
generate_keys
server_private_key=$private_key
server_public_key=$public_key

echo "Generating WireGuard client key pair:"
generate_keys
client_private_key=$private_key
client_public_key=$public_key

# Detect the server's public IPv4 address before prompting the user for the public server address
detect_server_ipv4

# Prompt the user for the public server address or set the detected IPv4 address by default
read -p "Enter the public server address (default: $server_public_ip): " manual_server_public_ip
server_public_ip=${manual_server_public_ip:-$server_public_ip}

# Prompt the user for the listen port or set a default
read -p "Enter the server's listen port (default: 51820): " listen_port
listen_port=${listen_port:-51820}

# Prompt the user for the server's tunnel IP range or set a default
read -p "Enter the server's tunnel IP range (default: 10.0.0.1/24): " server_tunnel_ip
server_tunnel_ip=${server_tunnel_ip:-10.0.0.1/24}

# Prompt the user for the client's tunnel IP range or set a default
read -p "Enter the client's tunnel IP range (default: 10.0.0.2/32): " client_tunnel_ip
client_tunnel_ip=${client_tunnel_ip:-10.0.0.2/32}

# Prompt the user to specify DNS for the client.conf or set a default
read -p "Enter the DNS for the client.conf (default: 8.8.8.8): " client_dns
client_dns=${client_dns:-8.8.8.8}

echo "Generating server configuration file with ListenPort $listen_port and Server Tunnel IP $server_tunnel_ip:"
generate_server_config
echo "Generating client configuration file with Client Tunnel IP $client_tunnel_ip, PersistentKeepalive = 25, and DNS = $client_dns:"
generate_client_config

# Enable and start the WireGuard server
enable_and_start_wireguard