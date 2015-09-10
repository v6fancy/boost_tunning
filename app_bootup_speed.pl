################################################################################
#
# Purpose: Used to measure the performance of launching application. 
# 
# Update History:
# 
################################################################################
use utf8;
#use warnings;
#use strict;
use GD::Graph::bars;
use GD::Graph::lines;
use GD::Graph::Data;
use Getopt::Std;

################################################################################
#
# TODO: Optimize this global variable.
################################################################################
sub by_number { $a <=> $b; }

################################################################################
#
# TODO: Optimize this global variable.
################################################################################
my (%Package_Acvitity_Hash);
my (%Package_WaitTime_Hash);
my ($PRODUCT);
my ($BUILD_TIME);
my ($FLYME_APPLICATION) = "./database/flyme_app_list.txt";
my ($THIRD_PART_APPLICATION) = "./database/third_app_list.txt";
my ($REFERENCE_APPLICATION_NAME) = "Reference";
################################################################################
#
################################################################################
my ($COMMAND_FORCE_STOP) = "adb shell am force-stop ";
my ($COMMAND_LAUNCH_ACTIVITY) = "adb shell am start -W";
my ($COMMAND_SHOW_ALL_PROCESS) = "adb shell ps";
my ($SLEEP_TIME_AFTER_KILL_PROCESS) = 3;


################################################################################
#
################################################################################
sub parse_Package_List {
    if (@_ != 1) {
        die "get_Total_Pss_Module_Info: Only support on parameter!\n";
    }
    my ($file_name) = @_;
    open DATA, '<', "${file_name}" or
        die "parse_Package_List: Can't open ${file_name}. $!\n";
    my (@result_array);

    while (<DATA>) {
        chomp;
        if ($_ =~ /(?<APP_NAME>\S+):(?<PACK_ACTIVITY_NAME>\S+)/) {
            $Package_Acvitity_Hash{$+{APP_NAME}} = $+{PACK_ACTIVITY_NAME};
            push @result_array, $+{APP_NAME};
        }
    }

    my($DEBUG) = (0);
    if ($DEBUG) {
        while (($key, $value) = each %Package_Acvitity_Hash) {
            print "=> $key - $value \n";
        }
    }

    close DATA;
    return @result_array;    
}


################################################################################
#
################################################################################
sub process_App_Launch_Action {
    my ($package_activity_name) = @_;
        
    #1: prepare kill
    &kill_Process($package_activity_name);
    exec(sleep $SLEEP_TIME_AFTER_KILL_PROCESS);

    #2: Check heartbeat
    if (&check_Process($package_activity_name)) {
        #TODO: Log it to the report file.
        print "do_Launch_Activity_Action: Can't Kill ${package_activity_name} \n";
    }

    #3: Launch
    my($consumed_time) = &launch_Process($package_activity_name);

    #4: stage clear kill
    &kill_Process($package_activity_name);
    exec(sleep $SLEEP_TIME_AFTER_KILL_PROCESS);

    return $consumed_time;
}


################################################################################
#
################################################################################
sub kill_Process {
    my ($DEBUG) = 0;
    my ($activity_name) = @_;
    if ($DEBUG) {print "kill_Process: Start to kill! $activity_name\n";}
    if ($activity_name =~ m<(?<PACAKAGE_NAME>\S+)/(?<ACTIVITY_NAME>\S+)>) {
        if ($DEBUG) {print "kill_Process: Target: $+{PACAKAGE_NAME} \n";}
        qx($COMMAND_FORCE_STOP $+{PACAKAGE_NAME});
    }
}


################################################################################
#
################################################################################
sub check_Process {
    my ($DEBUG) = 0;
    my ($activity_name) = @_;
    if ($activity_name =~ m<(?<PACAKAGE_NAME>\S+)/(?<ACTIVITY_NAME>\S+)>) {
        my (@all_process) = qx($COMMAND_SHOW_ALL_PROCESS);
        foreach (@all_process) {
            chomp;
            if ($_ =~ m((?<FOUND_ITEM>$+{PACAKAGE_NAME}))) {
                if ($DEBUG) {print "check_Process: Found process: $+{FOUND_ITEM} \n";}
                return 1;
            }            
        }
    }
    if ($DEBUG) {print "check_Process: Not Found process: $+{PACAKAGE_NAME} \n";}
    return 0;
}


