#!/bin/bash
# =================================================================
# System Monitor Installation Script
# Automates installation and setup
# =================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}System Monitor Installation Script${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Detect platform
detect_platform() {
    local os_type=$(uname -s)
    case "$os_type" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

PLATFORM=$(detect_platform)
echo -e "Detected platform: ${GREEN}$PLATFORM${NC}\n"

# Install dependencies based on platform
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    
    case "$PLATFORM" in
        linux)
            # Detect distribution
            if [ -f /etc/debian_version ]; then
                sudo apt-get update
                sudo apt-get install -y bash coreutils python3 python3-pip bc sysstat \
                    net-tools lm-sensors smartmontools dialog curl
            elif [ -f /etc/redhat-release ]; then
                sudo yum install -y bash coreutils python3 python3-pip bc sysstat \
                    net-tools lm_sensors smartmontools dialog curl
            else
                echo -e "${YELLOW}Unknown Linux distribution. Please install dependencies manually.${NC}"
            fi
            
            # Install Python packages
            pip3 install flask jinja2 markdown plotly pandas
            ;;
            
        macos)
            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}Homebrew not found. Please install it first:${NC}"
                echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            
            brew install bash coreutils python3 dialog smartmontools
            pip3 install flask jinja2 markdown plotly pandas
            ;;
            
        windows)
            echo -e "${YELLOW}On Windows, please ensure you have Git Bash or WSL installed${NC}"
            echo -e "${YELLOW}Python 3 and pip should be installed manually${NC}"
            
            pip3 install flask jinja2 markdown plotly pandas
            ;;
    esac
    
    echo -e "${GREEN}✓ Dependencies installed${NC}\n"
}

# Setup directories
setup_directories() {
    echo -e "${YELLOW}Setting up directories...${NC}"
    
    mkdir -p data/metrics
    mkdir -p data/reports
    mkdir -p data/logs
    mkdir -p data/alerts
    
    echo -e "${GREEN}✓ Directories created${NC}\n"
}

# Make scripts executable
setup_scripts() {
    echo -e "${YELLOW}Making scripts executable...${NC}"
    
    chmod +x scripts/*.sh
    chmod +x scripts/collectors/*.sh
    
    echo -e "${GREEN}✓ Scripts configured${NC}\n"
}

# Setup environment
setup_environment() {
    echo -e "${YELLOW}Setting up environment...${NC}"
    
    if [ ! -f .env ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Created .env file${NC}"
    else
        echo -e "${YELLOW}⚠ .env file already exists${NC}"
    fi
    
    echo ""
}

# Setup cron job (optional)
setup_cron() {
    echo -e "\n${YELLOW}Do you want to set up automatic monitoring (cron job)? [y/N]${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        local script_path="$(pwd)/scripts/monitor.sh"
        local cron_entry="*/5 * * * * cd $(pwd) && bash $script_path >> data/logs/cron.log 2>&1"
        
        # Add to crontab
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        
        echo -e "${GREEN}✓ Cron job added (runs every 5 minutes)${NC}"
    else
        echo -e "${YELLOW}⚠ Skipping cron setup${NC}"
    fi
}

# Main installation
main() {
    echo -e "${YELLOW}Starting installation...${NC}\n"
    
    # Ask what to install
    echo -e "Select installation type:"
    echo "1) Full installation (dependencies + setup)"
    echo "2) Setup only (skip dependencies)"
    echo "3) Docker only"
    read -p "Choice [1-3]: " choice
    
    case $choice in
        1)
            install_dependencies
            setup_directories
            setup_scripts
            setup_environment
            setup_cron
            ;;
        2)
            setup_directories
            setup_scripts
            setup_environment
            ;;
        3)
            echo -e "${YELLOW}Docker installation selected${NC}"
            echo -e "To run with Docker: ${GREEN}docker-compose up -d${NC}"
            echo -e "To include InfluxDB: ${GREEN}docker-compose --profile with-influxdb up -d${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    echo -e "Next steps:"
    echo -e "1. Test the monitor: ${GREEN}bash scripts/monitor.sh --test${NC}"
    echo -e "2. View CLI dashboard: ${GREEN}bash scripts/dashboard_cli.sh${NC}"
    echo -e "3. Start Docker services: ${GREEN}docker-compose up -d${NC}"
    echo -e "4. Access web dashboard: ${GREEN}http://localhost:8080${NC}\n"
}

main "$@"
