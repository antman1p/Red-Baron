#!/bin/bash

# Basic IPTABLES Template Script
# Author: Joe Vest, Andrew Chiles

# Description:
#       Template script to protect ATRTO C2 infrastructure.
#
# Note: Run this script on both your teamservers AND redirectors!
#       AND BE SURE TO REPLACE TEAM_RANGE WITH YOUR STUDENT RANGE!
#
# Parameter Reference: 
#    ALLOWED_PORTS - port allowed from the anywhere
#    TEAM_RANGE    - IP range allowed to connect to all ports
#    INTERFACE     - Interface name
#
# Usage
#   1) Modify the parameters to fit your needs
#   2) run script


# TODO: ensure your listener ports are contained in the list below!!!
ALLOWED_PORTS="50050,22"
ALLOWED_PORTS_REDIR="443"

# TODO: Team Source IP Space - REPLACE THIS WITH YOUR RANGE!!!
TEAM_RANGE="35.245.95.109"
REDIR_RANGE="35.236.194.228"


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
