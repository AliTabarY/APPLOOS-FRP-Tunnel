
#!/bin/bash
# Advanced Tunnel Manager for FRP & Chisel
# Author: Ali Tabari
# GitHub: https://github.com/alitabari/tunnel-manager
# Version: 2.1.0
# Description: Interactive script to manage FRP and Chisel tunnels with multiple protocols

# Color codes and formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BLACK='\033[1;30m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
NC='\033[0m' # No Color

# Default ports
DEFAULT_FRP_PORT=7000
DEFAULT_FRP_DASHBOARD_PORT=7500
DEFAULT_FRP_KCP_PORT=7000
DEFAULT_FRP_QUIC_PORT=7000
DEFAULT_FRP_WSS_PORT=7443
DEFAULT_CHISEL_PORT=8080
DEFAULT_CHISEL_WSS_PORT=8443

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print super fancy header
print_header() {
    clear
    echo -e "${BLUE}"
    echo "██████╗ ██████╗  ██████╗     ████████╗██╗   ██╗███╗   ██╗███╗   ██╗███████╗██╗     "
    echo "██╔══██╗██╔══██╗██╔═══██╗    ╚══██╔══╝██║   ██║████╗  ██║████╗  ██║██╔════╝██║     "
    echo "██████╔╝██████╔╝██║   ██║       ██║   ██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██║     "
    echo "██╔═══╝ ██╔══██╗██║   ██║       ██║   ██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║     "
    echo "██║     ██║  ██║╚██████╔╝       ██║   ╚██████╔╝██║ ╚████║██║ ╚████║███████╗███████╗"
    echo "╚═╝     ╚═╝  ╚═╝ ╚═════╝        ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝"
    echo -e "${PURPLE}                                                                v2.1.0${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to print section header
print_section() {
    local title=$1
    echo ""
    echo -e "${BG_BLUE}${WHITE}${BOLD} $title ${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_message "$RED" "⚠️  This script must be run as root" 
        exit 1
    fi
}

# Function to detect system architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm"
            ;;
        *)
            print_message "$RED" "⚠️  Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Function to get current IP address
get_ip() {
    local ip=$(curl -s ifconfig.me)
    if [ -z "$ip" ]; then
        ip="Unknown"
    fi
    echo $ip
}

# Function to check installation status
check_installation() {
    # Check FRP
    if [ -f "/opt/frp/frps" ] || [ -f "/opt/frp/frpc" ]; then
        frp_installed=true
    else
        frp_installed=false
    fi
    
    # Check FRP service status
    if systemctl is-active --quiet frps.service; then
        frps_active=true
    else
        frps_active=false
    fi
    
    if systemctl is-active --quiet frpc.service; then
        frpc_active=true
    else
        frpc_active=false
    fi
    
    # Check Chisel
    if [ -f "/opt/chisel/chisel" ]; then
        chisel_installed=true
    else
        chisel_installed=false
    fi
    
    # Check Chisel service status
    if systemctl is-active --quiet chisel-server.service; then
        chisel_server_active=true
    else
        chisel_server_active=false
    fi
    
    if systemctl is-active --quiet chisel-client.service; then
        chisel_client_active=true
    else
        chisel_client_active=false
    fi
    
    # Check Certbot
    if command -v certbot &> /dev/null; then
        certbot_installed=true
    else
        certbot_installed=false
    fi
}

