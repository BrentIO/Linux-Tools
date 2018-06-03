#!/bin/bash

# Updates the system with a single command line call to simplify my life
# /etc/P5Software/Linux-Tools/AutoUpdate.sh
# Brent Andrew Hendricks
# 3 June 2018

#Colors
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Make sure we're running as root
if ! [ $(id -u) = 0 ]; then
   echo -e "\n${RED}Please use sudo or root to run this script.${NC}\n"
   exit 1
fi

#Update the distribution, which shouldn't really be necessary but 
echo -e "\n${CYAN}Updating apt using dist-upgrade.${NC}"
apt-get dist-upgrade -y

responseCode=$?
if [ $responseCode != 0 ]; then
    echo -e "\n${RED}Error: ${NC}$responseCode"
    exit $responseCode
fi      

#Remove old package versions to save space
echo -e "\n${CYAN}Removing old packages.${NC}"
apt-get autoremove -y

responseCode=$?
if [ $responseCode != 0 ]; then
    echo -e "\n${RED}Error: ${NC}$responseCode"
    exit $responseCode
fi  

echo -e "\n${CYAN}Complete.${NC}"

#Notify the user if a reboot is required
if [ -f /var/run/reboot-required ]; then
  echo -e "\n${RED}A reboot is required.${NC}\n"
fi

exit 0