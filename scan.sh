#/bin/bash
# script runs nmap with vulnerscom script and send results on email. Inspired by Flan scan
# download script

# run scan
nmap -sV -oX ./xml_files -oN - -v1 $@ --script=vulners/vulners.nse -iL scan.ips

# send email with results
