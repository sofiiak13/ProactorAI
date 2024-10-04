# Title: data_puller.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-06
# Description: object to get training data from APIs
#

package training_puller;

use ALPHAAPI;
use datetime;

# Subroutine Name: new()
# Example use: training_puller->new()
# Description:
#     Creates an training_puller object to allow for pulling information from APIs
# Parameters:
#     $directory
# Return:
#     $self: new training_puller object
sub new {
    my $class = shift;
    my $self = {
        directory => shift . "/raw/"
    };
    bless $self, $class;
    return $self;
}  

sub pull_dates {
    my $self = shift;
    my @date_range = @_;
    my $alpha = ALPHAAPI->new(); 
    my $directory = $self->{directory};
    my $filename = "raw_alpha_data_";
    my $filetype = ".csv"; 
    
    my $datetime = datetime->new();
    my @dates = $datetime->dates_between(@date_range); 
    
    for (my $i = 0; $i < (scalar @dates); $i++) { 
        
        my $date = $dates[$i];

        print("...Pulling " . $date . "...\n");

        open ($fh, '>', $directory.$filename.$date.$filetype) or die "Cannot write raw training data file: $!\n";
        print $fh ($alpha->web_adb('function'));
        print $fh "MAXIMUMS\n";
        print $fh ($alpha->web_adb('function'));
        close $fh;
        sleep(1);
    }

    my $firstdate = $dates[0];
    my $lastdate = $dates[-1];

    my $logs_filename = "raw_alpha_logs_";
    $logs_filename = $logs_filename . $firstdate . "_" . $lastdate;

    print("...Pulling logs...\n");

    open ($file, '>', $directory.$logs_filename.$filetype) or die "Cannot write raw_alpha_logs file: $!\n";
    print $file ($alpha->web_adb('function'));
    close $file;
}

1;