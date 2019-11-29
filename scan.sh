#/bin/bash
# script runs nmap with vulnerscom script generates and sends xml and html reports on email, inspired by Flan scan
# needed packages tar, git, nmap, mailutils, xsltproc
# needed list of IP addresses to scan in file scan.ips
# tested on Debian 9
# define current time and output filename
current_time=$(date "+%Y.%m.%d-%H.%M")
filename=xml_files/$current_time.xml
filename_html=xml_files/$current_time.html

# download script. To check repo
if [ -d "/usr/share/nmap/scripts/vulners" ] 
then
    git clone https://github.com/vulnersCom/nmap-vulners /tmp/vulners_$current_time
    rsync -a /tmp/vulners_$current_time /usr/share/nmap/scripts && nmap --script-updatedb
    rm -rf /tmp/vulners_$current_time
else
    git clone https://github.com/vulnersCom/nmap-vulners /usr/share/nmap/scripts/vulners && nmap --script-updatedb
fi

# run scan. Remove -Pn if all online hosts available by icmp
nmap -Pn -sV -oX $filename -oN - -v1 $@ --script=vulners/vulners.nse -iL ./scan.ips

# convert to html
xsltproc $filename o $filename_html

# pack results
tar -czf xml_files.tar.gz $filename $filename_html

# send email with results
echo "See results in attachment" | mutt -s "Scan results" -a xml_files.tar.gz -- user@example.com