################################################################################
#
################################################################################
sub launch_Process {
    my ($DEBUG) = 1;
    my ($activity_name) = @_;
    my (@launch_result) = qx($COMMAND_LAUNCH_ACTIVITY $activity_name);
    
    foreach (@launch_result) {
        chomp;
        if ($_ =~ /WaitTime: (?<CONSUME_TIME>[0-9]+)/) {
            if ($DEBUG) {print "launch_Process WaitTime: $+{CONSUME_TIME} \n";}
            return $+{CONSUME_TIME};
        }
    }
    return 0;
}


################################################################################
#Accepting two arrays to generate Bar diagram
#  generate2DBar(array names,
#                array values,
#                string title,
#                string x_label,
#                string y_label,
#                string filename,
#                int width,
#                int height)
################################################################################
sub generate2DBar {
    my(
        $names_, 
        $values_, 
        $title_, 
        $xLable_, 
        $yLabel_, 
        $fileName_, 
        $width_, 
        $height_,
        $barColor_) = @_;
    if (@_ < 2) {
        die "generateBar: Should input at least 2 parameters!\n";
    }

    if ($title_ eq undef) {$title_ = "No_title";}
    if ($xLable_ eq undef) {$xLable_ = "No_Comments";}
    if ($yLabel_ eq undef) {$yLabel_ = "No_Comments";}
    if ($fileName_ eq undef) {$fileName_ = "No_Comments";}
    # if ($width_ == undef) {$width_ = 800;}
    # if ($height_ == undef) {$height_ = 500;}
    if ($barColor_ eq undef) {$barColor_ = "green";}

    if ($width_ == -1 || $height_ == -1) {
        my ($num_of_names, $num_of_values) = (0, 0);
        $num_of_names += @$names_;
        $num_of_values += @$values_;

        my ($width_scalar, $height_scalar) = (78, 40);
        $width_ = $num_of_names * $width_scalar;
        $height_ = $num_of_values * $height_scalar;
    }

    if ($DEBUG) {
        print "generate2DBar: names_: @$names_ \n";
        print "generate2DBar: values_: @$values_ \n";
        print "generate2DBar: title_: $title_ \n";
        print "generate2DBar: xLable_: $xLable_ \n";
        print "generate2DBar: yLabel_: $yLabel_ \n";
        print "generate2DBar: fileName_: $fileName_ \n";
        print "generate2DBar: width_: $width_ \n";
        print "generate2DBar: height_: $height_ \n";
    }

    #Create essential data
    my @x_label_array = @$names_;
    my @y_data_array = @$values_;
    my $data = GD::Graph::Data->new([
         [@x_label_array],
         [@y_data_array],
    ]) or die GD::Graph::Data->error;

    #Setup the decor image
    my $graph = GD::Graph::bars->new($width_, $height_);
    $graph->set( 
        x_label         => $xLable_,
        y_label         => $yLabel_,
        title           => $title_,
        #y_max_value     => 20,
        #y_tick_number   => 20,
        x_labels_vertical => 1,
        #bar_width       => 25,
        shadow_depth    => 4,
        show_values     => 1,
        transparent     => 0,
        dclrs           => [$barColor_],
    ) or die $graph->error;

    my $FONT_TYPE = "/usr/share/fonts/truetype/ubuntu-font-family/Ubuntu-M.ttf";
    $graph->set_title_font($FONT_TYPE, 25);

    $graph->set_x_label_font($FONT_TYPE, 16);
    $graph->set_y_label_font($FONT_TYPE, 16);

    $graph->set_x_axis_font($FONT_TYPE, 14);
    $graph->set_y_axis_font($FONT_TYPE, 9);

    $graph->set_values_font($FONT_TYPE, 15);

    #Image Generating
    $graph->plot($data) or die $graph->error;

    #File Generating
    my $file = $fileName_;
    open(my $out, '>', $file) or die "Cannot open '$file' for write: $!";
    binmode $out;
    print $out $graph->gd->png;
    close $out;
}


