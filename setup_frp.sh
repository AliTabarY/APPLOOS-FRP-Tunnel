#!/bin/bash

# ==================================================================================
#
#   APPLOOS FRP TUNNEL - Full Management Script (v71.7 - Log Level Fix)
#   Developed By: @AliTabari
#   Purpose: Automate the installation, configuration, and management of FRP.
#
# ==================================================================================

# --- Static Configuration Variables ---
FRP_VERSION="0.62.1"
FRP_INSTALL_DIR="/opt/frp"
SYSTEMD_DIR="/etc/systemd/system"
FRP_TCP_CONTROL_PORT="7000"
FRP_KCP_CONTROL_PORT="7002"
FRP_QUIC_CONTROL_PORT="7001"
FRP_DASHBOARD_PORT="7500"
XUI_PANEL_PORT="54333"
SSL_OPTIONS_FILE="/etc/letsencrypt/options-ssl-nginx.conf"
SSL_DHPARAMS_FILE="/etc/letsencrypt/ssl-dhparams.pem"

# --- Color Codes ---
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- Root Check ---
check_root() { if [[ $EUID -ne 0 ]]; then echo -e "${RED}ERROR: Must be run as root.${NC}"; exit 1; fi; }

# --- Function to check installation status ---
check_install_status() {
    if [ -f "${SYSTEMD_DIR}/frps.service" ] || [ -f "${SYSTEMD_DIR}/frpc.service" ]; then
        echo -e "  FRP Status: ${GREEN}[ ✅ Installed ]${NC}"
    else
        echo -e "  FRP Status: ${RED}[ ❌ Not Installed ]${NC}"
    fi
}

# --- Input Functions ---
get_server_ips() {
    read -p "Enter Public IP for IRAN Server (entry point): " IRAN_SERVER_IP
    if [[ -z "$IRAN_SERVER_IP" ]]; then echo -e "${RED}IP cannot be empty.${NC}"; return 1; fi
    read -p "Enter Public IP for FOREIGN Server (service host): " FOREIGN_SERVER_IP
    if [[ -z "$FOREIGN_SERVER_IP" ]]; then echo -e "${RED}IP cannot be empty.${NC}"; return 1; fi
    return 0
}
get_port_input() {
    echo -e "\n${CYAN}Please enter the port(s) you want to tunnel for BOTH TCP & UDP.${NC}"
    echo -e "Examples:\n  - A single port: ${YELLOW}8080${NC}\n  - A range: ${YELLOW}20000-30000${NC}\n  - A mix: ${YELLOW}80,443,9000-9100${NC}"
    read -p "Enter ports: " user_ports
    if [[ -z "$user_ports" ]]; then echo -e "${RED}No ports entered.${NC}"; return 1; fi
    if [[ "$user_ports" == *"$XUI_PANEL_PORT"* ]]; then echo -e "\n${RED}ERROR: Tunneling the XUI panel port (${XUI_PANEL_PORT}) is not allowed.${NC}"; return 1; fi
    if ! [[ "$user_ports" =~ ^[0-9,-]+$ ]]; then echo -e "${RED}Invalid format.${NC}"; return 1; fi
    FRP_TUNNEL_PORTS_FRP=$user_ports; FRP_TUNNEL_PORTS_UFW=${user_ports//-/:}; return 0
}
get_protocol_choice() {
    echo -e "\n${CYAN}Select the main transport protocol for the tunnel:${NC}"
    echo "  1. TCP (Standard)"; echo "  2. KCP (Fast on lossy networks)"; echo "  3. QUIC (Modern & fast, UDP-based)"
    echo "  4. WSS (Max stealth, requires domain & auto-installs Nginx)"
    read -p "Enter your choice [1-4]: " proto_choice
    case $proto_choice in 2) FRP_PROTOCOL="kcp" ;; 3) FRP_PROTOCOL="quic" ;; 4) FRP_PROTOCOL="wss" ;; *) FRP_PROTOCOL="tcp" ;; esac

    # Common settings for WSS that need domain/email
    if [[ "$FRP_PROTOCOL" == "wss" ]]; then
        read -p "Enter your domain pointed to the Iran server (e.g., frp.yourdomain.com): " FRP_DOMAIN
        if [[ -z "$FRP_DOMAIN" ]]; then echo -e "${RED}Domain cannot be empty for WSS.${NC}"; return 1; fi
        read -p "Enter your email address (for SSL renewal notices): " LETSENCRYPT_EMAIL
        if [[ -z "$LETSENCRYPT_EMAIL" ]]; then echo -e "${RED}Email cannot be empty for SSL certificates.${NC}"; return 1; fi
    fi

    # TCP_MUX setting (now globally applied based on protocol choice)
    TCP_MUX="false" # Default to false
    if [[ "$FRP_PROTOCOL" == "tcp" || "$FRP_PROTOCOL" == "kcp" || "$FRP_PROTOCOL" == "quic" ]]; then # Apply tcpmux for these protocols
        read -p $'\n'"Enable TCP Multiplexer (tcpmux) for better performance? [y/N]: " mux_choice
        if [[ "$mux_choice" =~ ^[Yy]$ ]]; then TCP_MUX="true"; fi
    fi
    # Note: For WSS, TCP_MUX is implicitly true as it relies on HTTP/WS multiplexing, but FRP's tcp_mux setting is not directly used for WSS transport.
}

