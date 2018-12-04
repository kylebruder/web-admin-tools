#!/bin/bash
# A shell wrapper to use cmsdump.pl to do a final dump of an Apterburner customer's site or sites.
# By kbruder@cloudbrigade.com
# Last modified 12/03/2018

# Declare variables
customer=$1
site=$2
date=`date +%Y-%m-%d`
arg_count=$#
# Specify your path convention here
userhome="/users/$customer/home/$customer"
sitesdir="$userhome/sites"
tarfile_site="$userhome/$customer-$site-$date-final.tar.gz"
tarfile_all="$userhome/$customer-$date-final.tar.gz"
# Randomize the config list names to avoid clobbering existing files
file1=`echo $RANDOM | sha1sum | cut -d ' ' -f 1`".txt"
file2=`echo $RANDOM | sha1sum | cut -d ' ' -f 1`".txt"
#export sitesdir
main() {
	check_args
	# Generate config lists for cmsdump and tar the site(s)
	if [ "$2" = "" ]; then
		backup_all
	else
		backup_site
	fi
	show_complete
	echo "Would you like to copy the backup files to S3? (y,n):  "
	read ans
	if [ $ans == "y" ]; then
		s3_cp
	else
		echo "Skipping S3, run the following command to copy the backup to S3:"
		print_s3
		exit 0
	fi
}
check_args() {
# Check the arguments passed from the CLI
	if (( $arg_count < 1 )); then
		echo "You must supply at least one argument."
		echo "Example:"
		echo "/path/to/apterbacker.sh user www.example.com"
		exit 3
	fi
	if [ ! -d /users/$customer ]; then
        	echo "Customer $customer not found!"
        	exit 1
	fi
}

backup_all() {
	# If there was no specified site, then backup all sites
	ls $sitesdir/*/configuration.php 2> /dev/null; ls $sitesdir/*/wp-config.php 2> /dev/null > $file1
	dump_db
	/bin/tar cvfpz $tarfile_all "$sitesdir"
}
backup_site() {
	# If a site argument was passed then backup the site
	# Check if the site exists in the customer's jail
	ls "$sitesdir"/"$site" > /dev/null 2> /dev/null
	exists=$?
	if (( $exists == 0 )) ; then
                ls "$sitesdir"/"$site"/configuration.php 2> /dev/null; ls "$sitesdir"/"$site"/wp-config.php 2> /dev/null > $file1
		dump_db
		/bin/tar cvfpz "$tarfile_site" "$sitesdir"/"$site"
        else
		# If the site does not exist suggest one from ls
                echo "The site, $site was not found for customer $customer"
		echo "Perhaps you meant one of these:"
		ls $sitesdir
                exit 2
        fi
}

dump_db() {
# Run cmsdump.pl and remove the temporary files
	echo "#!/bin/bash" > $file2
	while read f; do
        	./cmsdump.pl $f >> $file2
	done < $file1
	chmod o+x $file2
	./$file2
	/bin/rm $file1
	/bin/rm $file2
	/bin/mv /tmp/*"$customer"*.sql $sitedir/
}
show_complete() {
	# Show a list of backup files
	echo "Backup complete (The database dump is in the tar archive,) here is your file:"
	ls -lah "$userhome"/*"$customer"*.tar.gz
}
s3_cp() {
	# Look for a full bacup
	if [ -f "$tarfile_all" ]; then
		aws s3 cp "$tarfile_all" s3://scratchspacebackups/archive/
	# Look for a single site backup
	elif [ -f "$tarfile_site" ]; then
		aws s3 cp "$tarfile_site" s3://scratchspacebackups/archive/ 
	else
		echo "No tar file was found in $userhome"
		exit 5
	fi
	if (( $? == 0 )); then
			echo "Success!"
			aws s3 ls s3://scratchspacebackups/archive/
		else
			echo "There was an error copying the files to S3."
			exit 4
		fi
}
print_s3() {
        if [ -f $tarfile_all ]; then
               echo "aws s3 cp $tarfile_all s3://scratchspacebackups/archive/"
        elif [ -f $tarfile_site ]; then
                echo "aws s3 cp $userhome/ s3://scratchspacebackups/archive/"
        else
                echo "There was an error! Please check your arguments and run the command again."
                exit 6
        fi
}
reminder() {
	echo "NOTICE - A final backup was taken for customer on:' `date` by `who`.  REMINDER - Be sure to remove any related Route 53 resources and remove the user and\/or site(s) from the Puppet configuration and do a final puppet run. See https://scratchspace.atlassian.net/wiki/spaces/ssadmin/pages/92766209/Decomission+shared+FS+site+user for details." | mail -s "NOTICE `who | cut -d'(' -f2 | cut -d')' -f1`" operations@scratchspace.com
}
main