################################################################################
#Accepting two arrays to generate line diagram
################################################################################
sub generate2DLines {
    my(
        $names_, 
        $values_, 
        $ref_values_,
        $title_, 
        $xLable_, 
        $yLabel_, 
        $fileName_, 
        $width_, 
        $height_,
        $barColor_) = @_;
    if (@_ < 2) {
        die "generateBar: Should input at least 2 parameters!\n";
    }

    if ($title_ eq undef) {$title_ = "No_title";}
    if ($xLable_ eq undef) {$xLable_ = "No_Comments";}
    if ($yLabel_ eq undef) {$yLabel_ = "No_Comments";}
    if ($fileName_ eq undef) {$fileName_ = "No_Comments";}
    # if ($width_ == undef) {$width_ = 800;}
    # if ($height_ == undef) {$height_ = 500;}]
    if ($barColor_ eq undef) {$barColor_ = "green";}

    if ($width_ == -1 || $height_ == -1) {
        my ($num_of_names, $num_of_values) = (0, 0);
        $num_of_names += @$names_;
        $num_of_values += @$values_;

        my ($width_scalar, $height_scalar) = (78, 40);
        $width_ = $num_of_names * $width_scalar;
        $height_ = $num_of_values * $height_scalar;
    }

    my $DEBUG  = 0;
    if ($DEBUG) {
        print "generate2DLines: names_: @$names_ \n";
        print "generate2DLines: values_: @$values_ \n";
        print "generate2DLines: ref values_: @$ref_values_ \n";
        print "generate2DLines: title_: $title_ \n";
        print "generate2DLines: xLable_: $xLable_ \n";
        print "generate2DLines: yLabel_: $yLabel_ \n";
        print "generate2DLines: fileName_: $fileName_ \n";
        print "generate2DLines: width_: $width_ \n";
        print "generate2DLines: height_: $height_ \n";
    }

    #Create essential data
    my @x_label_array = @$names_;
    my @y_data_array = @$values_;
    my @y_ref_data_array = @$ref_values_;
    my $data = GD::Graph::Data->new([
         [@x_label_array],
         [@y_data_array],
         [@y_ref_data_array],
    ]) or die GD::Graph::Data->error;

    #Setup the decor image
    my $graph = GD::Graph::lines->new($width_, $height_);
    $graph->set( 
        x_label         => $xLable_,
        y_label         => $yLabel_,
        title           => $title_,
        line_width      => 5,
        line_types      => [1, 1], #1: solid, 2: dashed, 3: dotted, 4: dot-dashed.
        #y_max_value     => 20,
        #y_tick_number   => 20,
        x_labels_vertical => 1,
        #bar_width       => 25,
        shadow_depth    => 4,
        show_values     => 1,
        transparent     => 0,
        dclrs           => [$barColor_, "black"], #app color, ref color
    ) or die $graph->error;

    my $FONT_TYPE = "/usr/share/fonts/truetype/ubuntu-font-family/Ubuntu-M.ttf";

    $graph->set_legend($title_, "Reference_app");
    $graph->set_legend_font($FONT_TYPE, 15);

    $graph->set_title_font($FONT_TYPE, 25);

    $graph->set_x_label_font($FONT_TYPE, 16);
    $graph->set_y_label_font($FONT_TYPE, 16);

    $graph->set_x_axis_font($FONT_TYPE, 14);
    $graph->set_y_axis_font($FONT_TYPE, 9);

    $graph->set_values_font($FONT_TYPE, 15);

    #Image Generating
    $graph->plot($data) or die $graph->error;

    #File Generating
    my $file = $fileName_;
    open(my $out, '>', $file) or die "Cannot open '$file' for write: $!";
    binmode $out;
    print $out $graph->gd->png;
    close $out;
}


################################################################################
#
################################################################################
sub get_Almost_Average_Value {
    my ($array_data, $loop_count) = @_;

    if ($loop_count >= 6) {
        $loop_count = $loop_count / 6; #3 / 2

        for (my $i = 0; $i < $loop_count; $i++) {
            shift @${array_data};
            pop @${array_data};
        }
    }

    my ($count, $sum) = (0, 0);
    $count = @${array_data};
    foreach (@${array_data}) {
        $sum += ${_};
    }     
    return int($sum / $count);
}


################################################################################
# 
################################################################################
sub do_Launch_App_Measure_Task {
    my ($app_list, $loop_count) = @_;

    for (my $i = 0; $i < $loop_count; $i++) {
        foreach (@${app_list}) {
            print "=> ${_} - $Package_Acvitity_Hash{$_} \n";

            unless (defined ($Package_WaitTime_Hash{$_})) {
                $Package_WaitTime_Hash{$_} = [];       
            }
            my ($wait_time_array) = $Package_WaitTime_Hash{$_};
            push @${wait_time_array}, &process_App_Launch_Action($Package_Acvitity_Hash{$_});
        }
    }

    my ($log_handler) = &acquire_Target_Logging_File_Handle($PRODUCT, $BUILD_TIME);
    
    foreach (@${app_list}) {
        my ($wait_time);
        $wait_time = $Package_WaitTime_Hash{$_};
        @${wait_time} = sort by_number @${wait_time};
        print $log_handler "Detailed: $_ - @${wait_time} \n";
        print "Detailed: $_ - @${wait_time} \n";
        $Package_WaitTime_Hash{$_} = &get_Almost_Average_Value($wait_time, $loop_count);
    }

    #Record it to the hisory directory.
    print $log_handler "\nFinal Result:\n";
    foreach (@${app_list}) {
        printf $log_handler "+> %-15s : %d ms \n", $_, $Package_WaitTime_Hash{$_};
        printf "+> %-15s : %d ms \n", $_, $Package_WaitTime_Hash{$_};
    }

    &release_Target_Logging_File_Handle($log_handler);
}


