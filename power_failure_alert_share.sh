#/bin/bash

#script to email me before shutdown because of power failure.

#gets battery status
status=$(pmset -g batt)
#gets local hostname
hostname=$(hostname -f)
#gets inside ip address via route get command and extracting the active interface
ip_inside=$(ipconfig getifaddr $(route get 1.1.1.1 | awk '/interface: / {print $2; }'))
#gets the outside IP from curl. -s shouldn't give any transmit information
ip_outside=$(curl -s ifconfig.co)
#gets dns server ip address by doing an nslookup against another computer and seeing which dns server responds.
#MUST HAVE 2X TABS after 'Server:' in sed command, otherwise output to variable does not work.
dns_server=$(nslookup 1.1.1.1 | grep Server | sed 's/\Server:		//g')

#uses dig to get fqdn from dns server. -x is a reverse lookup. +short only gives dns name without extra info
fqdn=$(dig @"$dns_server" +short -x $ip_inside)

# if the output of the following command has a word count of 0, then set fqdn_bool to true. if it has anything other than a word count of 0, set it to false.
if [[ $(dig @"$dns_server" +short -x $ip_inside | wc -c) -ne 0 ]]; then
	fqdn_bool=1
else
	fqdn_bool=0
fi

#if that fqdn_bool is true, then use the $fqdn variable, otherwise use the regular hostname
if [[ $fqdn_bool -eq 1 ]] ; then
	best_name=$fqdn
else
	best_name=$hostname
fi

#if the file ps_output.txt exists, then erase it. 
if [ -f /Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/ps_output.txt ]; then
	rm /Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/ps_output.txt
fi

#gets battery status. if battery status includes the word "discharging" then use above information to send email.
pmset -g batt | grep discharging > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
	echo -e "The Computer $best_name at IP $ip_inside, $ip_outside has detected a power failure. \n" >> /Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/ps_output.txt
	echo -e "$status \n" >> /Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/ps_output.txt &&
	echo -e "Following is a list of top Processes by CPU usage" >> /Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/ps_output.txt &&
	ps aucSC -A | head -n 20 | column -t -s $'\t' >> /Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/ps_output.txt &&
	/usr/local/bin/sendEmail -f fromemail@email.com  -t toemail@email.com -u "Power Failure Notification" -s smtp.gmail.com:587 -o message-file=/Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/ps_output.txt -o tls=yes -xu username -xp password > /dev/null 2>&1

else
	echo "All Quiet On The Western Front" > /Users/tylerkspencer/iCloudDocs/Personal\ Projects/Power\ Failure/previous_status.txt
fi



