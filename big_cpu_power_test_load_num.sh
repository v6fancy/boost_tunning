#!/system/bin/sh
coreNum=$1
if [ $coreNum -eq 4 ];then
    echo 1 > /sys/devices/system/cpu/cpu7/online
    echo 1 > /sys/devices/system/cpu/cpu6/online
    echo 1 > /sys/devices/system/cpu/cpu5/online
    echo 1 > /sys/devices/system/cpu/cpu4/online
elif [ $coreNum -eq 3 ];then
    echo 0 > /sys/devices/system/cpu/cpu7/online
    echo 1 > /sys/devices/system/cpu/cpu6/online
    echo 1 > /sys/devices/system/cpu/cpu5/online
    echo 1 > /sys/devices/system/cpu/cpu4/online
elif [ $coreNum -eq 2 ];then
    echo 0 > /sys/devices/system/cpu/cpu7/online
    echo 0 > /sys/devices/system/cpu/cpu6/online
    echo 1 > /sys/devices/system/cpu/cpu5/online
    echo 1 > /sys/devices/system/cpu/cpu4/online
elif [ $coreNum -eq 1 ];then
    echo 0 > /sys/devices/system/cpu/cpu7/online
    echo 0 > /sys/devices/system/cpu/cpu6/online
    echo 0 > /sys/devices/system/cpu/cpu5/online
    echo 1 > /sys/devices/system/cpu/cpu4/online
else
    echo "Range of core numbers is 1~4"
fi