################################################################################
# 
################################################################################
my (%App_Value_Sorted_Hash);
sub by_sorted_value { $App_Value_Sorted_Hash{$b} <=> $App_Value_Sorted_Hash{$a}; }
sub generate_Diagram_Result {
    my ($app_list, $category_name, $bar_color) = @_;
    foreach (@${app_list}) {
        $App_Value_Sorted_Hash{$_} = $Package_WaitTime_Hash{$_}
    }
    my (@sorted_app_list) = sort by_sorted_value keys %App_Value_Sorted_Hash;
    my ($sorted_value_list) = [];
    
    foreach (@sorted_app_list) {
        push @${sorted_value_list}, $App_Value_Sorted_Hash{$_};
    }

    # print "generate_Diagram_Result: @sorted_app_list \n";
    # print "generate_Diagram_Result: @${sorted_value_list} \n";

    my( $title, $xLable, $yLabel, $fileName, $width, $height, $color) = (
        "${category_name} Launch Speed",
        "Application Name", "Time Consumption [ms]",
        "$PRODUCT/${BUILD_TIME}_${category_name}_launch_speed.png",
        -1, -1, $bar_color);
    generate2DBar(\@sorted_app_list, $sorted_value_list,
                   $title, $xLable, $yLabel, $fileName, $width, $height, $color); 
}


################################################################################
# 
################################################################################
sub get_Application_History_Array {
    my ($product, $application) = @_;
    my ($file_name_array) = [];
    opendir my $dir_handler, $product or die "Cannot open $product: $! \n";
    while (my $file_name = readdir $dir_handler) {
        if ($file_name =~ /(?<BUILD_TIME>[0-9]+)_data.txt/) {
          # print "-- $file_name ... $+{BUILD_TIME} \n";
          push @${file_name_array}, $+{BUILD_TIME};
        }
    }

    @${file_name_array} = sort by_number @${file_name_array};
    my ($history_array) = [];
    my ($size_of_file_name) = 0;
    $size_of_file_name = @${file_name_array};

    for (my $i = 0; $i < $size_of_file_name; $i++) {
        my $file_name = "$product/@$file_name_array[$i]_data.txt";
        my $app_value = &get_Application_Value_From_Database($application, 
                                                            $file_name);
        unless (defined($app_value)) {
            die "Cannot find this $application data in $file_name! No hisory data! \n";
        }

        # print " -- $file_name ... $app_value \n";
        push @${history_array}, $app_value;        
    }

    closedir $dir_handler;
    return ($file_name_array, $history_array);
}


################################################################################
# 
################################################################################
sub get_Application_Value_From_Database {
  my ($app_name, $db_file_name) = @_;
  my ($file_hanlder);
  open $file_hanlder, '<', $db_file_name;
  my ($value);

  # print "get_Application_Value_From_Database app_name: $app_name, db_file_name: $db_file_name \n";
  while (<$file_hanlder>) {
    chomp;
    if ($_ =~ /\+\> ${app_name}\s+: (?<WAIT_TIME>[0-9]+)/) {
      # print "get_Application_Value_From_Database : $_ \n";
      $value = $+{WAIT_TIME};
    }
  }
  return $value;
  close $file_hanlder;
}


