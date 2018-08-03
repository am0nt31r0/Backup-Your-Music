#!/usr/bin/perl -w
use strict;
use Date::Calc qw/Delta_Days/;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);;

# Todays Time
my $date = strftime "%d-%m-%Y", localtime;
my $day = strftime "%d", localtime;
my $month = strftime "%m", localtime;
my $year = strftime "%Y", localtime;

# Files and Directories
chomp(my $user = `whoami`);
my $directoryToBackup = "/home/$user/Music";
my $drive = "/media/$user/DRIVE_THAT_CONTAINS_THE_BACKUP";
my $logFile = "$drive/backup.log";

# New backup filename
my $newBackupFileName = "$drive/backup_Music_" . $date . ".tar";

# Find command that searches for last backup file
#chomp(my $backupFilename = `find $drive -iname backup_Music_\*-\*-\*.tar`);
#my $backupFilename = "^backup__Music_(\d+)-(\d+)-(\d+).tar";

if(@ARGV != 1)
{
        print STDERR ("Wrong number of arguments!\n");
        print "Please enter the backup filename [backup_Music_DD_MM_YYYY.tar]...\n";
        exit(1); # quando o programa termina sem sucesso, a função exit seguida do respetivo código de erro pode informar o utilizar acerca do erro
}

my $backupFilename = "$drive" . "/" . "$ARGV[0]";

sub exitMessage {

    print "[+] ", GREEN, "Backup is done!\n", RESET; # verde
    print "You can check the logs in ", BRIGHT_BLUE, "[$logFile]\n", RESET; # azul
}

if ( -e $backupFilename ) {
    
    # Date of Last Backup
    my $fileDay = substr("$backupFilename", 41, 2); 
    my $fileMonth = substr("$backupFilename", 44, 2); 
    my $fileYear = substr("$backupFilename", 47, 4);
    
    # Calculates how much day have passed since last backup
    my @oldBackupDate = ($fileYear, $fileMonth, $fileDay);
    my @todaysDate = ($year, $month, $day);
    my $numberOfDays = Delta_Days(@oldBackupDate, @todaysDate);

    print "[+] ", RED, "$numberOfDays", RESET, " days have passed...\n";
    
    # Number of files found to backup
    chomp(my $nOfFiles = `find $directoryToBackup -type f -mtime -$numberOfDays -print | wc -l`);

    print "[+] Old backup: ", BRIGHT_BLUE, "[$backupFilename]", RESET, RED, "[@oldBackupDate]\n", RESET;
    
    if ($nOfFiles > 0) {
    
        print "And there's $nOfFiles file(es) to backup!\n";
        print "The incremental backup will start now!\n";
        
        # The actual Backup and logging
        `echo "\n\n[$date]\n" >> $logFile`;
        # -print0, -0 and --null are used because of the names of the musics (have spaces...)
        `find $directoryToBackup -type f -mtime -$numberOfDays -print0 | xargs -0 tar --null --absolute-names -rvf $backupFilename 2>> $logFile`; # --absolute-names or -Prvf
        # Renames the old backup filename to the new one
        `mv $backupFilename $newBackupFileName`;

        exitMessage();
        
    } else {
            
        print "And there's no files to backup...\n";
            
    }

} else {
    
    print "[+] Backup file dont exist...\n";
    print "[+] Creating a complete backup of music ", BRIGHT_BLUE, "[$directoryToBackup] ", RESET, "to ", BRIGHT_BLUE, "[$newBackupFileName]\n", RESET;
    
    # Complete backup
    `tar -Pcvf $newBackupFileName $directoryToBackup 2> $logFile`;

    exitMessage();

}

print "Script terminated...\n";

exit(0);