# Function to display status with fancy formatting
display_status() {
    local ip=$(get_ip)
    local arch=$(detect_arch)
    local hostname=$(hostname)
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ${YELLOW}${BOLD}SYSTEM INFORMATION${NC}                                         ${GREEN}║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Fixed formatting for system information
    printf "${GREEN}║${NC} ${CYAN}IP Address:${NC} %-50s${GREEN}║${NC}\n" "$ip"
    printf "${GREEN}║${NC} ${CYAN}Architecture:${NC} %-47s${GREEN}║${NC}\n" "$arch"
    printf "${GREEN}║${NC} ${CYAN}Hostname:${NC} %-50s${GREEN}║${NC}\n" "$hostname"
    
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║ ${YELLOW}${BOLD}SERVICE STATUS${NC}                                            ${GREEN}║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # FRP Status - Fixed formatting
    if $frp_installed; then
        if $frps_active; then
            printf "${GREEN}║${NC} ${CYAN}FRP:${NC} [ ${GREEN}✅ SERVER ACTIVE${NC} ]%-37s${GREEN}║${NC}\n" ""
        elif $frpc_active; then
            printf "${GREEN}║${NC} ${CYAN}FRP:${NC} [ ${GREEN}✅ CLIENT ACTIVE${NC} ]%-37s${GREEN}║${NC}\n" ""
        else
            printf "${GREEN}║${NC} ${CYAN}FRP:${NC} [ ${YELLOW}⚠️  INSTALLED BUT INACTIVE${NC} ]%-29s${GREEN}║${NC}\n" ""
        fi
    else
        printf "${GREEN}║${NC} ${CYAN}FRP:${NC} [ ${RED}❌ NOT INSTALLED${NC} ]%-39s${GREEN}║${NC}\n" ""
    fi
    
    # Chisel Status - Fixed formatting
    if $chisel_installed; then
        if $chisel_server_active; then
            printf "${GREEN}║${NC} ${CYAN}Chisel Server:${NC} [ ${GREEN}✅ ACTIVE${NC} ]%-36s${GREEN}║${NC}\n" ""
        else
            printf "${GREEN}║${NC} ${CYAN}Chisel Server:${NC} [ ${YELLOW}⚠️  INSTALLED BUT INACTIVE${NC} ]%-21s${GREEN}║${NC}\n" ""
        fi
    else
        printf "${GREEN}║${NC} ${CYAN}Chisel Server:${NC} [ ${RED}❌ NOT INSTALLED${NC} ]%-31s${GREEN}║${NC}\n" ""
    fi
    
    if $chisel_installed; then
        if $chisel_client_active; then
            printf "${GREEN}║${NC} ${CYAN}Chisel Client:${NC} [ ${GREEN}✅ ACTIVE${NC} ]%-36s${GREEN}║${NC}\n" ""
        else
            printf "${GREEN}║${NC} ${CYAN}Chisel Client:${NC} [ ${YELLOW}⚠️  INSTALLED BUT INACTIVE${NC} ]%-21s${GREEN}║${NC}\n" ""
        fi
    else
        printf "${GREEN}║${NC} ${CYAN}Chisel Client:${NC} [ ${RED}❌ NOT INSTALLED${NC} ]%-31s${GREEN}║${NC}\n" ""
    fi
    
    # Certbot Status - Fixed formatting
    if $certbot_installed; then
        printf "${GREEN}║${NC} ${CYAN}Certbot:${NC} [ ${GREEN}✅ INSTALLED${NC} ]%-39s${GREEN}║${NC}\n" ""
    else
        printf "${GREEN}║${NC} ${CYAN}Certbot:${NC} [ ${RED}❌ NOT INSTALLED${NC} ]%-39s${GREEN}║${NC}\n" ""
    fi
    
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to show cool progress bar
show_progress() {
    local duration=$1
    local step=$((duration/30))
    local bar_length=30
    
    echo -ne "${YELLOW}Progress: ${NC}["
    for i in $(seq 1 $bar_length); do
        echo -ne "${GREEN}#${NC}"
        sleep $step
    done
    echo -e "] ${GREEN}Done!${NC}"
}

# Function to display animated spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to install Certbot via Snap
install_certbot() {
    print_section "INSTALLING CERTBOT"
    
    # Check if Snap is installed
    if ! command -v snap &> /dev/null; then
        print_message "$BLUE" "📦 Installing Snap..."
        apt update
        apt install -y snapd
        
        # Ensure snap paths are updated
        export PATH=$PATH:/snap/bin
        
        if ! command -v snap &> /dev/null; then
            print_message "$RED" "❌ Failed to install Snap. Please install it manually."
            read -p "Press Enter to continue..."
            return 1
        fi
    fi
    
    # Install Certbot via Snap
    print_message "$BLUE" "📦 Installing Certbot via Snap..."
    snap install core
    snap refresh core
    snap install --classic certbot
    
    # Create symbolic link
    if [ ! -f /usr/bin/certbot ]; then
        ln -s /snap/bin/certbot /usr/bin/certbot
    fi
    
    # Verify installation
    if command -v certbot &> /dev/null; then
        print_message "$GREEN" "✅ Certbot has been successfully installed."
        return 0
    else
        print_message "$RED" "❌ Failed to install Certbot. Please install it manually."
        read -p "Press Enter to continue..."
        return 1
    fi
}

# Function to obtain SSL certificate with Certbot
obtain_ssl_certificate() {
    local domain=$1
    local email=$2
    local cert_dir=$3
    
    print_message "$BLUE" "🔑 Obtaining SSL certificate for $domain..."
    
    # Check if domain is pointing to this server
    local server_ip=$(get_ip)
    local domain_ip=$(dig +short $domain)
    
    if [ "$domain_ip" != "$server_ip" ]; then
        print_message "$YELLOW" "⚠️  Warning: The domain $domain does not point to this server's IP ($server_ip)."
        print_message "$YELLOW" "⚠️  Domain currently points to: $domain_ip"
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [ "$continue_anyway" != "y" ]; then
            return 1
        fi
    fi
    
    # Stop services that might be using port 80
    systemctl stop nginx 2>/dev/null
    systemctl stop apache2 2>/dev/null
    systemctl stop chisel-server.service 2>/dev/null
    
    # Obtain certificate
    certbot certonly --standalone --non-interactive --agree-tos --email "$email" -d "$domain"
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "❌ Failed to obtain SSL certificate. Check the error message above."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Copy certificates to the specified directory
    mkdir -p "$cert_dir"
    cp /etc/letsencrypt/live/$domain/fullchain.pem "$cert_dir/server.crt"
    cp /etc/letsencrypt/live/$domain/privkey.pem "$cert_dir/server.key"
    
    # Set proper permissions
    chmod 644 "$cert_dir/server.crt"
    chmod 600 "$cert_dir/server.key"
    
    print_message "$GREEN" "✅ SSL certificate has been successfully obtained and installed."
    return 0
}

# Function to install FRP
install_frp() {
    print_section "INSTALLING FRP"
    
    # Create installation directory
    mkdir -p /opt/frp
    cd /opt/frp
    
    # Remove previous version if exists
    rm -rf frp_*
    
    # Detect architecture
    local arch_name=$(detect_arch)
    print_message "$BLUE" "🔍 Detected architecture: $arch_name"
    
    # Download FRP
    local frp_version="0.51.3"
    print_message "$BLUE" "📥 Downloading FRP v$frp_version for $arch_name..."
    wget -q --show-progress -O frp.tar.gz "https://github.com/fatedier/frp/releases/download/v${frp_version}/frp_${frp_version}_linux_${arch_name}.tar.gz"
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "❌ Failed to download FRP. Please check your internet connection."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Extract the archive
    print_message "$BLUE" "📦 Extracting FRP..."
    tar -xzf frp.tar.gz
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "❌ Failed to extract FRP."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Move files to the correct location
    cp -r frp_${frp_version}_linux_${arch_name}/* .
    rm -rf frp_${frp_version}_linux_${arch_name} frp.tar.gz
    
    # Test the executable
    print_message "$BLUE" "🧪 Testing FRP installation:"
    ./frps -v
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "❌ Failed to execute FRP. Installation might be corrupted."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    print_message "$GREEN" "✅ FRP has been successfully installed to /opt/frp/"
    return 0
}

# Function to install Chisel
install_chisel() {
    print_section "INSTALLING CHISEL"
    
    # Create installation directory
    mkdir -p /opt/chisel
    cd /opt/chisel
    
    # Remove previous version if exists
    rm -f chisel chisel.gz
    
    # Detect architecture
    local arch_name=$(detect_arch)
    print_message "$BLUE" "🔍 Detected architecture: $arch_name"
    
    # Download Chisel
    print_message "$BLUE" "📥 Downloading Chisel v1.10.1 for $arch_name..."
    wget -q --show-progress -O chisel.gz "https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_linux_${arch_name}.gz"
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "❌ Failed to download Chisel. Please check your internet connection."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Extract the archive
    print_message "$BLUE" "📦 Extracting Chisel..."
    gunzip chisel.gz
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "❌ Failed to extract Chisel."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Set executable permissions
    chmod +x chisel
    
    # Test the executable
    print_message "$BLUE" "🧪 Testing Chisel installation:"
    ./chisel --version
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "❌ Failed to execute Chisel. Installation might be corrupted."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    print_message "$GREEN" "✅ Chisel has been successfully installed to /opt/chisel/chisel"
    return 0
}

# Function to configure FRP Server
configure_frp_server() {
    print_section "CONFIGURING FRP SERVER"
    
    # Get authentication token
    read -p "Enter authentication token (default: UQpkP1jSOx8p9HOU): " token
    token=${token:-UQpkP1jSOx8p9HOU}
    
    # Ask for protocol selection
    echo ""
    print_message "$YELLOW" "Select protocol(s) to enable:"
    echo -e "  ${WHITE}${BG_BLUE} 1 ${NC} TCP only"
    echo -e "  ${WHITE}${BG_BLUE} 2 ${NC} TCP + KCP"
    echo -e "  ${WHITE}${BG_BLUE} 3 ${NC} TCP + QUIC"
    echo -e "  ${WHITE}${BG_BLUE} 4 ${NC} TCP + WebSocket/TLS"
    echo -e "  ${WHITE}${BG_BLUE} 5 ${NC} All protocols (TCP, KCP, QUIC, WebSocket/TLS)"
    read -p "Enter your choice (1-5, default: 5): " protocol_choice
    protocol_choice=${protocol_choice:-5}
    
    # Create configuration file
    cat > /opt/frp/frps.ini << EOF
[common]
bind_port = $DEFAULT_FRP_PORT
token = $token
dashboard_port = $DEFAULT_FRP_DASHBOARD_PORT
dashboard_user = admin
dashboard_pwd = $token
EOF
    
    # Configure protocols based on choice
    case $protocol_choice in
        2)
            print_message "$BLUE" "🔄 Configuring TCP + KCP protocols..."
            cat >> /opt/frp/frps.ini << EOF
kcp_bind_port = $DEFAULT_FRP_KCP_PORT
EOF
            ;;
        3)
            print_message "$BLUE" "🔄 Configuring TCP + QUIC protocols..."
            cat >> /opt/frp/frps.ini << EOF
quic_bind_port = $DEFAULT_FRP_QUIC_PORT
EOF
            ;;
        4)
            print_message "$BLUE" "🔄 Configuring TCP + WebSocket/TLS protocols..."
            
            # Ask for domain name for SSL certificate
            echo ""
            print_message "$YELLOW" "SSL Certificate Configuration:"
            read -p "Enter domain name for SSL certificate: " domain_name
            read -p "Enter email address for SSL notifications: " email_address
            
            # Install Certbot if not already installed
            if ! $certbot_installed; then
                install_certbot
            fi
            
            # Create directory for SSL certificates
            mkdir -p /opt/frp/certs
            
            # Obtain SSL certificate
            obtain_ssl_certificate "$domain_name" "$email_address" "/opt/frp/certs"
            
            cat >> /opt/frp/frps.ini << EOF
bind_port_wss = $DEFAULT_FRP_WSS_PORT
tls_cert_file = /opt/frp/certs/server.crt
tls_key_file = /opt/frp/certs/server.key
EOF
            ;;
        5)
            print_message "$BLUE" "🔄 Configuring all protocols (TCP, KCP, QUIC, WebSocket/TLS)..."
            
            # Ask for domain name for SSL certificate
            echo ""
            print_message "$YELLOW" "SSL Certificate Configuration:"
            read -p "Enter domain name for SSL certificate: " domain_name
            read -p "Enter email address for SSL notifications: " email_address
            
            # Install Certbot if not already installed
            if ! $certbot_installed; then
                install_certbot
            fi
            
            # Create directory for SSL certificates
            mkdir -p /opt/frp/certs
            
            # Obtain SSL certificate
            obtain_ssl_certificate "$domain_name" "$email_address" "/opt/frp/certs"
            
            cat >> /opt/frp/frps.ini << EOF
kcp_bind_port = $DEFAULT_FRP_KCP_PORT
quic_bind_port = $DEFAULT_FRP_QUIC_PORT
bind_port_wss = $DEFAULT_FRP_WSS_PORT
tls_cert_file = /opt/frp/certs/server.crt
tls_key_file = /opt/frp/certs/server.key
EOF
            ;;
        *)
            print_message "$BLUE" "🔄 Using TCP protocol only..."
            ;;
    esac
    
    # Create systemd service file
    cat > /etc/systemd/system/frps.service << EOF
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=/opt/frp/frps -c /opt/frp/frps.ini
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd, enable and start the service
    print_message "$BLUE" "🔄 Starting FRP Server service..."
    systemctl daemon-reload
    systemctl enable frps.service
    systemctl restart frps.service
    
    # Check service status
    if systemctl is-active --quiet frps.service; then
        print_message "$GREEN" "✅ FRP Server is running successfully!"
    else
        print_message "$RED" "❌ Failed to start FRP Server. Check logs with: journalctl -u frps.service"
        systemctl status frps.service
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Open firewall ports
    print_message "$BLUE" "🔥 Opening ports in firewall..."
    if command -v ufw &> /dev/null; then
        ufw allow $DEFAULT_FRP_PORT/tcp
        ufw allow $DEFAULT_FRP_DASHBOARD_PORT/tcp
        
        # Open additional ports based on protocol choice
        case $protocol_choice in
            2)
                ufw allow $DEFAULT_FRP_KCP_PORT/udp
                ;;
            3)
                ufw allow $DEFAULT_FRP_QUIC_PORT/udp
                ;;
            4)
                ufw allow $DEFAULT_FRP_WSS_PORT/tcp
                ;;
            5)
                ufw allow $DEFAULT_FRP_KCP_PORT/udp
                ufw allow $DEFAULT_FRP_QUIC_PORT/udp
                ufw allow $DEFAULT_FRP_WSS_PORT/tcp
                ;;
        esac
        
        print_message "$GREEN" "✅ Ports opened in UFW."
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$DEFAULT_FRP_PORT/tcp
        firewall-cmd --permanent --add-port=$DEFAULT_FRP_DASHBOARD_PORT/tcp
        
        # Open additional ports based on protocol choice
        case $protocol_choice in
            2)
                firewall-cmd --permanent --add-port=$DEFAULT_FRP_KCP_PORT/udp
                ;;
            3)
                firewall-cmd --permanent --add-port=$DEFAULT_FRP_QUIC_PORT/udp
                ;;
            4)
                firewall-cmd --permanent --add-port=$DEFAULT_FRP_WSS_PORT/tcp
                ;;
            5)
                firewall-cmd --permanent --add-port=$DEFAULT_FRP_KCP_PORT/udp
                firewall-cmd --permanent --add-port=$DEFAULT_FRP_QUIC_PORT/udp
                firewall-cmd --permanent --add-port=$DEFAULT_FRP_WSS_PORT/tcp
                ;;
        esac
        
        firewall-cmd --reload
        print_message "$GREEN" "✅ Ports opened in FirewallD."
    else
        print_message "$YELLOW" "⚠️  No supported firewall detected. Please manually open ports."
    fi
    
    # Display success message and connection info
    local server_ip=$(get_ip)
    echo ""
    echo -e "${BG_GREEN}${BLACK} SUCCESS ${NC} FRP Server configuration completed!"
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}SERVER INFORMATION${NC}                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Fixed formatting for dashboard info
    printf "${PURPLE}║${NC} ${CYAN}Dashboard URL:${NC} http://%s:%s${NC}%$((51-${#server_ip}-${#DEFAULT_FRP_DASHBOARD_PORT}-7))s${PURPLE}║${NC}\n" "$server_ip" "$DEFAULT_FRP_DASHBOARD_PORT" ""
    printf "${PURPLE}║${NC} ${CYAN}Username:${NC} admin%$((51-5))s${PURPLE}║${NC}\n" ""
    printf "${PURPLE}║${NC} ${CYAN}Password:${NC} %s%$((51-${#token}))s${PURPLE}║${NC}\n" "$token" ""
    
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}PROTOCOL INFORMATION${NC}                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Fixed formatting for protocol info
    printf "${PURPLE}║${NC} ${CYAN}TCP:${NC} %s:%s%$((51-${#server_ip}-${#DEFAULT_FRP_PORT}-4))s${PURPLE}║${NC}\n" "$server_ip" "$DEFAULT_FRP_PORT" ""
    
    # Display additional protocol information based on choice with fixed formatting
    case $protocol_choice in
        2)
            printf "${PURPLE}║${NC} ${CYAN}KCP:${NC} %s:%s%$((51-${#server_ip}-${#DEFAULT_FRP_KCP_PORT}-4))s${PURPLE}║${NC}\n" "$server_ip" "$DEFAULT_FRP_KCP_PORT" ""
            ;;
        3)
            printf "${PURPLE}║${NC} ${CYAN}QUIC:${NC} %s:%s%$((51-${#server_ip}-${#DEFAULT_FRP_QUIC_PORT}-5))s${PURPLE}║${NC}\n" "$server_ip" "$DEFAULT_FRP_QUIC_PORT" ""
            ;;
        4)
            printf "${PURPLE}║${NC} ${CYAN}WebSocket/TLS:${NC} %s:%s%$((51-${#server_ip}-${#DEFAULT_FRP_WSS_PORT}-13))s${PURPLE}║${NC}\n" "$domain_name" "$DEFAULT_FRP_WSS_PORT" ""
            ;;
        5)
            printf "${PURPLE}║${NC} ${CYAN}KCP:${NC} %s:%s%$((51-${#server_ip}-${#DEFAULT_FRP_KCP_PORT}-4))s${PURPLE}║${NC}\n" "$server_ip" "$DEFAULT_FRP_KCP_PORT" ""
            printf "${PURPLE}║${NC} ${CYAN}QUIC:${NC} %s:%s%$((51-${#server_ip}-${#DEFAULT_FRP_QUIC_PORT}-5))s${PURPLE}║${NC}\n" "$server_ip" "$DEFAULT_FRP_QUIC_PORT" ""
            printf "${PURPLE}║${NC} ${CYAN}WebSocket/TLS:${NC} %s:%s%$((51-${#domain_name}-${#DEFAULT_FRP_WSS_PORT}-13))s${PURPLE}║${NC}\n" "$domain_name" "$DEFAULT_FRP_WSS_PORT" ""
            ;;
    esac
    
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}CLIENT CONNECTION INFORMATION${NC}                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    printf "${PURPLE}║${NC} ${CYAN}Server Address:${NC} %s%$((51-${#server_ip}-14))s${PURPLE}║${NC}\n" "$server_ip" ""
    printf "${PURPLE}║${NC} ${CYAN}Token:${NC} %s%$((51-${#token}-6))s${PURPLE}║${NC}\n" "$token" ""
    printf "${PURPLE}║${NC} ${CYAN}TCP Port:${NC} %s%$((51-${#DEFAULT_FRP_PORT}-9))s${PURPLE}║${NC}\n" "$DEFAULT_FRP_PORT" ""
    
    if [ "$protocol_choice" = "4" ] || [ "$protocol_choice" = "5" ]; then
        printf "${PURPLE}║${NC} ${CYAN}WSS Domain:${NC} %s%$((51-${#domain_name}-11))s${PURPLE}║${NC}\n" "$domain_name" ""
        printf "${PURPLE}║${NC} ${CYAN}WSS Port:${NC} %s%$((51-${#DEFAULT_FRP_WSS_PORT}-9))s${PURPLE}║${NC}\n" "$DEFAULT_FRP_WSS_PORT" ""
    fi
    
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    # Setup automatic certificate renewal
    if [ "$protocol_choice" = "4" ] || [ "$protocol_choice" = "5" ]; then
        print_message "$BLUE" "🔄 Setting up automatic certificate renewal..."
        
        # Create renewal script
        cat > /opt/frp/renew-cert.sh << EOF
#!/bin/bash
# Script to renew Let's Encrypt certificate and update FRP

# Stop services that might be using port 80
systemctl stop nginx 2>/dev/null
systemctl stop apache2 2>/dev/null

# Renew certificate
certbot renew --quiet

# Copy new certificates
cp /etc/letsencrypt/live/$domain_name/fullchain.pem /opt/frp/certs/server.crt
cp /etc/letsencrypt/live/$domain_name/privkey.pem /opt/frp/certs/server.key

# Set proper permissions
chmod 644 /opt/frp/certs/server.crt
chmod 600 /opt/frp/certs/server.key

# Restart FRP server
systemctl restart frps.service
EOF
        
        chmod +x /opt/frp/renew-cert.sh
        
        # Add to crontab to run twice a day
        (crontab -l 2>/dev/null | grep -v "/opt/frp/renew-cert.sh" ; echo "0 0,12 * * * /opt/frp/renew-cert.sh") | crontab -
        
        print_message "$GREEN" "✅ Automatic certificate renewal has been set up."
    fi
    
    read -p "Press Enter to continue..."
    return 0
}

# Function to configure FRP Client
configure_frp_client() {
    print_section "CONFIGURING FRP CLIENT"
    
    # Get configuration parameters
    read -p "Enter Iran server address (domain or IP): " server_addr
    
    # Validate server address
    if [ -z "$server_addr" ]; then
        print_message "$RED" "❌ Server address cannot be empty!"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Test if the server address is reachable
    print_message "$BLUE" "🔍 Testing connection to server..."
    if ! ping -c 1 -W 5 "$server_addr" &>/dev/null; then
        print_message "$YELLOW" "⚠️  Warning: Cannot ping the server. This might be normal if ICMP is blocked."
        
        # Try to resolve the hostname
        if ! nslookup "$server_addr" &>/dev/null; then
            print_message "$RED" "❌ Cannot resolve the hostname. Please check if the address is correct."
            read -p "Do you want to continue anyway? (y/n): " continue_anyway
            if [ "$continue_anyway" != "y" ]; then
                return 1
            fi
        fi
    else
        print_message "$GREEN" "✅ Server is reachable."
    fi
    
    read -p "Enter authentication token (default: UQpkP1jSOx8p9HOU): " token
    token=${token:-UQpkP1jSOx8p9HOU}
    
    # Ask for protocol
    echo ""
    print_message "$YELLOW" "Select connection protocol:"
    echo -e "  ${WHITE}${BG_BLUE} 1 ${NC} TCP (default)"
    echo -e "  ${WHITE}${BG_BLUE} 2 ${NC} KCP (faster in lossy networks, UDP based)"
    echo -e "  ${WHITE}${BG_BLUE} 3 ${NC} QUIC (secure UDP with encryption)"
    echo -e "  ${WHITE}${BG_BLUE} 4 ${NC} WebSocket/TLS (secure, web-friendly)"
    echo -e "  ${WHITE}${BG_BLUE} 5 ${NC} Multiple protocols (for high availability)"
    read -p "Enter your choice (1-5, default: 1): " protocol_choice
    protocol_choice=${protocol_choice:-1}
    
    # Create base configuration file
    cat > /opt/frp/frpc.ini << EOF
[common]
server_addr = $server_addr
token = $token
EOF
    
    # Configure protocol
    case $protocol_choice in
        2)
            print_message "$BLUE" "🔄 Configuring KCP protocol..."
            cat >> /opt/frp/frpc.ini << EOF
server_port = $DEFAULT_FRP_KCP_PORT
protocol = kcp
EOF
            ;;
        3)
            print_message "$BLUE" "🔄 Configuring QUIC protocol..."
            cat >> /opt/frp/frpc.ini << EOF
server_port = $DEFAULT_FRP_QUIC_PORT
protocol = quic
EOF
            ;;
        4)
            print_message "$BLUE" "🔄 Configuring WebSocket/TLS protocol..."
            cat >> /opt/frp/frpc.ini << EOF
server_port = $DEFAULT_FRP_WSS_PORT
protocol = wss
EOF
            ;;
        5)
            print_message "$BLUE" "🔄 Configuring multiple protocols for high availability..."
            cat >> /opt/frp/frpc.ini << EOF
# Multiple protocols configuration
server_port = $DEFAULT_FRP_PORT
protocol = tcp
EOF
            ;;
        *)
            print_message "$BLUE" "🔄 Using default TCP protocol..."
            cat >> /opt/frp/frpc.ini << EOF
server_port = $DEFAULT_FRP_PORT
EOF
            ;;
    esac
    
    # Ask for tunnel configuration
    echo ""
    print_message "$YELLOW" "Configure tunnel:"
    read -p "Enter local port to forward (default: 22): " local_port
    local_port=${local_port:-22}
    
    read -p "Enter remote port for access (inbound port, default: 6000): " remote_port
    remote_port=${remote_port:-6000}
    
    # Add tunnel configuration
    cat >> /opt/frp/frpc.ini << EOF

[tunnel]
type = tcp
local_ip = 127.0.0.1
local_port = $local_port
remote_port = $remote_port
EOF
    
    # Create systemd service file
    cat > /etc/systemd/system/frpc.service << EOF
[Unit]
Description=FRP Client
After=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=/opt/frp/frpc -c /opt/frp/frpc.ini
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd, enable and start the service
    print_message "$BLUE" "🔄 Starting FRP Client service..."
    systemctl daemon-reload
    systemctl enable frpc.service
    systemctl restart frpc.service
    
    # Check service status
    if systemctl is-active --quiet frpc.service; then
        print_message "$GREEN" "✅ FRP Client is running successfully!"
    else
        print_message "$RED" "❌ Failed to start FRP Client. Check logs with: journalctl -u frpc.service"
        systemctl status frpc.service
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Display success message and connection info
    echo ""
    echo -e "${BG_GREEN}${BLACK} SUCCESS ${NC} FRP Client configuration completed!"
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}TUNNEL INFORMATION${NC}                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Fixed formatting for connection info
    local padding=$((51 - ${#server_addr} - ${#remote_port} - ${#local_port} - 14))
    if [ $padding -lt 0 ]; then padding=0; fi
    printf "${PURPLE}║${NC} ${CYAN}Connection:${NC} %s:%s → localhost:%s%${padding}s${PURPLE}║${NC}\n" "$server_addr" "$remote_port" "$local_port" ""
    
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}PROTOCOL INFORMATION${NC}                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Display protocol information with fixed formatting
    case $protocol_choice in
        2)
            printf "${PURPLE}║${NC} ${CYAN}Using KCP protocol${NC}%$((51-17))s${PURPLE}║${NC}\n" ""
            ;;
        3)
            printf "${PURPLE}║${NC} ${CYAN}Using QUIC protocol${NC}%$((51-18))s${PURPLE}║${NC}\n" ""
            ;;
        4)
            printf "${PURPLE}║${NC} ${CYAN}Using WebSocket/TLS protocol${NC}%$((51-26))s${PURPLE}║${NC}\n" ""
            ;;
        5)
            printf "${PURPLE}║${NC} ${CYAN}Using multiple protocols for high availability${NC}%$((51-41))s${PURPLE}║${NC}\n" ""
            ;;
        *)
            printf "${PURPLE}║${NC} ${CYAN}Using TCP protocol${NC}%$((51-17))s${PURPLE}║${NC}\n" ""
            ;;
    esac
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Press Enter to continue..."
    return 0
}

# Function to configure Chisel Server
configure_chisel_server() {
    print_section "CONFIGURING CHISEL SERVER"
    
    # Get authentication parameters
    read -p "Enter authentication username (default: admin): " auth_user
    auth_user=${auth_user:-admin}
    
    read -p "Enter authentication password (default: UQpkP1jSOx8p9HOU): " auth_pass
    auth_pass=${auth_pass:-UQpkP1jSOx8p9HOU}
    
    # Ask for port
    read -p "Enter server port (default: 8080): " server_port
    server_port=${server_port:-$DEFAULT_CHISEL_PORT}
    
    # Check if port is already in use
    if lsof -i :$server_port > /dev/null 2>&1; then
        print_message "$YELLOW" "⚠️  Warning: Port $server_port is already in use."
        read -p "Would you like to use a different port? (y/n): " change_port
        if [ "$change_port" = "y" ]; then
            read -p "Enter new port number: " server_port
        fi
    fi
    
    # Ask for protocol selection
    echo ""
    print_message "$YELLOW" "Select protocol to use:"
    echo -e "  ${WHITE}${BG_BLUE} 1 ${NC} HTTP only (default)"
    echo -e "  ${WHITE}${BG_BLUE} 2 ${NC} HTTPS/TLS"
    echo -e "  ${WHITE}${BG_BLUE} 3 ${NC} HTTP + WebSocket"
    echo -e "  ${WHITE}${BG_BLUE} 4 ${NC} HTTPS/TLS + WebSocket"
    read -p "Enter your choice (1-4, default: 1): " protocol_choice
    protocol_choice=${protocol_choice:-1}
    
    # Build command based on protocol choice
    chisel_command="/opt/chisel/chisel server --host 0.0.0.0 -p $server_port --auth $auth_user:$auth_pass --reverse"
    
    case $protocol_choice in
        2)
            print_message "$BLUE" "🔄 Configuring HTTPS/TLS protocol..."
            
            # Ask for domain name for SSL certificate
            echo ""
            print_message "$YELLOW" "SSL Certificate Configuration:"
            read -p "Enter domain name for SSL certificate: " domain_name
            read -p "Enter email address for SSL notifications: " email_address
            
            # Install Certbot if not already installed
            if ! $certbot_installed; then
                install_certbot
            fi
            
            # Create directory for SSL certificates
            mkdir -p /opt/chisel/certs
            
            # Obtain SSL certificate
            obtain_ssl_certificate "$domain_name" "$email_address" "/opt/chisel/certs"
            
            # Updated to use --tls-key and --tls-cert
            chisel_command="$chisel_command --tls-key /opt/chisel/certs/server.key --tls-cert /opt/chisel/certs/server.crt"
            ;;
        3)
            print_message "$BLUE" "🔄 Configuring HTTP + WebSocket protocol..."
            # For WebSocket, we'll use the default HTTP protocol without additional flags
            # The --ws flag was causing issues, so we're removing it
            ;;
        4)
            print_message "$BLUE" "🔄 Configuring HTTPS/TLS + WebSocket protocol..."
            
            # Ask for domain name for SSL certificate
            echo ""
            print_message "$YELLOW" "SSL Certificate Configuration:"
            read -p "Enter domain name for SSL certificate: " domain_name
            read -p "Enter email address for SSL notifications: " email_address
            
            # Install Certbot if not already installed
            if ! $certbot_installed; then
                install_certbot
            fi
            
            # Create directory for SSL certificates
            mkdir -p /opt/chisel/certs
            
            # Obtain SSL certificate
            obtain_ssl_certificate "$domain_name" "$email_address" "/opt/chisel/certs"
            
            # Updated to use --tls-key and --tls-cert without the --ws flag
            chisel_command="$chisel_command --tls-key /opt/chisel/certs/server.key --tls-cert /opt/chisel/certs/server.crt"
            ;;
        *)
            print_message "$BLUE" "🔄 Using HTTP protocol only..."
            ;;
    esac
    
    # Add keepalive to the command
    chisel_command="$chisel_command --keepalive 25s"
    
    # Create systemd service file with enhanced options
    cat > /etc/systemd/system/chisel-server.service << EOF
[Unit]
Description=Chisel Server
After=network.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=10s
ExecStart=$chisel_command
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd, enable and start the service
    print_message "$BLUE" "🔄 Starting Chisel Server service..."
    systemctl daemon-reload
    systemctl enable chisel-server.service
    systemctl restart chisel-server.service
    
    # Check service status with a delay to ensure it's running
    sleep 2
    if systemctl is-active --quiet chisel-server.service; then
        print_message "$GREEN" "✅ Chisel Server is running successfully!"
    else
        print_message "$RED" "❌ Failed to start Chisel Server. Trying alternative configuration..."
        
        # Try alternative configuration without some flags
        chisel_command="/opt/chisel/chisel server --host 0.0.0.0 -p $server_port --auth $auth_user:$auth_pass --reverse --keepalive 25s"
        
        # Update service file with simplified command
        cat > /etc/systemd/system/chisel-server.service << EOF
[Unit]
Description=Chisel Server
After=network.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=10s
ExecStart=$chisel_command
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
        
        # Try again
        systemctl daemon-reload
        systemctl restart chisel-server.service
        sleep 2
        
        if systemctl is-active --quiet chisel-server.service; then
            print_message "$GREEN" "✅ Chisel Server is now running with alternative configuration!"
        else
            print_message "$RED" "❌ Still failed to start Chisel Server. Check logs with: journalctl -u chisel-server.service"
            systemctl status chisel-server.service
            read -p "Press Enter to continue..."
            return 1
        fi
    fi
    
    # Open firewall port
    print_message "$BLUE" "🔥 Opening ports in firewall..."
    if command -v ufw &> /dev/null; then
        ufw allow $server_port/tcp
        print_message "$GREEN" "✅ Ports opened in UFW."
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$server_port/tcp
        firewall-cmd --reload
        print_message "$GREEN" "✅ Ports opened in FirewallD."
    else
        print_message "$YELLOW" "⚠️  No supported firewall detected. Please manually open ports."
    fi
    
    # Display success message and connection info
    local server_ip=$(get_ip)
    echo ""
    echo -e "${BG_GREEN}${BLACK} SUCCESS ${NC} Chisel Server configuration completed!"
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}SERVER INFORMATION${NC}                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Fixed formatting for server info
    if [ "$protocol_choice" = "2" ] || [ "$protocol_choice" = "4" ]; then
        printf "${PURPLE}║${NC} ${CYAN}Server Address:${NC} %s:%s%$((51-${#domain_name}-${#server_port}-14))s${PURPLE}║${NC}\n" "$domain_name" "$server_port" ""
    else
        printf "${PURPLE}║${NC} ${CYAN}Server Address:${NC} %s:%s%$((51-${#server_ip}-${#server_port}-14))s${PURPLE}║${NC}\n" "$server_ip" "$server_port" ""
    fi
    
    local auth_info="$auth_user:$auth_pass"
    printf "${PURPLE}║${NC} ${CYAN}Authentication:${NC} %s%$((51-${#auth_info}-14))s${PURPLE}║${NC}\n" "$auth_info" ""
    
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}PROTOCOL INFORMATION${NC}                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Display protocol information based on choice with fixed formatting
    case $protocol_choice in
        2)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTPS/TLS${NC}%$((51-18))s${PURPLE}║${NC}\n" ""
            ;;
        3)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTP + WebSocket${NC}%$((51-24))s${PURPLE}║${NC}\n" ""
            ;;
        4)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTPS/TLS + WebSocket${NC}%$((51-30))s${PURPLE}║${NC}\n" ""
            ;;
        *)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTP${NC}%$((51-14))s${PURPLE}║${NC}\n" ""
            ;;
    esac
    
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}CLIENT CONNECTION INFORMATION${NC}                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Display client connection information
    if [ "$protocol_choice" = "2" ] || [ "$protocol_choice" = "4" ]; then
        printf "${PURPLE}║${NC} ${CYAN}Server Address:${NC} %s%$((51-${#domain_name}-14))s${PURPLE}║${NC}\n" "$domain_name" ""
    else
        printf "${PURPLE}║${NC} ${CYAN}Server Address:${NC} %s%$((51-${#server_ip}-14))s${PURPLE}║${NC}\n" "$server_ip" ""
    fi
    printf "${PURPLE}║${NC} ${CYAN}Port:${NC} %s%$((51-${#server_port}-5))s${PURPLE}║${NC}\n" "$server_port" ""
    printf "${PURPLE}║${NC} ${CYAN}Username:${NC} %s%$((51-${#auth_user}-9))s${PURPLE}║${NC}\n" "$auth_user" ""
    printf "${PURPLE}║${NC} ${CYAN}Password:${NC} %s%$((51-${#auth_pass}-9))s${PURPLE}║${NC}\n" "$auth_pass" ""
    
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    # Setup automatic certificate renewal if using SSL
    if [ "$protocol_choice" = "2" ] || [ "$protocol_choice" = "4" ]; then
        print_message "$BLUE" "🔄 Setting up automatic certificate renewal..."
        
        # Create renewal script
        cat > /opt/chisel/renew-cert.sh << EOF
#!/bin/bash
# Script to renew Let's Encrypt certificate and update Chisel

# Stop services that might be using port 80
systemctl stop nginx 2>/dev/null
systemctl stop apache2 2>/dev/null

# Renew certificate
certbot renew --quiet

# Copy new certificates
cp /etc/letsencrypt/live/$domain_name/fullchain.pem /opt/chisel/certs/server.crt
cp /etc/letsencrypt/live/$domain_name/privkey.pem /opt/chisel/certs/server.key

# Set proper permissions
chmod 644 /opt/chisel/certs/server.crt
chmod 600 /opt/chisel/certs/server.key

# Restart Chisel server
systemctl restart chisel-server.service
EOF
        
        chmod +x /opt/chisel/renew-cert.sh
        
        # Add to crontab to run twice a day
        (crontab -l 2>/dev/null | grep -v "/opt/chisel/renew-cert.sh" ; echo "0 0,12 * * * /opt/chisel/renew-cert.sh") | crontab -
        
        print_message "$GREEN" "✅ Automatic certificate renewal has been set up."
    fi
    
    read -p "Press Enter to continue..."
    return 0
}

# Function to configure Chisel Client
configure_chisel_client() {
    print_section "CONFIGURING CHISEL CLIENT"
    
    # Get configuration parameters
    read -p "Enter Iran server address (domain or IP): " server_address
    
    # Validate server address
    if [ -z "$server_address" ]; then
        print_message "$RED" "❌ Server address cannot be empty!"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Test if the server address is reachable
    print_message "$BLUE" "🔍 Testing connection to server..."
    if ! ping -c 1 -W 5 "$server_address" &>/dev/null; then
        print_message "$YELLOW" "⚠️  Warning: Cannot ping the server. This might be normal if ICMP is blocked."
        
        # Try to resolve the hostname
        if ! nslookup "$server_address" &>/dev/null; then
            print_message "$RED" "❌ Cannot resolve the hostname. Please check if the address is correct."
            read -p "Do you want to continue anyway? (y/n): " continue_anyway
            if [ "$continue_anyway" != "y" ]; then
                return 1
            fi
        fi
    else
        print_message "$GREEN" "✅ Server is reachable."
    fi
    
    read -p "Enter authentication username (default: admin): " auth_user
    auth_user=${auth_user:-admin}
    
    read -p "Enter authentication password (default: UQpkP1jSOx8p9HOU): " auth_pass
    auth_pass=${auth_pass:-UQpkP1jSOx8p9HOU}
    
    # Ask for server port
    read -p "Enter server port (default: 8080): " server_port
    server_port=${server_port:-$DEFAULT_CHISEL_PORT}
    
    # Ask for protocol selection
    echo ""
    print_message "$YELLOW" "Select protocol to use:"
    echo -e "  ${WHITE}${BG_BLUE} 1 ${NC} HTTP only (default)"
    echo -e "  ${WHITE}${BG_BLUE} 2 ${NC} HTTPS/TLS"
    echo -e "  ${WHITE}${BG_BLUE} 3 ${NC} HTTP + WebSocket"
    echo -e "  ${WHITE}${BG_BLUE} 4 ${NC} HTTPS/TLS + WebSocket"
    read -p "Enter your choice (1-4, default: 1): " protocol_choice
    protocol_choice=${protocol_choice:-1}
    
    # Build base command based on protocol choice
    case $protocol_choice in
        2)
            print_message "$BLUE" "🔄 Configuring HTTPS/TLS protocol..."
            # Add --tls-skip-verify flag instead of --insecure for better compatibility
            chisel_command="/opt/chisel/chisel client --auth $auth_user:$auth_pass --keepalive 25s --tls-skip-verify https://$server_address:$server_port"
            ;;
        3)
            print_message "$BLUE" "🔄 Configuring HTTP + WebSocket protocol..."
            # Remove --ws flag as it's causing issues
            chisel_command="/opt/chisel/chisel client --auth $auth_user:$auth_pass --keepalive 25s http://$server_address:$server_port"
            ;;
        4)
            print_message "$BLUE" "🔄 Configuring HTTPS/TLS + WebSocket protocol..."
            # Add --tls-skip-verify flag instead of --insecure for better compatibility
            # Remove --ws flag as it's causing issues
            chisel_command="/opt/chisel/chisel client --auth $auth_user:$auth_pass --keepalive 25s --tls-skip-verify https://$server_address:$server_port"
            ;;
        *)
            print_message "$BLUE" "🔄 Using HTTP protocol only..."
            chisel_command="/opt/chisel/chisel client --auth $auth_user:$auth_pass --keepalive 25s http://$server_address:$server_port"
            ;;
    esac
    
    # Ask for tunnel configuration
    echo ""
    print_message "$YELLOW" "Configure tunnel:"
    read -p "Enter local port to forward (default: 22): " local_port
    local_port=${local_port:-22}
    
    read -p "Enter remote port for access (inbound port, default: 6000): " remote_port
    remote_port=${remote_port:-6000}
    
    # Add tunnel configuration
    chisel_command="$chisel_command R:$remote_port:127.0.0.1:$local_port"
    
    # Create systemd service file
    cat > /etc/systemd/system/chisel-client.service << EOF
[Unit]
Description=Chisel Client
After=network.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=10s
ExecStart=$chisel_command
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd, enable and start the service
    print_message "$BLUE" "🔄 Starting Chisel Client service..."
    systemctl daemon-reload
    systemctl enable chisel-client.service
    systemctl restart chisel-client.service
    
    # Check service status with a delay to ensure it's running
    sleep 2
    if systemctl is-active --quiet chisel-client.service; then
        print_message "$GREEN" "✅ Chisel Client is running successfully!"
    else
        print_message "$RED" "❌ Failed to start Chisel Client. Trying alternative configuration..."
        
        # Try alternative configuration with simplified command
        chisel_command="/opt/chisel/chisel client --auth $auth_user:$auth_pass --keepalive 25s http://$server_address:$server_port R:$remote_port:127.0.0.1:$local_port"
        
        # Update service file with simplified command
        cat > /etc/systemd/system/chisel-client.service << EOF
[Unit]
Description=Chisel Client
After=network.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=10s
ExecStart=$chisel_command
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
        
        # Try again
        systemctl daemon-reload
        systemctl restart chisel-client.service
        sleep 2
        
        if systemctl is-active --quiet chisel-client.service; then
            print_message "$GREEN" "✅ Chisel Client is now running with alternative configuration!"
        else
            print_message "$RED" "❌ Still failed to start Chisel Client. Check logs with: journalctl -u chisel-client.service"
            systemctl status chisel-client.service
            read -p "Press Enter to continue..."
            return 1
        fi
    fi
    
    # Display success message and connection info
    echo ""
    echo -e "${BG_GREEN}${BLACK} SUCCESS ${NC} Chisel Client configuration completed!"
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}TUNNEL INFORMATION${NC}                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Fixed formatting for connection info
    local padding=$((51 - ${#server_address} - ${#remote_port} - ${#local_port} - 14))
    if [ $padding -lt 0 ]; then padding=0; fi
    printf "${PURPLE}║${NC} ${CYAN}Connection:${NC} %s:%s → localhost:%s%${padding}s${PURPLE}║${NC}\n" "$server_address" "$remote_port" "$local_port" ""
    
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║ ${YELLOW}${BOLD}PROTOCOL INFORMATION${NC}                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    
    # Display protocol information based on choice with fixed formatting
    case $protocol_choice in
        2)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTPS/TLS${NC} (TLS verification disabled)%$((51-40))s${PURPLE}║${NC}\n" ""
            ;;
        3)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTP + WebSocket${NC}%$((51-24))s${PURPLE}║${NC}\n" ""
            ;;
        4)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTPS/TLS + WebSocket${NC} (TLS verification disabled)%$((51-52))s${PURPLE}║${NC}\n" ""
            ;;
        *)
            printf "${PURPLE}║${NC} ${CYAN}Protocol: HTTP${NC}%$((51-14))s${PURPLE}║${NC}\n" ""
            ;;
    esac
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Press Enter to continue..."
    return 0
}

# Function to manage services with fancy UI
manage_services() {
    while true; do
        print_header
        print_section "SERVICE MANAGEMENT"
        
        echo -e "${YELLOW}${BOLD}Available Actions:${NC}"
        echo -e "  ${WHITE}${BG_GREEN} 1 ${NC} Start/Restart FRP Server"
        echo -e "  ${WHITE}${BG_GREEN} 2 ${NC} Start/Restart FRP Client"
        echo -e "  ${WHITE}${BG_GREEN} 3 ${NC} Start/Restart Chisel Server"
        echo -e "  ${WHITE}${BG_GREEN} 4 ${NC} Start/Restart Chisel Client"
        echo -e "  ${WHITE}${BG_RED} 5 ${NC} Stop FRP Server"
        echo -e "  ${WHITE}${BG_RED} 6 ${NC} Stop FRP Client"
        echo -e "  ${WHITE}${BG_RED} 7 ${NC} Stop Chisel Server"
        echo -e "  ${WHITE}${BG_RED} 8 ${NC} Stop Chisel Client"
        echo -e "  ${WHITE}${BG_BLUE} 9 ${NC} Return to Main Menu"
        echo ""
        read -p "Enter your choice [1-9]: " choice
        
        case $choice in
            1)
                systemctl restart frps.service
                print_message "$GREEN" "✅ FRP Server restarted."
                read -p "Press Enter to continue..."
                ;;
            2)
                systemctl restart frpc.service
                print_message "$GREEN" "✅ FRP Client restarted."
                read -p "Press Enter to continue..."
                ;;
            3)
                systemctl restart chisel-server.service
                print_message "$GREEN" "✅ Chisel Server restarted."
                read -p "Press Enter to continue..."
                ;;
            4)
                systemctl restart chisel-client.service
                print_message "$GREEN" "✅ Chisel Client restarted."
                read -p "Press Enter to continue..."
                ;;
            5)
                systemctl stop frps.service
                print_message "$YELLOW" "⚠️  FRP Server stopped."
                read -p "Press Enter to continue..."
                ;;
            6)
                systemctl stop frpc.service
                print_message "$YELLOW" "⚠️  FRP Client stopped."
                read -p "Press Enter to continue..."
                ;;
            7)
                systemctl stop chisel-server.service
                print_message "$YELLOW" "⚠️  Chisel Server stopped."
                read -p "Press Enter to continue..."
                ;;
            8)
                systemctl stop chisel-client.service
                print_message "$YELLOW" "⚠️  Chisel Client stopped."
                read -p "Press Enter to continue..."
                ;;
            9)
                return
                ;;
            *)
                print_message "$RED" "❌ Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to manage scheduled restarts with fancy UI
manage_scheduled_restarts() {
    while true; do
        print_header
        print_section "SCHEDULED RESTART MANAGEMENT"
        
        echo -e "${YELLOW}${BOLD}Available Actions:${NC}"
        echo -e "  ${WHITE}${BG_BLUE} 1 ${NC} Schedule FRP Server Restart"
        echo -e "  ${WHITE}${BG_BLUE} 2 ${NC} Schedule FRP Client Restart"
        echo -e "  ${WHITE}${BG_BLUE} 3 ${NC} Schedule Chisel Server Restart"
        echo -e "  ${WHITE}${BG_BLUE} 4 ${NC} Schedule Chisel Client Restart"
        echo -e "  ${WHITE}${BG_RED} 5 ${NC} Remove All Scheduled Restarts"
        echo -e "  ${WHITE}${BG_PURPLE} 6 ${NC} View Current Scheduled Restarts"
        echo -e "  ${WHITE}${BG_GREEN} 7 ${NC} Return to Main Menu"
        echo ""
        read -p "Enter your choice [1-7]: " choice
        
        case $choice in
            1)
                read -p "Enter restart interval in hours (e.g., 6): " hours
                (crontab -l 2>/dev/null | grep -v "systemctl restart frps.service" ; echo "0 */$hours * * * systemctl restart frps.service") | crontab -
                print_message "$GREEN" "✅ FRP Server will restart every $hours hours."
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter restart interval in hours (e.g., 6): " hours
                (crontab -l 2>/dev/null | grep -v "systemctl restart frpc.service" ; echo "0 */$hours * * * systemctl restart frpc.service") | crontab -
                print_message "$GREEN" "✅ FRP Client will restart every $hours hours."
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter restart interval in hours (e.g., 6): " hours
                (crontab -l 2>/dev/null | grep -v "systemctl restart chisel-server.service" ; echo "0 */$hours * * * systemctl restart chisel-server.service") | crontab -
                print_message "$GREEN" "✅ Chisel Server will restart every $hours hours."
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter restart interval in hours (e.g., 6): " hours
                (crontab -l 2>/dev/null | grep -v "systemctl restart chisel-client.service" ; echo "0 */$hours * * * systemctl restart chisel-client.service") | crontab -
                print_message "$GREEN" "✅ Chisel Client will restart every $hours hours."
                read -p "Press Enter to continue..."
                ;;
            5)
                (crontab -l 2>/dev/null | grep -v "systemctl restart frps.service" | grep -v "systemctl restart frpc.service" | grep -v "systemctl restart chisel-server.service" | grep -v "systemctl restart chisel-client.service") | crontab -
                print_message "$GREEN" "✅ All scheduled restarts removed."
                read -p "Press Enter to continue..."
                ;;
            6)
                echo ""
                print_message "$BLUE" "📋 Current Scheduled Restarts:"
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                crontab -l | grep "systemctl restart" || echo -e "${RED}No scheduled restarts found.${NC}"
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                return
                ;;
            *)
                print_message "$RED" "❌ Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to view logs with fancy UI
