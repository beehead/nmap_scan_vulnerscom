# Nmap Vulners Scanner

Automated network vulnerability scanning script using nmap and vulners NSE script, with HTML/XML report generation and email delivery.

## Features

- ✅ Automatic dependency installation
- ✅ Root privilege verification
- ✅ Configurable email recipient via CLI or environment variable
- ✅ Color-coded logging with progress indicators
- ✅ Error handling and validation at each step
- ✅ Automatic vulners script update
- ✅ XML and HTML report generation
- ✅ Compressed results archive
- ✅ Email delivery with attachment
- ✅ Support for custom nmap options

## Requirements

- **Operating System**: Debian 9+, Ubuntu 18.04+ (or any Debian-based distro)
- **Privileges**: Root access (sudo)
- **Dependencies**: tar, git, nmap, mailutils, xsltproc, mutt (auto-installed)

## Installation

```bash
git clone https://github.com/your-repo/nmap-vulners-scan.git
cd nmap-vulners-scan
```

## Configuration

### 1. Create Target List

Create a `scan.ips` file with IP addresses to scan (one per line):

```bash
cp scan.ips.example scan.ips
# Edit scan.ips with your target IPs
nano scan.ips
```

**Format examples:**
```
192.168.1.1
192.168.1.0/24
10.0.0.1
example.com
```

⚠️ **Legal Notice**: Only scan networks you own or have explicit written permission to scan.

### 2. Configure Email Recipient

Set the default recipient via environment variable (optional):

```bash
export SCAN_RECIPIENT="security@example.com"
```

Or specify it at runtime with `-r` flag.

## Usage

### Basic Scan

```bash
sudo ./scan.sh
```

### With Custom Email

```bash
sudo ./scan.sh -r security@example.com
```

### With Additional Nmap Options

```bash
sudo ./scan.sh -r security@example.com --min-rate 100
```

### Show Help

```bash
./scan.sh -h
```

## Output

Results are stored in `xml_files/` directory:
- `YYYY.MM.DD-HH.MM.xml` - Raw nmap XML output
- `YYYY.MM.DD-HH.MM.html` - Human-readable HTML report
- `results_YYYY.MM.DD-HH.MM.tar.gz` - Compressed archive of both files

The archive is automatically sent to the configured email address.

## Script Flow

1. **Validation**: Checks root privileges and required files
2. **Dependencies**: Installs missing packages automatically
3. **Vulners Update**: Clones or updates vulners NSE script
4. **Scanning**: Runs nmap with vulners script against targets
5. **Conversion**: Converts XML report to HTML format
6. **Packaging**: Creates compressed archive of results
7. **Delivery**: Sends results via email

## Troubleshooting

### Common Issues

**"This script must be run as root"**
```bash
sudo ./scan.sh
```

**"File scan.ips not found"**
```bash
cp scan.ips.example scan.ips
# Edit with your targets
```

**Email delivery fails**
- Ensure MTA (Mail Transfer Agent) is configured on your system
- Check `/var/log/mail.log` for delivery errors
- Verify recipient email address is correct

**Nmap scan takes too long**
- Reduce scope in `scan.ips`
- Add timing options: `sudo ./scan.sh --min-rate 100 --max-retries 2`

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SCAN_RECIPIENT` | Default email recipient | `user@example.com` |

## Command Line Options

| Option | Description |
|--------|-------------|
| `-r EMAIL` | Set recipient email address |
| `-h` | Show help message |

## Security Considerations

- Run only on networks you own or have authorization to scan
- Results contain sensitive vulnerability information - protect accordingly
- Email transmission is not encrypted by default - consider using secure mail transport
- Store `scan.ips` securely as it contains target infrastructure information

## License

GPL v3 - See [LICENSE](LICENSE) file for details

## Credits

- Inspired by [Flan Scanner](https://github.com/flant/flan)
- Uses [vulners NSE script](https://github.com/vulnersCom/nmap-vulners)

## Contributing

Contributions welcome! Please submit issues and pull requests.
	
