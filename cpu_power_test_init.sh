#!/system/bin/sh
big_little=$1
setenforce 0
echo 0 > /sys/devices/system/cpu/cpu7/online
echo 0 > /sys/devices/system/cpu/cpu6/online
echo 0 > /sys/devices/system/cpu/cpu5/online
echo 0 > /sys/devices/system/cpu/cpu4/online
echo 0 > /sys/devices/system/cpu/cpu3/online
echo 0 > /sys/devices/system/cpu/cpu2/online
echo 0 > /sys/devices/system/cpu/cpu1/online
echo 1 > /sys/power/wake_lock
if [ $big_little -eq 1 ];then
echo 1 > /sys/devices/system/cpu/cpu4/online
fi
