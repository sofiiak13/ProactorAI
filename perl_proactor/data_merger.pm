#
# Title: data_merger.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: object to collect and organize API data from data_getter
#

package data_merger;

use Data::Dumper qw(Dumper);

# Subroutine Name: new()
# Example use: data_merger->new()
# Description:
#     create a data_merger object to collect and organize API data from data_getter
# Parameters:
#     $filename
# Return:
#     $data_merger
sub new {
    my $class = shift;
    my $self = {
        directory => shift,

        alpha_api => {},
        starlink => {},
        nero => {},
        
        sites_hash => {},
        routers_hash => {},
        aps_hash => {},
        switches_hash => {},
        starlinks_hash => {}
    };
    bless $self, $class;

    return $self;
}

sub get_sites {
    my $self = shift;
    return $self->{sites_hash};
}

sub get_routers {
    my $self = shift;
    return $self->{routers_hash};
}

sub get_switches {
    my $self = shift;
    return $self->{switches_hash};
}

sub get_aps {
    my $self = shift;
    return $self->{aps_hash};
}

# Subroutine Name: read_raw_data()
# Example use: data_merger->read_raw_data()
# Description:
#     read raw data from input raw_database to set unmerged_data attribute
# Parameters:
#     $filename
# Return:
#     none
sub read_raw_data {
    my $self = shift;
    my @sources = (
        "alpha_api", "nero", "star",
    );

    foreach my $source (@sources) {
        my $path = $self->{directory} . "/raw_" . $source . ".json";
        open my $file, '<', $path or die "Cannot read raw database file for " . $source . ": $!\n";
        my $raw_database_content = do {local $/; <$file> };
        close $file;
        $self->{$source} = JSON::decode_json($raw_database_content);
    }

    return;
}

# Subroutine Name: read_alpha_api_training()
# Example use: data_merger->read_akip_training()
# Description:
#     
# Parameters:
#     
# Return:
#     
sub read_alpha_api_training {
    my $self = shift;
    my $dirname = $self->{directory};
    my $path = $dirname . "/raw_alpha_api.json";
    open my $file, '<', $path or die "Cannot read static raw_alpha_api file: $!\n";
    my $raw_alpha_api = do {local $/; <$file> };
    close $file;
    $self->{alpha_api} = JSON::decode_json($raw_alpha_api);

    $self->read_alpha_api_history();

    return;
}

