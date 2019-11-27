#/bin/bash
# needed packages tar, git, nmap, mailutils, xsltproc
# needed list of IP addresses to scan in file scan.ips
# script runs nmap with vulnerscom script and send results on email. Inspired by Flan scan
# tested on Debian 9
# define current time and output filename
current_time=$(date "+%Y.%m.%d-%H.%M")
filename=xml_files/$current_time.xml
filename_html=xml_files/$current_time.html

# download script. To check repo
git clone https://github.com/vulnersCom/nmap-vulners /usr/share/nmap/scripts/vulners && nmap --script-updatedb

# run scan. To check keys
nmap -Pn -sV -oX $filename -oN - -v1 $@ --script=vulners/vulners.nse -iL ./scan.ips

# convert to html
xsltproc $filename o $filename_html

# pack results
tar -czf xml_files.tar.gz $filename $filename_html

# send email with results
echo "See results in attachment" | mutt -s "Scan results" -a xml_files.tar.gz -- user@example.com