################################################################################
# 
################################################################################
sub generate_History_Diagram_Result {
    my ($app_name) = @_;
    my ($app_history_array, $date_stream);
    my ($referece_history_array);

    ($date_stream, $app_history_array) = 
                &get_Application_History_Array($PRODUCT, $app_name);
    ($date_stream, $referece_history_array) = 
                &get_Application_History_Array($PRODUCT, $REFERENCE_APPLICATION_NAME);

    # print "____date_stream: @${date_stream} \n";
    # print "____$app_name: @${app_history_array} \n";
    # print "____$REFERENCE_APPLICATION_NAME: @${referece_history_array} \n";

    my ($save_path) = "${PRODUCT}/history";
    unless (-e $save_path) {
        system "mkdir -p ${save_path}"; #Trick for Unix-like system
    }

    my( $title, $xLable, $yLabel, $fileName, $width, $height, $color) = (
        "${app_name} history",
        "History Data", "Time Consumption [ms]",
        "${save_path}/${app_name}_history.png",
        -1, -1, "red");
    &generate2DLines($date_stream, $app_history_array, $referece_history_array,
                   $title, $xLable, $yLabel, $fileName, $width, $height, $color); 
}


################################################################################
# 
################################################################################
sub list_All_Be_Measured_Applications {
    my (@flyme_app_list) = &parse_Package_List($FLYME_APPLICATION);
    my (@third_app_list) = &parse_Package_List($THIRD_PART_APPLICATION);
    
    print "\t [Flyme build-in Application list] \n";
    foreach (@flyme_app_list) { printf "-+> %-10s : %s \n", ${_}, $Package_Acvitity_Hash{$_}; }
    
    print "\n";

    print "\t [Third part Application list] \n";
    foreach (@third_app_list) { printf "--> %-10s : %s \n", ${_}, $Package_Acvitity_Hash{$_}; }    
}


################################################################################
# 
################################################################################
sub acquire_Target_Logging_File_Handle {
    my ($product, $build_version) = @_;
    unless (-e $product) {
        mkdir $product, 0755 or warn "Cannot make ${product} directory $! \n";
    }
    open my ($data_handler), '>', "${product}/${build_version}_data.txt" or
        die "Can't open $product/$build_version. $!\n";
    return $data_handler;
}

sub release_Target_Logging_File_Handle {
    my($data_handler) = @_;
    close $data_handler;
}


################################################################################
# 
################################################################################
sub help_Document {
    print "\nUsage: \n";
    print "\t -f     ; Measure flyme built-in application.\n";
    print "\t -t     ; Measure third part application. \n";
    print "\t -l     ; List all the available apps. \n";
    print "\t -c num ; Do [num] times measure, default is 18.\n";
    print "\t -p prd ; Specify the measured product(Used for hisory diagram).\n";
    print "\t -b time; Specify the measured build version.\n";
    print "\t -i app ; Generate hisory diagram. app: application to be shown. \n";
    print "\n";
}


################################################################################
# Main Entry
################################################################################
unless (@ARGV) { &help_Document; }

#Prepare options parser
my %program_options = ();
getopts("hftlc:ep:b:i:", \%program_options);

#Options -h:
if ($program_options{h}) { &help_Document; die "Done!\n"; }

#Options -l:
if ($program_options{l}) { &list_All_Be_Measured_Applications; die "Done!\n"; }

#Options -c:
my ($loop_count) = 18;
if (defined($program_options{c})) { $loop_count = $program_options{c}; }

if ($program_options{f} || $program_options{t}) {

    #Options -p:
    unless ($program_options{p}) {
        die " Error: Please input product parameter! \n";
    } else {
        $PRODUCT = $program_options{p};
    }

    #Options -b:
    unless ($program_options{b}) {
        die " Error: Please input build time parameter! \n";
    } else {
        $BUILD_TIME = $program_options{b};
    }

    #Options -f:
    if ($program_options{f}) {
        my (@flyme_app_list) = &parse_Package_List($FLYME_APPLICATION);
        &do_Launch_App_Measure_Task(\@flyme_app_list, $loop_count);
        &generate_Diagram_Result(\@flyme_app_list, "FlymeApps", "yellow");
        if ($program_options{e}) { &generate_Text_Result(\@flyme_app_list); }
    }

    #Options -t:
    if ($program_options{t}) {
        my (@third_app_list) = &parse_Package_List($THIRD_PART_APPLICATION);
        &do_Launch_App_Measure_Task(\@third_app_list, $loop_count);
        &generate_Diagram_Result(\@third_app_list, "ThirdApps", "black");
        if ($program_options{e}) { &generate_Text_Result(\@third_app_list); }
    }
}

#Options -i:
if ($program_options{i}) { 

    #Options -p:
    unless ($program_options{p}) {
        die " Error: Please input product parameter! \n";
    } else {
        $PRODUCT = $program_options{p};
    }

    &generate_History_Diagram_Result($program_options{i});
}

#Options mesh up:
if (@ARGV) { &help_Document; }

