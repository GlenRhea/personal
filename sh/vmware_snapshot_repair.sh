#!/bin/sh
#vmware abandoned snapshot repair script

#check to see if the snapshot removal has finished
check_progress() {
	echo "Waiting on task: $1"
	echo -n "Progress (every dot is $2 seconds): "
	while true; do
		getstate=$(vim-cmd vimsvc/task_info $1|grep "state"|sed 's/"//g')                 
		if echo $getstate | grep -q "state = running,"; then
			#redneck progress bar
			echo -n "."
			#sleep for 1 minute
			sleep $2
		else
			echo "breaking"
			break
		fi
		done
}

#check to see if the arg exists
if [ -z "$1" ]; then
    echo "Please add the server name as the first argument! E.g. $0 servername"
    exit 1
fi

echo "Working on VM: $1"
echo "Getting VM ID..."
vmid=$(vim-cmd vmsvc/getallvms  | grep -i $1 | awk '{print $1}')
echo "Consolidating disks on VM $1 with VMID: $vmid"
#apparently there isn't a CLI command to do the disk consolidation so it has to be started with the UI
#and then you can run this script

#now get the task name e.g. haTask-49-vim.VirtualMachine.removeAllSnapshots-5899780
taskname=$(vim-cmd vmsvc/get.tasklist $vmid| grep -i "consolidateDisks" | awk -F ":" '{print $2}'|sed "s/'/ /g")
check_progress $taskname 600
echo "Task completed."

echo "Renaming the VMSD"
#rename the vmsd
mv $1.vmsd $1.vmsd.bak
echo "Task completed."

echo "Creating snapshot."
#create snapshot
vim-cmd vmsvc/snapshot.create $vmid test
taskname=$(vim-cmd vmsvc/get.tasklist $vmid| grep -i "Snapshot" | awk -F ":" '{print $2}'|sed "s/'/ /g")
check_progress $taskname 60
echo "Task completed."


#remove all snapshots
echo "Removing all snapshots on VM $1 with VMID: $vmid"
vim-cmd vmsvc/snapshot.removeall $vmid
taskname=$(vim-cmd vmsvc/get.tasklist $vmid| grep -i "removeAllSnapshots" | awk -F ":" '{print $2}'|sed "s/'/ /g")
check_progress $taskname 600
echo "Task completed."

#delete the files after the snapshot removal is complete
echo "Moving all the leftover delta files to a tmp folder."
mkdir -p tmp
mv *000* tmp
echo "Task completed."