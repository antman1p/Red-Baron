#!/bin/bash

# Basic IPTABLES Template Script
# Author: Joe Vest, Andrew Chiles, Antonio Piazza

# Description:
#       Template script to protect C2 infrastructure.
#
# Note: Run this script on your teamservers!
#
#
# Parameter Reference: 
#    ALLOWED_PORTS - ports allowed to the team server
#    ALLOWED_PORTS_REDIR - ports allowed to the redirector
#    TEAM_RANGE    - skidkrew vpn public IP address range
#    INTERFACE     - Interface name
#    REDIR_RANGE   - Redirector IP range
#
# Usage
#   1) Modify the parameters to fit your needs
#   2) run script

# Check an make sure there is a command line argument.  This
# argument needs to be the redirector's public IP
if [ $# -lt 1 ]
	echo "Not enough arguments"
	exit 1
fi


# TODO: ensure your listener ports are contained in the list below!!!
ALLOWED_PORTS="50050,22"
ALLOWED_PORTS_REDIR="80,443"

# TODO: Team Source IP Space - REPLACE THIS WITH YOUR RANGE!!!
TEAM_RANGE="35.245.95.109"
# Need to figure out how to populate this redir addr automatically
REDIR_RANGE= $1


# System Settings
INTERFACE="eth0"
IPTABLES="/sbin/iptables"



# Start of script
echo "Basic iptables Configuration Script"
echo "Using the following variables..."
echo " TEAM_RANGE: $TEAM_RANGE"
echo " REDIR_RANGE: $REDIR_RANGE"
echo " Allowed Ports: $ALLOWED_PORTS"
echo " ALLOWED PORTS REDIR: $ALLOWED_PORTS_REDIR"
echo " Primary Interface: $INTERFACE"

# Flush all existing rules
echo " Clearing Existing Rules..."
$IPTABLES -F INPUT 
$IPTABLES -F FORWARD 
$IPTABLES -F OUTPUT 
$IPTABLES -F -t nat
$IPTABLES -F LOGGING

# Set default policies on each chain
echo " Setting Default Policies..."
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT

echo " Setting New Rules..."
# Open up C2 ports for access from redirector
$IPTABLES -A INPUT -i $INTERFACE -m multiport -s $REDIR_RANGE -p tcp --dports $ALLOWED_PORTS_REDIR -j ACCEPT
# Allow all access from team range
$IPTABLES -A INPUT -i $INTERFACE -m multiport -s $TEAM_RANGE -p tcp --dports $ALLOWED_PORTS -j ACCEPT
# Enable stateful firewall
$IPTABLES -A INPUT -i $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
# Enable all outbound traffic
$IPTABLES -A OUTPUT -o $INTERFACE -j ACCEPT
# Ensure loopback traffic is allowed
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Create logging for dropped packets
echo " Setting Logging..."
$IPTABLES -N LOGGING
$IPTABLES -A INPUT -j LOGGING
$IPTABLES -A LOGGING -m limit --limit 4/min -j LOG --log-prefix "IPTABLES-DROPPED "
$IPTABLES -A LOGGING -j DROP

echo "Done"
echo "Use iptables -L to view the rules"
echo "NOTE: These rules are not persistent !!!"
