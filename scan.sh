#!/bin/bash
# Script: nmap-vulners-scan
# Description: Runs nmap with vulners script, generates XML and HTML reports, and sends results via email
# Inspired by Flan scan
# Usage: sudo ./scan.sh [-r recipient_email] [nmap_options]
# Requirements: root privileges, scan.ips file with target IPs
# Tested on: Debian 9+, Ubuntu 18.04+

set -e  # Exit on error

# Configuration
RECIPIENT_EMAIL="${SCAN_RECIPIENT:-user@example.com}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XML_DIR="${SCRIPT_DIR}/xml_files"
NMAP_SCRIPTS_DIR="/usr/share/nmap/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check required files
check_prerequisites() {
    if [ ! -f "${SCRIPT_DIR}/scan.ips" ]; then
        log_error "File scan.ips not found in ${SCRIPT_DIR}"
        log_error "Please create a file with IP addresses to scan (one per line)"
        exit 1
    fi
    
    if [ ! -s "${SCRIPT_DIR}/scan.ips" ]; then
        log_error "File scan.ips is empty"
        exit 1
    fi
}

# Install package if not present
install_package() {
    local pkg=$1
    if [ $(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        log_info "Installing $pkg..."
        apt-get update -qq
        apt-get --assume-yes install "$pkg" || {
            log_error "Failed to install $pkg"
            exit 1
        }
    fi
}

# Install required packages
install_dependencies() {
    log_info "Checking dependencies..."
    install_package "tar"
    install_package "git"
    install_package "nmap"
    install_package "mailutils"
    install_package "xsltproc"
    install_package "mutt"
    log_info "All dependencies installed"
}

# Parse command line arguments
parse_args() {
    while getopts "r:h" opt; do
        case $opt in
            r)
                RECIPIENT_EMAIL="$OPTARG"
                log_info "Using custom recipient: $RECIPIENT_EMAIL"
                ;;
            h)
                echo "Usage: $0 [-r recipient_email] [nmap_options]"
                echo "  -r EMAIL    Set recipient email address"
                echo "  -h          Show this help message"
                echo ""
                echo "Environment variables:"
                echo "  SCAN_RECIPIENT    Default recipient email (default: user@example.com)"
                exit 0
                ;;
            \?)
                log_error "Invalid option: -$OPTARG"
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
    NMAP_EXTRA_ARGS="$@"
}

# Define current time and output filename
setup_output_dir() {
    current_time=$(date "+%Y.%m.%d-%H.%M")
    
    # Create XML directory if it doesn't exist
    if [ ! -d "$XML_DIR" ]; then
        log_info "Creating output directory: $XML_DIR"
        mkdir -p "$XML_DIR" || {
            log_error "Failed to create directory $XML_DIR"
            exit 1
        }
    fi
    
    filename="${XML_DIR}/${current_time}.xml"
    filename_html="${XML_DIR}/${current_time}.html"
}

# Download or update vulners script
update_vulners_script() {
    log_info "Checking vulners script..."
    
    if [ -d "${NMAP_SCRIPTS_DIR}/vulners" ]; then
        log_info "Vulners script exists, updating..."
        cd "${NMAP_SCRIPTS_DIR}/vulners"
        git pull --quiet || log_warn "Failed to update vulners script, continuing with existing version"
        cd "$SCRIPT_DIR"
    else
        log_info "Cloning vulners script..."
        git clone --quiet https://github.com/vulnersCom/nmap-vulners "${NMAP_SCRIPTS_DIR}/vulners" || {
            log_error "Failed to clone vulners script"
            exit 1
        }
    fi
    
    log_info "Updating nmap script database..."
    nmap --script-updatedb || log_warn "Failed to update nmap script database"
}

# Run nmap scan
run_scan() {
    log_info "Starting nmap scan..."
    log_info "Target file: ${SCRIPT_DIR}/scan.ips"
    log_info "Output XML: $filename"
    log_info "Output HTML: $filename_html"
    
    # Run scan with error handling
    # Remove -Pn if scanning hosts that may block ICMP
    nmap -Pn -sV -oX "$filename" -oN - -v1 $NMAP_EXTRA_ARGS --script=vulners/vulners.nse -iL "${SCRIPT_DIR}/scan.ips" || {
        log_error "Nmap scan failed"
        exit 1
    }
    
    # Verify scan output was created
    if [ ! -f "$filename" ]; then
        log_error "Scan failed: XML output file not created"
        exit 1
    fi
    
    log_info "Scan completed successfully"
}

# Convert XML to HTML
convert_to_html() {
    log_info "Converting XML to HTML..."
    xsltproc -o "$filename_html" "$filename" || {
        log_error "Failed to convert XML to HTML"
        exit 1
    }
    
    if [ ! -f "$filename_html" ]; then
        log_error "HTML file was not created"
        exit 1
    fi
    
    log_info "HTML report generated: $filename_html"
}

# Pack results
pack_results() {
    log_info "Packing results..."
    tar -czf "${XML_DIR}/results_${current_time}.tar.gz" -C "$XML_DIR" "$(basename $filename)" "$(basename $filename_html)" || {
        log_error "Failed to pack results"
        exit 1
    }
    
    archive_file="${XML_DIR}/results_${current_time}.tar.gz"
    log_info "Results packed: $archive_file"
}

# Send email with results
send_email() {
    log_info "Sending results to: $RECIPIENT_EMAIL"
    
    # Check if mail command is available
    if command -v mutt &> /dev/null; then
        echo "See results in attachment" | mutt -s "Nmap Scan Results (${current_time})" -a "$archive_file" -- "$RECIPIENT_EMAIL" || {
            log_error "Failed to send email with mutt"
            exit 1
        }
    elif command -v mail &> /dev/null; then
        # Fallback to mail command with encoded attachment
        log_warn "mutt not found, using mail command (attachment may not work properly)"
        cat "$archive_file" | mail -s "Nmap Scan Results (${current_time})" -a "Content-Type: application/octet-stream" -a "Content-Disposition: attachment; filename=results.tar.gz" "$RECIPIENT_EMAIL" || {
            log_error "Failed to send email"
            exit 1
        }
    else
        log_error "No mail client found (mutt or mail)"
        exit 1
    fi
    
    log_info "Email sent successfully"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script failed with exit code: $exit_code"
        log_info "Partial results may be available in $XML_DIR"
    fi
}

# Main execution
main() {
    trap cleanup EXIT
    
    log_info "=== Nmap Vulners Scanner ==="
    
    # Initialize
    parse_args "$@"
    check_root
    check_prerequisites
    install_dependencies
    
    # Setup
    setup_output_dir
    update_vulners_script
    
    # Execute scan
    run_scan
    convert_to_html
    pack_results
    
    # Report
    send_email
    
    log_info "=== Scan Complete ==="
    log_info "Results saved in: $XML_DIR"
}

# Run main function with all arguments
main "$@"