# Subroutine Name: read_alpha_api_history()
# Example use: data_merger->read_alpha_api_history()
# Description: 
#     reads alpha_api data within 10 days ago
# Parameters:
#     
# Return:
#     
sub read_alpha_api_history {
    my $self = shift;
    my $dirname = $self->{directory};
    my $idas = IDAS->new();

    opendir(DIR, $dirname) or die "Could not open $dirname\n";
    @filenames = readdir(DIR);
    closedir(DIR);

    @filenames = sort(@filenames);                                          # sort files from latest to earliest
    
    my %history_hash;
    
    foreach my $filename (@filenames) {    
        if (!($filename =~ /^alpha_apidata/)){          
            next;
        }
        
        print $filename . "\n";

        $filename = $dirname . "/" . $filename;
        open my $file, '<', $filename or die "Cannot read raw database file for " . $filename . "\n";
        my $alpha_api_csv = '';
        while (my $line = <$file>) {
            $alpha_api_csv .= $line;
        }
        close $file;

        @alpha_api = $idas->csv2list($alpha_api_csv);

        my $prev_name = "";
        my $temp_total = 0;
        my $temp_count = 0;
        my $temp_max = 0;
        my $cpu_total = 0;
        my $cpu_count = 0;
        my $cpu_max = 0;

        my $i = 0;
        foreach my $line (@alpha_api) {
            $i++;
            my @line = @$line;
            my $name = lc($line[0]);
            if ($name =~ /^[^-]+-.*-[^-]+$/) {
                if ( !($name =~ /^[a-zA-z]{3}s/) ) {                        # if not a switch, skip
                    next;
                }
                if ( !($name eq $prev_name) ) {                             # we moved on to a new device
                    if ( !($prev_name eq "") ) {                            # if not the first device
                        if ($temp_count >= 1) {
                            my $temp_avg = $temp_total / $temp_count;
                            push @{ $history_hash{$prev_name}{"temp_avg"} }, $temp_avg;  
                            push @{ $history_hash{$prev_name}{"temp_max"} }, $temp_max;
                        }
                        if ($cpu_count >= 1) {
                            my $cpu_avg = $cpu_total / $cpu_count;
                            push @{ $history_hash{$prev_name}{"cpu_avg"} }, $cpu_avg;
                            push @{ $history_hash{$prev_name}{"cpu_max"} }, $cpu_max;
                        }
                        $temp_total = 0;                                    # reset running avg/max
                        $temp_count = 0;
                        $temp_max = 0;
                        $cpu_total = 0;
                        $cpu_count = 0;
                        $cpu_max = 0;
                    }
                    $prev_name = $name;
                    $history_hash{$name}{"device_name"} = $name;
                }
                
                my $stat = ($line[2] =~ /\.([^\.]+)$/)[0];
                my $value = $line[4];
                if ($value) {
                    if ($stat eq "jnxOperatingCPU") {
                        $cpu_count++;
                        $cpu_total += $value;
                        if ($value > $cpu_max) {
                            $cpu_max = $value;
                        }
                    } elsif ($stat eq "jnxOperatingTemp") {
                        $temp_count++;
                        $temp_total += $value;
                        if ($value > $temp_max) {
                            $temp_max = $value;
                        }
                    }
                }
            }
            # if last devcie in file
            if ($i == scalar @alpha_api) {
                my $temp_avg = $temp_total / $temp_count;
                my $cpu_avg = $cpu_total / $cpu_count;
                push @{ $history_hash{$prev_name}{"temp_avg"} }, $temp_avg;  
                push @{ $history_hash{$prev_name}{"temp_max"} }, $temp_max;
                push @{ $history_hash{$prev_name}{"cpu_avg"} }, $cpu_avg;
                push @{ $history_hash{$prev_name}{"cpu_max"} }, $cpu_max;
            }
        }
    }

    $self->alpha_api_union(\%history_hash);

    return;
}

# Subroutine Name: alpha_api_union()
# Example use: data_merger->alpha_api_union(\%history_hash)
# Description: 
#     union alpha_api today hash and alpha_api history hash and update today alpha_api
# Parameters:
#     $hash_ref: reference to a history hash
# Return:
#     none
sub alpha_api_union {
    my $self = shift;
    my $hash_ref = shift;
    my %history_hash = %{$hash_ref};

    foreach my $outer_key (keys %history_hash) {
        if ( $self->{alpha_api}{$outer_key} ) {
            %temp_hash = %{$history_hash{$outer_key}};
            foreach my $inner_key (keys %temp_hash) {
                $self->{alpha_api}{$outer_key}{$inner_key} = $history_hash{$outer_key}{$inner_key};
            }
        }
    }

    foreach my $device (keys %{$self->{alpha_api}}) {
        if ( !($history_hash{$device}) ) {
            delete($self->{alpha_api}{$device});
        }
    }

    return;
}

# Subroutine Name: merge_data()
# Example use: data_merger->merge_data()
# Description:
#     take raw data from various sources and create sets of objects which will be used to populate database
# Parameters:
#     none
# Return:
#     none
sub merge_data {
    my $self = shift;
    $self->merge_alpha_api();
    $self->merge_nero();
    $self->merge_starlink();
    return;
}

