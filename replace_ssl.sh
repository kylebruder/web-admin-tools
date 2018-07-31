#!/bin/bash
# A bash script to replace old SSL files with new ones and push out a new configuration file
# By kbruder@cloudbrigade.com
 
# Declare variables here. You can skip a lot of the interaction by manually entering paths and
# filenames here. Don't use trailing slashes
 
# service to use
service_restart="service httpd restart" # name of service to reload
service_test="apachectl -t" # command to test syntax
 
# new file names
new_config="test.conf" # staged configuration file
new_key_name="test.key" # staged key file
new_cert_name="site.crt" # staged site certificate
new_intermediate="inter.crt" # staged intermediate certificate
 
# old file names
old_config="old_test.conf" # original configuration file
old_key_name="old_test.key" # original key file
old_cert_name="old_site.crt" # original site certificate
old_intermediate="old_inter.crt" # original intermediate certificate
 
# directories
stage_dir="/tmp/testing/stage" # staging directory for new files
cert_dir="/tmp/testing/orig/cert" # certificate directory defined in configuration file
key_dir="/tmp/testing/orig/private" # private key directory defined in configuration file
config_dir="/tmp/testing/conf" # configuration directory
backup_dir="/tmp/backups" # backup directory
 
function make_test_env()
{
        env_dir="/tmp/testing"
        echo "Creating test environment in $env_dir ..."
        mkdir -p "$env_dir"/conf
        mkdir -p "$env_dir"/stage
        mkdir -p "$env_dir"/orig/cert
        mkdir -p "$env_dir"/orig/private
 
        touch "$env_dir"/conf/old_test.conf
        touch "$env_dir"/orig/cert/old_inter.crt
        touch "$env_dir"/orig/cert/old_site.crt
        touch "$env_dir"/orig/private/old_test.key
        touch "$env_dir"/stage/inter.crt
        touch "$env_dir"/stage/site.crt
        touch "$env_dir"/stage/test.conf
        touch "$env_dir"/stage/test.crt
        touch "$env_dir"/stage/test.key
        tree $env_dir
}
 
# Check to see if user supplied any arguments
if [ $1 == "-t" ]; then
        echo "Creating a test environment in /tmp..."
        make_test_env
        echo "Done"
fi
 
# Function definitions
function confirm_vars()
{
        # Confirm static values or enter new ones
        echo "The script is using the following variables"
        echo "SSL Service Restart Command: $service_restart"
        echo "Configuraiton Test Command: $service_test"
        echo "Staged Configuration File: $stage_dir/$new_config"
        echo "Staged Key File : $stage_dir/$new_key_name"
        echo "Staged Site Certificate: $stage_dir/$new_cert_name"
        echo "Staged Intermediate Certificate: $stage_dir/$new_intermediate"
        echo "Original Configuration File: $config_dir/$old_config"
        echo "Original Key File: $key_dir/$old_key_name"
        echo "Original Site Certificate: $cert_dir/$old_cert_name"
        echo "Original Intermediate Certificate: $cert_dir/$old_intermediate"
        echo "Change variables?  (y,n) "
        read answer
        if [ "$answer" == "n" ]; then
                echo "Starting Script"
        else
                read_vars
        fi
}
 
function confirm_files()
{
        # Create an array containing the absolute paths of the files
        file_array=(
                "$stage_dir/$new_config"
                "$stage_dir/$new_key_name"
                "$stage_dir/$new_cert_name"
                "$stage_dir/$new_intermediate"
                "$config_dir/$old_config"
                "$key_dir/$old_key_name"
                "$cert_dir/$old_cert_name"
                "$cert_dir/$old_intermediate"
        )
        #echo $file_array # Debug line
        # Check if each file exits
        for f in ${file_array[*]};
        do
                if [ -f $f ]; then
                        echo "'$f' OK"
                else
                        echo "'$f' not found...please check"
                        exit 1
                fi
        done
}
 
