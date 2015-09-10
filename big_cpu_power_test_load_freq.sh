#!/system/bin/sh
freq=$1

curFreq=`cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq`

echo $curFreq $freq
while true
do
if [ $curFreq -gt $freq ];then
    echo "-->"
    echo $freq > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
    sleep 1
    echo $freq > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
else
    echo "<--"
    echo $freq > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    sleep 1
    echo $freq > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
fi
curFreq=`cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq`
echo $curFreq $freq
if [ $curFreq -eq $freq ];then
    break;
fi
done
