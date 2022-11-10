#!/bin/bash
# Program to output a system information page
var_diskSize_avail=$(df -h --output=avail,used,pcent /dev/sdb  | tail -1 | awk '{print $1}')
var_diskSize_used=$(df -h --output=avail,used,pcent /dev/sdb  | tail -1 | awk '{print $2}')
var_diskSize_pcent=$(df -h --output=avail,used,pcent /dev/sdb  | tail -1 | awk '{print $3}')
var_memory_used=$(free -g | awk '/^Mem:/{print $3}')
var_memory_avail=$(free -g | awk '/^Mem:/{print $7}')
var_swap_used=$(free -g | awk '/^Swap:/{print $3}')
var_swap_avail=$(free -g | awk '/^Swap:/{print $4}')
echo "<i>Master</i> \nDisk Size: Avail ${var_diskSize_avail}, Used ${var_diskSize_used}, Pcent ${var_diskSize_pcent} \nMemory: Avail ${var_memory_avail}G, Used ${var_memory_used}G \nSwap: Avail ${var_swap_avail}G, Used ${var_swap_used}G"