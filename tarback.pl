#!/usr/bin/perl
##### A perl script to backup directories and mysql databases on a unix fs #####
##### By kbruder@scratchspace.com #####

# Check args
if ( $#ARGV != 0 ) {
        print "This program takes one argument.\n";
        print "The argument must be a text file\n";
        print "containing the absolute paths of the\n";
        print "directories you wish to backup,\n";
        print "one per line.\n";
        exit;
}

# Ask the user to give the backup a name
print "Enter an alpha-numeric name for this backup > ";
chomp( $name= <STDIN> );

# Check for spaces
if ( $ans =~ /\w\s+/ ) {
        print "Name must be a single word without spaces\n";
        print "Exiting.\n";
        exit;
}

# Check for non-word characters
if ( $ans =~ /\W/ ) {
        print "Name cannot contain non-word characters\n";
        print "Exiting.\n";
        exit;
}

# Open the file specified in the argument
$dirfile = $ARGV[0];
$backdir = $name . '-backup';
open ( DIRS, $dirfile );

# Check each file for existence
# If it is readable, push it into @dirs
# If not, warn the user

while ( <DIRS> ) {
        chomp;
        if ( -r $_ ) {
                push( @dirs, $_ );
        } else {
                print "Excluding ${_}... path not readable.\n";
                print "Proceed?  (y,n) > ";
                chomp( $ans = <STDIN> );
                if ( $ans ne 'y' ) {
                        print "Bye.\n";
                        exit;
                }
        }
}

# Close the file
close DIRS;

if ( ! @dirs ) {
        print "No files were included in your file argument\n";
        print "Exiting.\n";
        exit;
}

# Notifiy the user of the results of the directory existence test
print "Including:\n";
foreach $i ( @dirs ) {
        print $i . "\n";
}
print "Proceed?  (y,n) > ";
chomp ( $ans = <STDIN> );
if ( $ans ne 'y' ) {
        print "Bye.\n";
        exit;
}

# Set a time variable to be used in the filename to prevent overwrites
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$timestamp = $year . '-' . $mon . '-' . $mday . '-' . $hour . '-' . $min . '-' . $sec;
# Create a folder in the user's home directory where the backups will go
# unless the folder already exists
if ( ! -e $ENV{"HOME"} . "/" . $backdir ) {
        print "Creating dir ${backdir} in your home folder...";
        system ( "mkdir ~/$backdir" );
        print "Success\n";
}

# tar the directories
print "Tarring....Please be patient";
system ( "tar zcfpP ~/$backdir/$backdir-$timestamp.tar.gz @dirs" );
print "....Success\n";

# Ask about mysql backups
print "Do you need to back up mysql?  (y,n) > ";
chomp ( $ans = <STDIN> );
if ( $ans ne 'y' ) {
        all_done();
}

# Ask the user for database names one by one
while ( $ans eq 'y' ) {
        print "Enter the exact name of the database > ";
        chomp ( $datab = <STDIN> );
        push ( @mysql, $datab );
        print "Would you like to add another database?  (y,n) > ";
        chomp ( $ans = <STDIN> );
}

# Dump the databases
print "Tarring....Please be patient";
foreach $i ( @mysql ) {
        system ( "mysqldump $i > ~/$backdir/$i-backup-$timestamp.sql" );
        system ( "tar zcfpP ~/$backdir/$i-backup-$timestamp.tar.gz ~/$backdir/$i-backup-$timestamp.sql" );
        system ( "rm -f ~/$backdir/$i-backup-$timestamp.sql" );
}
print "....Success\n";

# Exit the program
all_done();

# Exit function
sub all_done {
        print "Done.\n";
        system ("du -h ~/$backdir/*");
        exit;
}
