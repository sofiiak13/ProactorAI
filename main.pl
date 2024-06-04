#
# Title: main.pl
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: APIs -> data_puller -> raw_database.json -> data_merger -> database.json -> data_analyzer -> data_reporter -> output.txt
# Example: ./main.pl --mode=1
#

use lib 'anonymized library location';
use JSON;
use Getopt::Long;
use Data::Dumper qw(Dumper);

use data_puller;
use data_merger;
use data_analyzer;
use data_reporter;
use Site;
use Router;

my $mode = 1;
my $merger;

GetOptions(
  'mode=i'   => \$mode,
) or die "Invalid options for $0\n";

if ($mode == 0 || $mode == 1) {
    update_database();
    print "Updated database file.\n"
}
if ($mode == 1) {
    analyze_database_directly();
    print "Analyzed database directly.\n"
}
if ($mode == 2) {
    analyze_database_file();
    print "Analyzed database from file.\n"
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
    my $puller = data_puller->new();
    $puller->to_raw_database("raw_database.json");
    $merger = data_merger->new("raw_database.json");
    $merger->to_database("database.json");
}

# Subroutine Name: analyze_database_file()
# Example use:
# Description:
#     Loads from database file, analyzes, and reports
# Parameters:
#     none
# Return:
#     none
sub analyze_database_file {
    my $analyzer = data_analyzer->new("database.json");
    my $reporter = data_reporter->new($analyzer);
    $reporter->to_file("output.txt");
}

# Subroutine Name: analyze_database_directly()
# Example use:
# Description:
#     Loads directly from merger, analyzes, and reports
# Parameters:
#     none
# Return:
#     none
sub analyze_database_directly {
    my $analyzer = data_analyzer->new($merger);
    my $reporter = data_reporter->new($analyzer);
    $reporter->to_file("output.txt");
}

1;