# --- Core Logic Functions ---
stop_frp_processes() {
    killall frps > /dev/null 2>&1 || true; killall frpc > /dev/null 2>&1 || true
    systemctl stop frps.service > /dev/null 2>&1; systemctl stop frpc.service > /dev/null 2>&1
}
download_and_extract() {
    rm -rf ${FRP_INSTALL_DIR}; mkdir -p ${FRP_INSTALL_DIR}
    FRP_TAR_FILE="frp_${FRP_VERSION}_linux_amd64.tar.gz"
    FRP_DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FRP_TAR_FILE}";
    wget -q "${FRP_DOWNLOAD_URL}" -O "${FRP_TAR_FILE}"; tar -zxvf "${FRP_TAR_FILE}" -C "${FRP_INSTALL_DIR}" --strip-components=1; rm "${FRP_TAR_FILE}"
    echo -e "${GREEN}--> FRP version $(${FRP_INSTALL_DIR}/frps --version) downloaded successfully.${NC}"
}
setup_iran_server() {
    get_server_ips && get_port_input && get_protocol_choice || return 1
    echo -e "\n${YELLOW}--- Setting up Iran Server (frps) ---${NC}"; stop_frp_processes; download_and_extract

    # Nginx and Certbot installation for WSS
    if [ "$FRP_PROTOCOL" == "wss" ]; then
        echo -e "${YELLOW}--> WSS mode: Installing prerequisites...${NC}"
        apt-get update -y > /dev/null
        apt-get install nginx openssl snapd -y > /dev/null
        if [ $? -ne 0 ]; then echo -e "${RED}Failed to install Nginx/Snapd.${NC}"; return 1; fi

        # Install Certbot using the official Snap method
        if ! command -v certbot &> /dev/null; then
            echo -e "${YELLOW}--> Installing Certbot via Snap...${NC}"
            snap install --classic certbot > /dev/null
            ln -s /snap/bin/certbot /usr/bin/certbot > /dev/null 2>&1
        fi

        systemctl stop nginx
        echo -e "${YELLOW}--> Obtaining SSL certificate for ${FRP_DOMAIN}...${NC}";
        certbot certonly --standalone --agree-tos --non-interactive --email ${LETSENCRYPT_EMAIL} -d ${FRP_DOMAIN}
        if [ $? -ne 0 ]; then echo -e "${RED}Failed to obtain SSL certificate. Check DNS and port 80.${NC}"; systemctl start nginx; return 1; fi

        echo -e "${YELLOW}--> Creating SSL security files...${NC}"
        if [ ! -f "${SSL_OPTIONS_FILE}" ]; then
            tee ${SSL_OPTIONS_FILE} > /dev/null <<'EOF'
