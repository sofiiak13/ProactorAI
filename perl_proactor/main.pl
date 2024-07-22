#
# Title: main.pl
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: APIs -> data_puller -> raw_database.json -> data_merger -> database.json -> data_analyzer -> data_reporter -> output.txt
# Example: ./main.pl --mode=1 --type=pru --to="email.address@email.domain.ca"
#

use lib 'lib/path/1';
use lib 'lib/path/2';
use JSON;
use Getopt::Long;
use Data::Dumper qw(Dumper);

use data_puller;
use data_merger;
use data_analyzer;
use data_reporter;
use Site;
use Router;
use Switch;
use AP;
use Starlink;

my $puller;
my $merger;
my $analyzer;
my $reporter;

my $mode = 1;            # 0 to update database, 1 to do everything (default), 2 to analyze data
my $type = "pru";        # analysis type, default is pru (Percentage Routers Up)
my $to;                  # string of email recipients divided by commas, default is empty

GetOptions(
  'mode=i'   => \$mode,
  'type=s'   => \$type,
  'to=s'     => \$to,
) or die "Invalid options for $0\n";


if ($mode == 0 || $mode == 1) {
    update_database();
}
if ($mode == 1 || $mode == 2) {
    analyze_database();
}
if ($mode == 3) {
    training_data();
}


# Subroutine Name: update_database()
# Example use:
# Description:
#     Pulls data from APIs, merges, and overwrites database file
# Parameters:
#     none
# Return:
#     none
sub update_database {
    print "Pulling from APIs...\n";
    $puller = data_puller->new("databases");
    $merger = data_merger->new("databases");
    print "Merging raw data...\n";
    $merger->read_raw_data();
    $merger->merge_data();
    print "Writing merged data to database...\n";
    $merger->to_database("databases/database.json");
    print "===Database file updated===\n";
}

# Subroutine Name: analyze_database()
# Example use:
# Description:
#     Loads from database, analyzes, and reports
# Parameters:
#     none
# Return:
#     none
sub analyze_database {
    if ($mode == 1) {
        print "Analyzing database from memory...\n";
        $analyzer = data_analyzer->new($merger);
    } elsif ($mode == 2) {
        print "Analyzing database from file...\n";
        $analyzer = data_analyzer->new("databases/database.json");
    }

    if ($type eq "pru") {
        print "Generating PRU report...\n";
        $analyzer->percentage_routers_up();
        $reporter = data_reporter->new($analyzer);
    }

    print "Writing report to file...\n";
    $reporter->to_file("output.txt");
    print "===Report written to file===\n";
    
    if ($to) {
        print "Writing report to email...\n";
        $reporter->to_email($to);
        print "===Report emailed===\n";
    }
}

# Subroutine Name: training_data()
# Example use:
# Description:
#     
# Parameters:
#    
# Return:
#   
sub training_data {
    $merger = data_merger->new("alpha_api_data");
    print "Merging training data...\n";
    $merger->read_alpha_api_training();
    $merger->merge_alpha_api();
    print "Writing training data to database...\n";
    $merger->to_database("databases/database.json");
    print "===Database file updated===\n";
}

1;