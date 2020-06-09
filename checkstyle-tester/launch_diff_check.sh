#!/bin/bash
# Usage: Automate check behavior regression report
# Must be run in contribution/checkstyle-tester directory!
# Use absolute paths in setup variables

################ SETUP ##################
checkstyle_tester_dir=$(pwd)
#Set your checkstyle directory
checkstyle_dir=${HOME}/checkstyle
#Set output directory
output_dir=${HOME}/reports
#Set directory with configs
config_dir=${HOME}/xml_check_configs
##########################################

#Set time variable for tracking report and log generation
time=$(date '+%Y_%m_%d');

#Exit if no patch branch is specified
if [ -z "$1" ]; then
    echo "Need to specify valid patch branch as command line arguement."
    echo "Example:  ./launch_diff_check.sh your-patch-branch"
    exit 1
elif [ ! $(cd "$checkstyle_dir" && git branch --list "$branch_name") ]; then
    echo "git branch $PATCH_BRANCH does not exist"
    echo "Enter a valid patch branch."
    exit 1
fi

PATCH_BRANCH=$1
echo "Running check regression reports on patch branch: $1"
echo "Make sure that you have selected all projects from projects-to-test-on.properties!"
sleep 5

#Setup directories for logs and reports
log_directory=$output_dir/"$PATCH_BRANCH"_check_diff_logs_$time
report_directory=$output_dir/"$PATCH_BRANCH"_check_diff_reports_$time
mkdir -p "$log_directory"
mkdir -p "$report_directory"

#Begin running reports, "shopt" usage to eliminate undefinied for loop behavior
shopt -s nullglob
echo "Log files will populate in $log_directory"
echo "Reports will populate in $report_directory"

#Iterate through every config file in specified directory and generate report
for file in "$config_dir"/*.xml;
do
    filename=$(basename -- "$file")
    filename="${filename%.*}"
    echo "Running check regression report using config file $file..."
    groovy diff.groovy \
    -r "$checkstyle_dir" \
    -b master -p "$PATCH_BRANCH" \
    -c "$file" \
    -l projects-to-test-on.properties \
    > "$log_directory"/logfile_"$filename" 2>&1
    sleep 5

    echo "Moving reports to report directory..."
    if ! mv ./reports/diff "$report_directory"/diff_"$filename" ; then
        echo "Script failed!"
        echo "logfile_$filename generated in $log_directory."
        exit 1
    fi

    echo "Check regression report for config file $file completed."
    echo "logfile_$filename generated in $log_directory."
    echo "report diff_$filename generated in $report_directory."

    sleep 5

done

exit 0