# Subroutine Name: merge_alpha_api()
# Example use: data_merger->merge_alpha_api()
# Description:
#     read from alpha_api raw data and populate the trusted fields of Site and Router objects
# Parameters:
#     none
# Return:
#     none
sub merge_alpha_api {
    my $self = shift;
    my $raw_alpha_api = $self->{alpha_api};                                             # access raw alpha_api
    foreach my $dev_key (keys %$raw_alpha_api) {
        if ($dev_key =~ /^([^-]+)-.*-([^-]+)$/) {
            my $device_name = $1;
            my $site_code = $2;
            my $device_type = ($device_name =~ /^.{3}([a-z]{2})/)[0];           # grab two characters from device name that define device type
          
            if (!exists($self->{sites_hash}{$site_code})) {                     # if the site does not exist, create a new one
                my %new_site_params = (
                    site_code => $site_code,
                );
                my $new_site = Site->new(\%new_site_params);
                
                $self->{sites_hash}{$site_code} = $new_site;
            }

            if ($device_type) {
                # check if router
                if ($device_type =~ /^r./) {
                    $self->create_router($device_name, $site_code, $self->{alpha_api}{$dev_key}{ping_state});
                    my %updated_params = (
                        routers => [$device_name]
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add router name to the existing site
                # check if switch
                } elsif ($device_type =~ /^s./) {
                    $self->create_switch(   $device_name, 
                                            $site_code, 
                                            $self->{alpha_api}{$dev_key}{ping_state}, 
                                            $self->{alpha_api}{$dev_key}{temp_avg},
                                            $self->{alpha_api}{$dev_key}{temp_max},
                                            $self->{alpha_api}{$dev_key}{cpu_avg},
                                            $self->{alpha_api}{$dev_key}{cpu_max}
                    );
                    my %updated_params = (
                        switches => [$device_name]
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add switch name to the existing site
                # check if AP
                } elsif ($device_type =~ /^a./) {
                    $self->create_ap($device_name, $site_code, $self->{alpha_api}{$dev_key}{ping_state});
                    my %updated_params = (
                        aps => [$device_name]
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add ap name to the existing site
                }
            }
        }
    } 
    return;
}

# Subroutine Name: merge_star()
# Example use: data_merger->merge_star()
# Description:
#     read from star raw data and populate the trusted fields of Site and Starlink objects
# Parameters:
#     none
# Return:
#     none
sub merge_star {
    my $self = shift;
    my $raw_star = $self->{star};                                   # access raw starlink data
    foreach my $dev_key (keys %$raw_star) {
        $device_name = $dev_key;
        $site_code = $raw_star->{$dev_key}{site_code};
        $ping_state = $raw_star->{$dev_key}{ping_state};

        if (!exists($self->{sites_hash}{$site_code})) {                     # if the site does not exist, create a new one
            my %new_site_params = (
                site_code => $site_code,
            );
            my $new_site = Site->new(\%new_site_params);
            
            $self->{sites_hash}{$site_code} = $new_site;
        }

        $self->create_starlink($device_name, $site_code, $ping_state);
        my %updated_params = (
            starlinks => [$device_name]
        );
        $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add router name to the existing site
    } 
    return;
}

# Subroutine Name: merge_nero()
# Example use: data_merger->merge_nero()
# Description:
#     read from nero raw data and populate the trusted fields of Site and Router objects
# Parameters:
#     none
# Return:
#     none
sub merge_nero {
    my $self = shift;
    my $raw_nero = $self->{nero};                                   # access raw nero

    foreach my $dev_key (keys %$raw_nero) {
        if ($dev_key =~ /^([^-]+)-\d*$/) {
            my $site_code = $1;
            if (exists($self->{sites_hash}{$site_code})) {
                my $latlng = $self->{nero}{$dev_key}{latlng};
                if ($latlng =~ /^(.+),(.+)$/) {
                    my $lat = $1;
                    my $lng = $2;
                    my %updated_params = (
                        address => $self->{nero}{$dev_key}{address},
                        lat => $lat,
                        lng => $lng,
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);
                }
            }
        }
    }
    return;
}

# Subroutine Name: create_router
# Example use: data_merger->create_router($device_name, $site_code, $ping)
# Description:
#     creates a new Router object and adds it to the routers hash
# Parameters:
#     $router_name
#     $site_code
#     $alpha_api_ping 
# Return:
#     none
sub create_router {
    my $self = shift;
    my ($router_name, $site_code, $alpha_api_ping) = (@_);

    my %new_router_params = (
        router_name => $router_name,
        site_code => $site_code,
        alpha_api_ping => $alpha_api_ping
    );
    my $new_router = Router->new(\%new_router_params);              # create a new Router object
    $self->{routers_hash}{$router_name} = $new_router; 
    return;
}

# Subroutine Name: create_switch
# Example use: data_merger->create_switch($device_name, $site_code, $ping)
# Description:
#     creates a new Switch object and adds it to the switches hash
# Parameters:
#     $switch_name
#     $site_code
#     $alpha_api_ping 
# Return:
#     none
sub create_switch {
    my $self = shift;
    my ($switch_name, $site_code, $alpha_api_ping, $temp_avg, $temp_max, $cpu_avg, $cpu_max) = (@_);
   
    my %new_switch_params = (
        switch_name => $switch_name,
        site_code => $site_code,
        alpha_api_ping => $alpha_api_ping,
        temp_avg => $temp_avg, 
        temp_max => $temp_max,
        cpu_avg => $cpu_avg,
        cpu_max => $cpu_max
    );
    my $new_switch = Switch->new(\%new_switch_params);              # create a new Switch object
    $self->{switches_hash}{$switch_name} = $new_switch; 
    return;
}

# Subroutine Name: create_ap
# Example use: data_merger->create_ap($device_name, $site_code, $ping)
# Description:
#     creates a new AP object and adds it to the AP hash
# Parameters:
#     $ap_name
#     $site_code
#     $alpha_api_ping 
# Return:
#     none
sub create_ap {
    my $self = shift;
    my ($ap_name, $site_code, $alpha_api_ping) = (@_);

    my %new_ap_params = (
        ap_name => $ap_name,
        site_code => $site_code,
        alpha_api_ping => $alpha_api_ping
    );
    my $new_ap = AP->new(\%new_ap_params);              # create a new AP object
    $self->{aps_hash}{$ap_name} = $new_ap; 
    return;
}

# Subroutine Name: create_starlink
# Example use: data_merger->create_starlink($device_name, $site_code, $ping)
# Description:
#     creates a new Starlink object and adds it to the starlinks hash
# Parameters:
#     $router_name
#     $site_code
#     $alpha_api_ping 
# Return:
#     none
sub create_starlink {
    my $self = shift;
    my ($starlink_name, $site_code, $starlink_ping) = (@_);

    my %new_starlink_params = (
        starlink_name => $starlink_name,
        site_code => $site_code,
        starlink_ping => $starlink_ping
    );
    my $new_starlink = Starlink->new(\%new_starlink_params);              # create a new starlink object
    $self->{starlinks_hash}{$starlink_name} = $new_starlink; 
    return;
}

# Subroutine Name: to_database()
# Example use: data_merger->to_database()
# Description:
#     output json database of merged data
# Parameters:
#     $filename
# Return:
#     none
sub to_database {
    my $self = shift;
    my $database_filename = shift;
    my %output_hash;

    my $JSON = JSON->new->utf8;
    $JSON->convert_blessed(1);

    $output_hash{sites} = $self->{sites_hash};
    $output_hash{routers} = $self->{routers_hash};
    $output_hash{switches} = $self->{switches_hash};
    $output_hash{aps} = $self->{aps_hash};
    $output_hash{starlink} = $self->{starlinks_hash};
    my $database_content = $JSON->encode(\%output_hash);
    open my $file, '>', $database_filename or die "Cannot write database file: $!\n";
    print $file $database_content;
    close $file;
    return;
}

1;