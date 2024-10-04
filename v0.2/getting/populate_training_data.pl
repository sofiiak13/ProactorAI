# Title: populate_training_data.pl
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-06
# Description: APIs -> training_puller -> raw folder -> training_merger -> formatted folder -> python
# Example: ./populate_training_data.pl
#
   
use lib '../getting';
use lib '../devices';
use lib '..';
use JSON;
use Getopt::Long;
use Data::Dumper qw(Dumper);

use training_puller;
use training_merger;
use Site;
use Router;
use Switch; 
use AP;
use Starlink;


# in format (YYYY, M, D, YYYY, M, D), inclusive of start and end
my @date_range = (2023, 1, 1, 2023, 12, 31);
my $databases_dir = "../v0.2/databases";

print Dumper(\@date_range);

print "Pulling raw data...\n";
my $puller = training_puller->new($databases_dir);
$puller->pull_dates(@date_range);
print "===Updated raw databases===\n";


print "Formatting raw data...\n";
my $merger = training_merger->new($databases_dir);
$merger->to_database(@date_range);
print "===Updated formatted database===\n";

1;