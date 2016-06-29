#!/bin/bash

####################################
#  Verify and Repair Disks Script  #
#  verifyrepairdisks.sh            #
#  Version 1.0                     #
#  By Jake Benedict                #
#  Franklin & Marsahll College     #
####################################    

#  Purpose  ################################################
#  -------                                                 #
#  To create an easier way to run Verify Disk Permissions  #
#  and Repair Disk Permissions on all mounted disks        #
############################################################

clear

#  Get the maximum possible number of paritions  #
numLines="$(diskutil list | grep -c ^)"

#  Create the disk array  #
listDisks=()

#  Fill the disk array with all mounted partitions, excluding EFI and Recovery HD  #
for ((i=1; i <= numLines ; i++)) ; do	
	item="$(diskutil list -plist | awk -F"<|>" '/VolumeName/ {getline;print $3}' | grep -v EFI | grep -v Recovery\ HD | head -$i | tail -1)"
	if [ "$item" = "${listDisks[$(($i-1))]}" ]; then
		listDisks[$i]="FINISHED"
		break
	else
		listDisks[$i]="$(diskutil list -plist | awk -F"<|>" '/VolumeName/ {getline;print $3}' | grep -v EFI | grep -v Recovery\ HD | head -$i | tail -1)"
	fi
done

#  For testing to make sure the disk list is properly filled  #
#for disk in "${listDisks[@]}"; do
#	echo "$disk"
#done

#  Display the disks for the user to choose from  #
printf "%b" "\a\n\nSelect a disk to fix or select FINISHED:\n" >&2
	select disk in "${listDisks[@]}"; do
		if [ "$disk" = "FINISHED" ]; then
			exit 0
		fi
		break
	done

#  Sets the mount point of the selected disk for verify and repair commands  #
mountPoint="$(diskutil info "$disk" | sed -n -e 's/^.*Mount Point: //p'| tr -d '[[:space:]]')"

#  For testign that the mount point for the disk is correct  #
#echo "$mountPoint"

#  Creates the repair choices array  #
declare -a repairChoices=("Verify" "Repair" "CANCEL")

#  Allows the user to choose whether to verify or repair disk permissions, or cancel  #
printf "%b" "\a\n\nWould you like to Verify or Repair the Disk Permissions, or CANCEL?:\n" >&2
	select choice in "${repairChoices[@]}"; do
		if [ "$choice" = "Verify" ]; then
			echo "Verifying '$disk'"
			sudo /usr/libexec/repair_packages --verify --standard-pkgs "$mountPoint"
			break
		elif [ "$choice" = "Repair" ]; then
			echo "Repairing '$disk'"
			sudo /usr/libexec/repair_packages --repair --standard-pkgs --volume "$mountPoint"
			break
		fi
			break
	done