view_logs() {
    while true; do
        print_header
        print_section "LOG VIEWER"
        
        echo -e "${YELLOW}${BOLD}Available Logs:${NC}"
        echo -e "  ${WHITE}${BG_BLUE} 1 ${NC} View FRP Server Logs"
        echo -e "  ${WHITE}${BG_BLUE} 2 ${NC} View FRP Client Logs"
        echo -e "  ${WHITE}${BG_BLUE} 3 ${NC} View Chisel Server Logs"
        echo -e "  ${WHITE}${BG_BLUE} 4 ${NC} View Chisel Client Logs"
        echo -e "  ${WHITE}${BG_BLUE} 5 ${NC} View Certbot Logs"
        echo -e "  ${WHITE}${BG_GREEN} 6 ${NC} Return to Main Menu"
        echo ""
        read -p "Enter your choice [1-6]: " choice
        
        case $choice in
            1)
                print_message "$BLUE" "📜 FRP Server Logs:"
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                journalctl -u frps.service -n 50 --no-pager
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                print_message "$BLUE" "📜 FRP Client Logs:"
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                journalctl -u frpc.service -n 50 --no-pager
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                print_message "$BLUE" "📜 Chisel Server Logs:"
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                journalctl -u chisel-server.service -n 50 --no-pager
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                print_message "$BLUE" "📜 Chisel Client Logs:"
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                journalctl -u chisel-client.service -n 50 --no-pager
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                print_message "$BLUE" "📜 Certbot Logs:"
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                if [ -f "/var/log/letsencrypt/letsencrypt.log" ]; then
                    tail -n 50 /var/log/letsencrypt/letsencrypt.log
                else
                    echo -e "${RED}Certbot log file not found.${NC}"
                fi
                echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                return
                ;;
            *)
                print_message "$RED" "❌ Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to uninstall FRP with fancy UI