function read_vars()
{
        # Read new variables from user input
        echo "SSL Service Restart Command: "
        read service_restart
        echo "Configuration Test Command: "
        read service_test
        echo "Staging Directory: (no trailing slash)"
        read stage_dir
        echo "Certificate Directory: (no trailing slash)"
        read cert_dir
        echo "Private Key Directory: (no trailing slash)"
        read key_dir
        echo "Configuration File Directory: (no trailing slash)"
        read config_dir
        echo "Backup Directory: (no trailing slash)"
        read backup_dir
        echo "Original Key Filename: "
        read old_key_name
        echo "Original Site Certificate Filename: "
        read old_cert_name
        echo "Original Intermediate Filename: "
        read old_intermediate
        echo "Original Configuration Filename: "
        read old_config
        echo "Staged Key Filename: "
        read new_key_name
        echo "Staged Site Certificate: "
        read new_cert_name
        echo "Staged Intermediate Certificate Filename: "
        read new_intermediate
        echo "Staged Configuration File: "
        read new_config
        confirm_vars
}
 
function backup_check()
{
        # check for backup
        if [ -d $backup_dir ]; then
                echo "found '$backup_dir'"
        else
                echo "Creating backup directory '$backup_dir' ..."
                mkdir -p "$backup_dir"
        fi
}
 
function make_backups()
{
        # make backups
        echo "Making backups ..."
        cp "$key_dir"/"$old_key_name" "$backup_dir"
        cp "$cert_dir"/"$old_cert_name" "$backup_dir"
        cp "$cert_dir"/"$old_intermediate" "$backup_dir"
        cp "$config_dir"/"$old_config" "$backup_dir"
}
 
function deploy_files()
{
        # deploy the files
        echo "Deloying staged files..."
        cp "$stage_dir"/"$new_cert_name" "$cert_dir"
        cp "$stage_dir"/"$new_intermediate" "$cert_dir"
        cp "$stage_dir"/"$new_key_name" "$key_dir"
        cp "$stage_dir"/"$new_config" "$config_dir"
        # Check to see if the user would like to remove the original configuration file
        if [ "$old_config" != "$new_config" ]; then
                echo "Remove original config file: $config_dir/$old_config? (y,n)"
                read answer
                if [ "$answer" == "y" ]; then
                        rm "$config_dir"/"$old_config"
                fi
        fi
}
 
function restart_service()
{
        # restart nginx
        echo "Testing configuration syntax..."
        $service_test
        echo "Restart Service? (y,n) "
        read answer
        if [ "$answer" == "y" ]; then
                $service_restart
        else
                exit 0
        fi
}
 
function test_prompt()
{
        # Prompt the user to test a SSL/TLS tranaction
        echo "The script is complete....Please test now."
        sleep 3
        # Ask the user if they want to restore the files from backup
        echo "type 'undo' to restore the original files from backup or hit enter to close"
        read answer
        if [ "$answer" == "undo" ]; then
                replace_files
 
        else
                tree_dirs
                exit 0
        fi
}
 
function replace_files()
{
        echo "Removing new files..."
        rm "$cert_dir"/"$new_cert_name"
        rm "$cert_dir"/"$new_intermediate"
        rm "$key_dir"/"$new_key_name"
        rm "$config_dir"/"$new_config"
        echo "Relpacing original files"
        cp "$backup_dir"/"$old_key_name" "$key_dir" # replace original key file
        cp "$backup_dir"/"$old_cert_name" "$cert_dir" # replace original site certificate
        cp "$backup_dir"/"$old_intermediate" "$cert_dir" # replace original intermediate certificate
        cp "$backup_dir"/"$old_config" "$config_dir" # replace original configuration file
        echo "Done...Testing syntax"
}
 
function tree_dirs()
{
        tree $stage_dir $cert_dir $key_dir $backup_dir $config_dir
}
 
 
function main_func()
{
        confirm_vars
        confirm_files
        backup_check
        make_backups
        deploy_files
        restart_service
        test_prompt
        tree_dirs
}
main_func