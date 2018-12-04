#!/usr/bin/perl
use strict;
use warnings;
# Declare vars
my @lines;
my @db_info;
my %creds;
# Get the local system date
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900;
my $date = $mon . "-" . $mday .  "-" . $year;
# Read each line from the configuration and push into a list
# If the line matches one of the data base variables, push it into a list
# For each database line, create a key pair and assign in associative array
# Print the mysqldump command with
print_cmd($ARGV[0]);
sub print_cmd {
        # This is the main function. Checks the filename to determine how to
        # parse the file
        if ($_[0] =~ /wp-config\.php/) {
                # if the script detects a Wordpress configuration
                get_wp();
        } elsif ($_[0] =~ /confitionguration\.php/) {
                # if the script detects a Joomla! configuration
                get_jom();
        } else {
                print $_[0] . " is not a valid WordPress or Joomla! configuration!\n"
        }
}
sub get_lines {
        # Read the lines in the file
        while (<>) {
                push (@lines,$_);
        }
}
sub get_wp {
        # Read each line
        get_lines();
        foreach (@lines) {
                # Look for the WP database keys
                if (/DB_HOST|DB_USER|DB_PASSWORD|DB_NAME/) {
                        push(@db_info,$_);
                }
        }
        foreach (@db_info) {
                #
                $_ =~ /'(.*?)'.*'(.*?)'/ and $creds{$1} = $2;
        }
        print_wp();
}
sub get_jom {
        get_lines();
        foreach (@lines) {
                if  (/\$host |\$user |\$db |\$password /) {
                        push(@db_info,$_);
                }
        }
        foreach (@db_info) {
                $_ =~ /\$(\w*)\s*=\s*'(.*)'/ and $creds{$1} = $2;
        }
        print_jom();
}
sub print_wp {
        # Print the mysqldump command with
         print "mysqldump -h " . $creds{DB_HOST} . " -u " . $creds{DB_USER} . " -p" . $creds{DB_PASSWORD} . "  " . $creds{DB_NAME} . " >  /tmp/" . $creds{DB_NAME} . "-" . $date . ".sql". "\n";
}
sub print_jom {
        # Print the mysqldump command with
         print "mysqldump -h " . $creds{host} . " -u " . $creds{user} . " -p" . $creds{password} . "  " . $creds{db} . " >  /tmp/" . $creds{db} . "-" . $date . ".sql". "\n";
}
