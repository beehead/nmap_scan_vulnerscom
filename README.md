# nmap scan vulnerscom script

## plan to make on bash
Install nmap, download vulners script, scans and sends result on email

## description
Script runs nmap with vulnerscom script and send results on email, ispired by Flan scan. You need installed tar, git, nmap, nmap-scripts, mailutils, xsltproc and file scan.ips in working directory, that contains list of IP addresses. Tested on Debian 9.

To run use `./scan.sh`, no parameters needed.