uninstall_frp() {
    print_section "UNINSTALLING FRP"
    
    echo -e "${BG_RED}${WHITE} WARNING ${NC} This will completely remove FRP from your system!"
    read -p "Are you sure you want to uninstall FRP? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        print_message "$YELLOW" "⚠️  Uninstallation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    print_message "$YELLOW" "🗑️  Uninstalling FRP..."
    
    # Stop and disable services
    systemctl stop frps.service 2>/dev/null
    systemctl stop frpc.service 2>/dev/null
    systemctl disable frps.service 2>/dev/null
    systemctl disable frpc.service 2>/dev/null
    
    # Remove service files
    rm -f /etc/systemd/system/frps.service
    rm -f /etc/systemd/system/frpc.service
    
    # Reload systemd
    systemctl daemon-reload
    
    # Remove FRP files
    rm -rf /opt/frp
    
    print_message "$GREEN" "✅ FRP has been uninstalled."
    read -p "Press Enter to continue..."
}

# Function to uninstall Chisel with fancy UI
uninstall_chisel() {
    print_section "UNINSTALLING CHISEL"
    
    echo -e "${BG_RED}${WHITE} WARNING ${NC} This will completely remove Chisel from your system!"
    read -p "Are you sure you want to uninstall Chisel? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        print_message "$YELLOW" "⚠️  Uninstallation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    print_message "$YELLOW" "🗑️  Uninstalling Chisel..."
    
    # Stop and disable services
    systemctl stop chisel-server.service 2>/dev/null
    systemctl stop chisel-client.service 2>/dev/null
    systemctl disable chisel-server.service 2>/dev/null
    systemctl disable chisel-client.service 2>/dev/null
    
    # Remove service files
    rm -f /etc/systemd/system/chisel-server.service
    rm -f /etc/systemd/system/chisel-client.service
    
    # Reload systemd
    systemctl daemon-reload
    
    # Remove Chisel files
    rm -rf /opt/chisel
    
    print_message "$GREEN" "✅ Chisel has been uninstalled."
    read -p "Press Enter to continue..."
}

