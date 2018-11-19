#!/bin/bash

#this script will clean out all the old kernels

#output the current kenel
curr=$(uname -r)
echo "The current kernel is: $curr"
echo

#now get all the installed kernels EXCEPT the running one
echo "Here is the list of all the kernels that will be cleaned."
dpkg -l linux-{image,headers}-"[0-9]*" | awk '/ii/{print $2}' | grep -ve "$(uname -r | sed -r 's/-[a-z]+//')"
echo

#now ask the user if they want to remove all the old kernels
echo "Would you like to clean all the old kernels out? (y/n)"
read input

#check the inputted value
checkval=$(echo $input|grep -ic "y")

if [ $checkval -eq 1 ]
then
        echo "Removing all the old kernels..."
        apt-get -q -y purge $(dpkg -l linux-{image,headers}-"[0-9]*" | awk '/ii/{print $2}' | grep -ve "$(uname -r | sed -r 's/-[a-z]+//')")
        echo
        echo "All old kernels removed!"
        echo
        echo "Current space in /boot:"
        df -h|grep "boot"
        exit 0
else
        echo "Not remvoing the old kernels!"
        exit 1
fi
