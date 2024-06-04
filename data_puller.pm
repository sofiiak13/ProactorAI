#
# Title: data_puller.pl
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: object to get information from APIs
#

package data_puller;

use alphaAPI;       #anonymized imports
use betaAPI;
use gammaAPI;
use deltaAPI;
use epsilonAPI;
use JSON;
use zeta;

# Subroutine Name: new()
# Example use: data_puller->new()
# Description:
#     Creates an data_puller object to allow for pulling information from APIs
# Parameters:
#     none
# Return:
#     $self: new data_puller object
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->{alpha_data} = $self->pull_alpha_data(); 
    $self->{beta_data} = $self->pull_beta_data();   
    $self->{delta_data} = $self->pull_delta_data();   
    $self->{epsilon_data} = $self->pull_epsilon_data();   
    $self->{gamma_data} = $self->pull_gamma_data();
    return $self;
}

# Subroutine Name: pull_alpha_data()
# Example use: data_puller->pull_alpha_data()
# Description:
#     Pulls data from alpha API
# Parameters:
#     none
# Return:
#     $data   : csv file with data that was pulled from alpha API 
sub pull_alpha_data {
    my $self = shift;
    my $alpha = alphaAPI->new();
    # query web active database
    my $data = $alpha->web_adb("anonymized api call command"); #returns a csv
    my $zeta = zeta->new();
    my @list = $zeta->csv2list($data);
    my %hash;

    foreach my $device (@list) {
        my @device = @$device;
        if ($device[0] =~ /^anonymized regex$/){
            $hash{$device[0]}{"attribute"} = $device[index];
            $hash{$device[0]}{"attribute"} = $device[index];
            $hash{$device[0]}{"attribute"} = $device[index];
        }
    }
    return \%hash;
}

# Subroutine Name: pull_beta_data()
# Example use: data_puller->pull_beta_data()
# Description:
#     Pulls data from betaAPI
# Parameters:
#     none
# Return:
#     $data: json file with data that was pulled from alpha API 
sub pull_beta_data {
    my $self = shift;
    my $beta = betaAPI->new();
    # only get data for routers 
    my $data = $beta->getData("routers"); 
    my $hashref = JSON::decode_json($data); 
    my %hash = %{$hashref};
    return \%hash;
}

# Subroutine Name: pull_gamma_data()
# Example use: data_puller->pull_gamma_data()
# Description:
#     Pulls data from gamma
# Parameters:
#     none
# Return:
#     $data: json file with data that was pulled from gamma 
sub pull_gamma_data {
    my $self = shift;
    my @data = AnonFetch("anonymized api call command");
    my %hash;
    for my $site (@data) {
        my @site = @$site;
        if (!$site[2]) {next};
        $hash{$site[0]}{"attribute"} = $site[index];
        $hash{$site[0]}{"attribute"} = $site[index];
        $hash{$site[0]}{"attribute"} = $site[index];
    }
    return \%hash;
}

# Subroutine Name: pull_delta_data()
# Example use: data_puller->pull_delta_data()
# Description:
#     Pulls data from deltaAPI
# Parameters:
#     none
# Return:
#     $data: json file with data that was pulled from deltaAPI 
sub pull_delta_data {
    my $self = shift;
    my $delta = deltaAPI->new();
    my $data = $delta->anon_api_call();
    my $hashref = JSON::decode_json($data); 
    my %hash = %{$hashref};
    return \%hash;
}

# Subroutine Name: pull_epsilon_data()
# Example use: data_puller->pull_epsilon_data()
# Description:
#     Pulls data about all sites and all devices from epsilonAPI and combines it into one json
# Parameters:
#     none
# Return:
#     $merged_json: json file with data that was pulled from epsilonAPI
sub pull_epsilon_data {
    my $self = shift;
    my $epsilon = epsilonAPI->new();
   
    my $inventory = $epsilon->getData("anonymized api call");
    my $sites = $epsilon->getData("anonymized api call");
    my @merged_data;
   
    my $inv_str = JSON::decode_json($inventory); 
    my $site_str = JSON::decode_json($sites); 
   
    for(my $i = 0; $i < scalar @$inv_str; $i++) {
        my $site_id = $inv_str->[$i]{site_id};

        for(my $j = 0; $j < scalar @$site_str; $j++) {
            my $id = $site_str->[$j]{attribute};
            if ($site_id){
                if ($id eq $site_id){
                    my %merged_device = (
                        attribute => $inv_str->[index]{attribute},
                        # 12 additional attributes anonymized
                    );
                    push @merged_data, \%merged_device;
                }
            }
        }
    }
    return \@merged_data;
}

# Subroutine Name: to_raw_database()
# Example use: 
# Description:
#     output json database of raw data
# Parameters:
#     $filename
# Return:
#     none
sub to_raw_database {
    my $self = shift;
    my $filename = shift;
    my %raw_data;
    
    $raw_data{alpha} = $self->{alpha_data};
    $raw_data{epsilon} = $self->{epsilon_data};
    $raw_data{delta} = $self->{delta_data};
    $raw_data{beta} = $self->{beta_data};
    $raw_data{gamma} = $self->{gamma_data};

    my $raw_database_content = lc(JSON::encode_json(\%raw_data));
    open my $file, '>', $filename or die "Cannot write raw database file: $!\n";
    print $file $raw_database_content;
    close $file;
}

1;