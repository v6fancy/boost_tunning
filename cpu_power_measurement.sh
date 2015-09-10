#!/bin/bash
isBL=$2
if [ $isBL -eq 1 ];then
	core=$1
	coreNUMs=4
else
	core=0
	coreNUMs=8
fi

path=`pwd`
cpu_power_test_init_script=cpu_power_test_init.sh
cpu_power_test_load_num_script=cpu_power_test_load_num.sh
big_cpu_power_test_load_freq_script=big_cpu_power_test_load_freq.sh
big_cpu_power_test_load_num_script=big_cpu_power_test_load_num.sh
little_cpu_power_test_load_freq_script=little_cpu_power_test_load_freq.sh
little_cpu_power_test_load_num_script=little_cpu_power_test_load_num.sh
burnCortexA9=burnCortexA9
#getAvgCurrent_script=../../utils/gpib/getAvgCurrent_66319d.py

mobile_name=`adb shell getprop ro.product.mobile.name`
if [[ $mobile_name == m86* ]];then
echo $mobile_name
adb shell "echo 1 > /sys/devices/system/march-hotplug/enable_march_thread_hotplug"
little_cpu_available_freq_path=/sys/devices/system/cpu/cpufreq/mp-cpufreq/cluster0_freq_table
big_cpu_available_freq_path=/sys/devices/system/cpu/cpufreq/mp-cpufreq/cluster1_freq_table
else
little_cpu_available_freq_path=/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
big_cpu_available_freq_path=/sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies
fi

tmp_data_path=data/local/tmp
if [ $core -eq 1 ];then
	power_table_text=big_power.txt
else
	power_table_text=little_power.txt
fi

function init(){
	if [ $1 -eq 1 ];then
		echo 'big core' > $power_table_text
	else
		echo 'little core' > $power_table_text
	fi
	echo '==============================================' >> $power_table_text
	echo 'num	freq		power(A)' >> $power_table_text
	if [ $isBL -eq 1 ];then
		adb push $path/$big_cpu_power_test_load_freq_script $tmp_data_path/
		adb push $path/$big_cpu_power_test_load_num_script $tmp_data_path/
		adb push $path/$little_cpu_power_test_load_num_script $tmp_data_path/
	else
		adb push $path/$cpu_power_test_load_num_script $tmp_data_path/
	fi
	adb push $path/$cpu_power_test_init_script $tmp_data_path/
	adb push $path/$little_cpu_power_test_load_freq_script $tmp_data_path/
	adb push $path/$burnCortexA9 $tmp_data_path/
	adb shell chmod 777 $tmp_data_path/* 
	adb shell ./$tmp_data_path/cpu_power_test_init.sh $1
}

function burnCortexA9Kill(){
	adb shell kill $(adb shell ps |awk '/burnCortexA9/{print $2}')	
}

#################################
# $1: online core numbers
################################
function burnCortexA9Exe(){
	num=0
	while(( $num < $1 ));do
		adb shell ./$tmp_data_path/$burnCortexA9 &
		let "num++"
	done
	echo "\n"
}

function getcurrent(){
	avg=`$path/$getAvgCurrent_script`
	echo $avg
}

##############################
# $1: little/big core, 0 is little core,1 is bigcore
# $2: core freq
#############################
function setFreq(){
	if [ $1 -eq 0 ];then
		adb shell ./$tmp_data_path/$little_cpu_power_test_load_freq_script $2
	else
       	 	adb shell ./$tmp_data_path/$big_cpu_power_test_load_freq_script $2
	fi
}

function checkLoad(){
	if [ $1 -eq 1 ];then
		load=`adb shell cat /sys/devices/system/cpu/cpu4/cpufreq/interactive/cpu_util`
	else
		load=`adb shell cat /sys/devices/system/cpu/cpu0/cpufreq/interactive/cpu_util`
	fi
	count=$[$(echo $load |grep -o "H_I*"|wc -l)+$(echo $load |grep -o "100*"|wc -l)]
	echo $count
}
############################
# $1: little/big core, 0 is little core,1 is bigcore
# $2: little core numbers
# $3: isBL, 0 isn't big/little core, 1 is big/little core
###########################
function setCoreNum(){
	if [ $3 -eq 1 ];then
		if [ $1 -eq 0 ];then
			adb shell ./$tmp_data_path/$little_cpu_power_test_load_num_script $2
		else
        		adb shell ./$tmp_data_path/$big_cpu_power_test_load_num_script $2
		fi
	else
        	adb shell ./$tmp_data_path/$cpu_power_test_load_num_script $2
	fi
}

####################################
# $1: core numbers
# $2: core freq
# $3: power(A)
###################################
function writeTxt(){
	echo "$1	$2		$3" >> $power_table_text
}

init $core 
if [ $core -eq 1 ];then
	freq=(`adb shell cat $big_cpu_available_freq_path`)
else
	freq=(`adb shell cat $little_cpu_available_freq_path`)
fi
for i in ${freq[@]}
do
	if [ ${#i} -eq 1 ];then
		continue
	else
	setFreq $core $i
	j=1
	count=0
	while(( $j <= $coreNUMs))
	do
		setCoreNum $core $j $isBL
		#TODO
		#call app lunch script
		perl app_bootup_speed.pl -f -c 1 -p m86 -b "$j-$i"
		sleep 1
                let "j++"

	done
	fi
done

#TODO
# after test finish, we need process the txt result file.
# and show in excel table.