# Function to setup Iran server with FRP
setup_iran_server_frp() {
    print_header
    print_section "SETTING UP IRAN SERVER WITH FRP"
    
    # Install FRP if not already installed
    if ! $frp_installed; then
        install_frp
    fi
    
    # Configure FRP Server
    configure_frp_server
}

# Function to setup foreign server with FRP
setup_foreign_server_frp() {
    print_header
    print_section "SETTING UP FOREIGN SERVER WITH FRP"
    
    # Install FRP if not already installed
    if ! $frp_installed; then
        install_frp
    fi
    
    # Configure FRP Client
    configure_frp_client
}

# Function to setup Iran server with Chisel
setup_iran_server_chisel() {
    print_header
    print_section "SETTING UP IRAN SERVER WITH CHISEL"
    
    # Install Chisel if not already installed
    if ! $chisel_installed; then
        install_chisel
    fi
    
    # Install Certbot if not already installed
    if ! $certbot_installed; then
        install_certbot
    fi
    
    # Configure Chisel Server
    configure_chisel_server
}

# Function to setup foreign server with Chisel
setup_foreign_server_chisel() {
    print_header
    print_section "SETTING UP FOREIGN SERVER WITH CHISEL"
    
    # Install Chisel if not already installed
    if ! $chisel_installed; then
        install_chisel
    fi
    
    # Configure Chisel Client
    configure_chisel_client
}

