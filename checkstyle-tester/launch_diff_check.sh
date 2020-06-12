#!/bin/bash
# Usage: Automate check behavior regression report by running diff.groovy on
#   all config files in a given directory
# Must be run in contribution/checkstyle-tester directory!
# Use absolute paths in setup variables

################ SETUP ##################
#Set your checkstyle directory
checkstyle_dir=${HOME}/IdeaProjects/checkstyle
#Set output directory
output_dir=${HOME}/reports
#Set directory with configs
config_dir=${HOME}/xml_check_configs
##########################################

#Set time variable for tracking report and log generation
time=$(date '+%m_%d');

PATCH_BRANCH=$1
#Exit if no patch branch is specified
if [ -z "$PATCH_BRANCH" ]; then
    echo "Need to specify valid patch branch as command line argument."
    echo "Example:  ./launch_diff_check.sh your-patch-branch"
    exit 1
elif [ ! "$(cd "$checkstyle_dir" && git branch --list "$PATCH_BRANCH")" ]; then
    echo "git branch \"$PATCH_BRANCH\" does not exist or incorrect checkstyle directory specified."
    echo "Enter a valid patch branch and verify checkstyle directory is correct."
    exit 1
fi

echo "Running check regression reports for patch branch: $1"
echo "Make sure that you have selected all projects from projects-to-test-on.properties!"
sleep 5

#Setup directories for logs and reports
log_directory=$output_dir/"$PATCH_BRANCH"_check_diff_logs_$time
report_directory=$output_dir/"$PATCH_BRANCH"_check_diff_reports_$time
mkdir -p "$log_directory"
mkdir -p "$report_directory"

#Begin running reports, "shopt" usage to eliminate undefinied for loop behavior
shopt -s nullglob

#Iterate through every config file in specified directory and generate report for each
#If report generation for one config fails, script will try the next one.
for file in "$config_dir"/*.xml;
do
    filename=$(basename -- "$file")
    filename="${filename%.*}"
    echo "Generating check regression diff report using config $file..."
    groovy diff.groovy \
    -r "$checkstyle_dir" \
    -b master -p "$PATCH_BRANCH" \
    -c "$file" \
    -l projects-to-test-on.properties \
    > "$log_directory"/logfile_"$filename" 2>&1
    sleep 5

    if mv ./reports/diff "$report_directory"/diff_"$filename" ; then
        echo "Check regression diff report for config file $file completed."
    else
        tail "$log_directory"/logfile_"$filename"
        echo ""#add config file check; grep for saxon or whatever
        echo "Report generation for config $filename.xml failed!"
        echo "See logfile_$filename generated in $log_directory for details."
    fi

    sleep 5

done

exit 0
