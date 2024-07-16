#
# Title: data_puller.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: object to get information from APIs
#

package data_puller;

use ALPHAAPI;
use neroAPI;
use rodeoAPI;
use sierraAPI;
use mikeAPI;
use JSON;
use internal;
use velocityAPI;

use Data::Dumper qw(Dumper);

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
    my $self = {
        directory => shift,
    };
    bless $self, $class;

    $self->pull_api_data();

    return $self;
}


sub pull_api_data {
    my $self = shift;
    my $num_process = 3;                        # Equal to the number of APIs we're pulling from
    my @pids;
    for (my $i = 0; $i < $num_process; $i++) {
        my $pid = fork();
        push @pids, $pid;
        if ($pid) {
            next;
        } else {
            if ($i == 0) {
                $self->pull_alpha_api_data();
            } elsif ($i == 1) {
                $self->pull_rodeo_data();
            } elsif ($i == 2) {
                $self->pull_sierra_data();
            }
            die;
        }
    }
    foreach my $id (@pids) {
        waitpid($id, 0);
    }
    return;
}

# Subroutine Name: pull_alpha_api_data()
# Example use: data_puller->pull_alpha_api_data()
# Description:
#     Pulls data from alpha_api API
# Parameters:
#     none
# Return:
#     $data   : csv file with data that was pulled from alpha_api API 
sub pull_alpha_api_data {
    my $self = shift;
    my $filename = "raw_alpha_api.json";
    my $path = $self->{directory} . "/" . $filename;
    my $alpha_api = ALPHAAPI->new();
    # query web active database
    my $data = $alpha_api->web_adb("/anonymized_api_call/"); #returns a csv
    my $internal = internal->new();
    my @array = $internal->csv2list($data);
    my %today_hash;

    foreach my $device (@array) {
        my @device = @$device;
        if ($device[0] =~ /anonymized_regex/){
            $today_hash{$device[0]}{"device_name"} = $device[0];
            $today_hash{$device[0]}{"other_attribute"} = $device[5];
            $today_hash{$device[0]}{"another_attribute"} = $device[8];
        }
    }

    $self->to_raw_database($path, \%today_hash);
    print "...Pulled from alpha_api.\n";
    return;
}


# Subroutine Name: pull_nero_data()
# Example use: data_puller->pull_nero_data()
# Description:
#     Pulls data from neroAPI
# Parameters:
#     none
# Return:
#     $data: json file with data that was pulled from alpha_api API 
sub pull_nero_data {
    my $self = shift;
    my $filename = "raw_nero.json";
    my $nero =  neroAPI->new();
    # only get data for routers 
    my $data = $nero->getData("routers"); 
    my $hashref = JSON::decode_json($data); 
    my %hash = %{$hashref};
    $self->to_raw_database($filename, \%hash);
    return;
}

# Subroutine Name: pull_rodeo_data()
# Example use: data_puller->pull_rodeo_data()
# Description:
#     Pulls data from rodeo
# Parameters:
#     none
# Return:
#     $data: json file with data that was pulled from rodeo 
sub pull_rodeo_data {
    my $self = shift;
    my $filename = "raw_rodeo.json";
    my $path = $self->{directory} . "/" . $filename;
    my @data = FetchORA("anonymized/api/call");
    my %hash;
    for my $site (@data) {
        my @site = @$site;
        if (!$site[2]) {next};
        $hash{$site[0]}{"anonymized_attribute1"} = $site[0];
        $hash{$site[0]}{"attribute2"} = $site[1];
        $hash{$site[0]}{"attribute3"} = $site[2];
    }

    $self->to_raw_database($path, \%hash);
    print "...Pulled from rodeo.\n";
    return;
}

# Subroutine Name: pull_sierra_data()
# Example use: data_puller->pull_sierra_data()
# Description:
#     Pulls data from sierraAPI
# Parameters:
#     none
# Return:
#     $data: json file with data that was pulled from sierraAPI 
sub pull_sierra_data {
    my $self = shift;
    my $filename = "raw_star.json";
    my $path = $self->{directory} . "/" . $filename;
    my $star = sierraAPI->new();
    my $data = $star->get_service_lines();
    my $hashref = JSON::decode_json($data); 
    my $arrayref = $hashref->{content}{results};
    my @array = @$arrayref;
    my %hash;
    foreach my $sierra (@array) {
        my $device_name = $sierra->{nickname};
        if ($device_name =~ /anonymized_regex/) {
            my $anonymized_attribute = $attribute;
            my $ping_state = $sierra->{attribute};
            $hash{$device_name}{attribute} = $attribute;
            $hash{$more}{attributes} = $omitted;
        }
    }
    $self->to_raw_database($path, \%hash);
    print "...Pulled from sierra.\n";
    return;
}

# Subroutine Name: pull_mike_data()
# Example use: data_puller->pull_mike_data()
# Description:
#     Pulls data about all sites and all devices from mikeAPI and combines it into one json
# Parameters:
#     none
# Return:
#     $merged_json: json file with data that was pulled from mikeAPI
sub pull_mike_data {
    my $self = shift;
    my $mike = mikeAPI->new();
   
    my $inventory = $mike->getData('orgs/' . $mike->{org_id} . '/inventory');
    my $sites = $mike->getData('orgs/' . $mike->{org_id} . '/sites');
    my @merged_data;
   
    my $inv_str = JSON::decode_json($inventory); 
    my $site_str = JSON::decode_json($sites); 
   
    for(my $i = 0; $i < scalar @$inv_str; $i++) {
        my $site_id = $inv_str->[$i]{site_id};

        for(my $j = 0; $j < scalar @$site_str; $j++) {
            my $id = $site_str->[$j]{id};
            if ($site_id){
                if ($id eq $site_id){
                    my %merged_device = (
                        id => $id,
                        anon => $anonymized->[$anon]{anon},
                        etc => $more->[$omitted]
                    );
                    push @merged_data, \%merged_device;
                }
            }
        }
    }
    $self->{mike_data} = \@merged_data;
    return;
}

# Subroutine Name: to_raw_database()
# Example use: data_puller->to_raw_database($path)
# Description:
#     output json database of raw data
# Parameters:
#     $path
# Return:
#     none
sub to_raw_database {
    my $self = shift;
    my $path = shift;
    my $raw_data = shift;
    my $raw_database_content = lc(JSON::encode_json($raw_data));
    open my $file, '>', $path or die "Cannot write raw database file: $!\n";
    print $file $raw_database_content;
    close $file;
    return;
}

1;