# Main function
main() {
    check_root
    
    while true; do
        print_header
        check_installation
        display_status
        
        echo -e "${YELLOW}${BOLD}MAIN MENU:${NC}"
        echo -e "  ${WHITE}${BG_BLUE} 1 ${NC} Setup Iran Server (FRP)"
        echo -e "  ${WHITE}${BG_BLUE} 2 ${NC} Setup Foreign Server (FRP)"
        echo -e "  ${WHITE}${BG_PURPLE} 3 ${NC} Setup Iran Server (Chisel)"
        echo -e "  ${WHITE}${BG_PURPLE} 4 ${NC} Setup Foreign Server (Chisel)"
        echo -e "  ${WHITE}${BG_GREEN} 5 ${NC} Manage Services"
        echo -e "  ${WHITE}${BG_GREEN} 6 ${NC} Manage Scheduled Restarts"
        echo -e "  ${WHITE}${BG_CYAN} 7 ${NC} View Logs"
        echo -e "  ${WHITE}${BG_RED} 8 ${NC} Uninstall FRP"
        echo -e "  ${WHITE}${BG_RED} 9 ${NC} Uninstall Chisel"
        echo -e "  ${WHITE}${BG_YELLOW}${BLACK} 10 ${NC} Exit"
        echo ""
        read -p "Enter your choice [1-10]: " choice
        
        case $choice in
            1)
                setup_iran_server_frp
                ;;
            2)
                setup_foreign_server_frp
                ;;
            3)
                setup_iran_server_chisel
                ;;
            4)
                setup_foreign_server_chisel
                ;;
            5)
                manage_services
                ;;
            6)
                manage_scheduled_restarts
                ;;
            7)
                view_logs
                ;;
            8)
                uninstall_frp
                ;;
            9)
                uninstall_chisel
                ;;
            10)
                print_header
                echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${GREEN}║                                                               ║${NC}"
                echo -e "${GREEN}║  ${YELLOW}Thank you for using Advanced Tunnel Manager!${GREEN}              ║${NC}"
                echo -e "${GREEN}║                                                               ║${NC}"
                echo -e "${GREEN}║  ${CYAN}GitHub: https://github.com/alitabari/tunnel-manager${GREEN}         ║${NC}"
                echo -e "${GREEN}║                                                               ║${NC}"
                echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_message "$RED" "❌ Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the main function
main
