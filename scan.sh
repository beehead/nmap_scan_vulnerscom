#/bin/bash
# needed packages tar, git, nmap, nmap-scripts, mailutils
# needed list of IP addresses to scan in file scan.ips
# script runs nmap with vulnerscom script and send results on email. Inspired by Flan scan
# download script. To check repo
git clone https://github.com/vulnersCom/nmap-vulners /usr/share/nmap/scripts/vulners && nmap --script-updatedb

# run scan. To check keys
nmap -sV -oX ./xml_files -oN - -v1 $@ --script=vulners/vulners.nse -iL ./scan.ips

# pack results
tar -cfz xml_files.tar.gz ./xml_files

# send email with results
echo "See results in attachment" | mail -s "Scan results" -A xml_files.tar.gz user@example.com
