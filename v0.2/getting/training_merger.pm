# Title: training_merger.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-06
# Description: object to get training data from APIs
#

package training_merger;

use Time::Piece;
use Data::Dumper qw(Dumper);


# Subroutine Name: new()
# Example use: training_merger->new()
# Description:
#     create a training_merger object to collect raw databases and format them
# Parameters:
#     $directory
# Return:
#     $training_merger
#
sub new {
    my $class = shift;
    my $self = {
        directory => shift,

        raw_alpha => {},
        
        sites_hash => {},
        routers_hash => {},
        aps_hash => {},
        switches_hash => {},
        starlinks_hash => {}
    };
    bless $self, $class;

    $self->read_raw_alpha();
    $self->read_alpha_logs();
    $self->merge_alpha();

    return $self;
}


# Subroutine Name: read_raw_alpha()
# Example use: training_merger->read_raw_alpha()
# Description: 
#     reads alpha data from raw databases
# Parameters:
#     none
# Return:
#     
sub read_raw_alpha {
    my $self = shift;
    my $raw_dir = $self->{directory} . "/raw/";

    opendir(DIR, $raw_dir) or die "Could not open $raw_dir\n";
    @filenames = readdir(DIR);
    closedir(DIR);

    @filenames = sort(@filenames);                                          # sort files from earliest to latest
    
    my $file_number = 0;
    foreach my $filename (@filenames) {    
        if (!($filename =~ /^raw_alpha_data/)){          
            next;   
        }

        print("...Merging from " . $filename . "...\n");

        my $path = $raw_dir . $filename;
        my $alpha = $self->csv_file_to_list($path); 

        my $prev_name = "";
        my $temp_total = 0;
        my $temp_count = 0;
        my $temp_max = 0;
        my $cpu_total = 0;
        my $cpu_count = 0;
        my $cpu_max = 0;

        my $line_number = 0;
        my $group = 0;                                                      # 0 = average, 1 = max 
        foreach my $line (@{$alpha}) {
            $line_number++;
            my @line = @$line;

            if ($line[0] eq "MAXIMUMS") {
                $group = 1;
                next;
            }
            my $name = lc($line[0]);
            if ($name =~ /^regex$/) {
                if ( !($name =~ /^switch_regex/) ) {                        # if not a switch, skip
                    next;
                }

                if ( !($name eq $prev_name) ) {                             # if we moved on to a new device
                    if ( !($prev_name eq "") ) {                            # if not the first device in file
                        if ($temp_count >= 1) {
                            
                            if ($group == 0) {                                          # insert in avg "array"
                                my $temp_avg = $temp_total / $temp_count;               # calc avg
                                $self->{raw_alpha}{$prev_name}{temp_avg}{$file_number} = $temp_avg;
                            } elsif ($group == 1) {                                     # insert in max "array"
                                $self->{raw_alpha}{$prev_name}{temp_max}{$file_number} = $temp_max;
                            }
                        }
                        if ($cpu_count >= 1) {
                            my $cpu_avg = $cpu_total / $cpu_count;
                            if ($group == 0) {
                                my $cpu_avg = $cpu_total / $cpu_count;
                                $self->{raw_alpha}{$prev_name}{cpu_avg}{$file_number} = $cpu_avg;
                            } elsif ($group = 1) {
                                $self->{raw_alpha}{$prev_name}{cpu_max}{$file_number} = $cpu_max;
                            }  
                        }
                        $temp_total = 0;                                    # reset running avg/max
                        $temp_count = 0;
                        $temp_max = 0;
                        $cpu_total = 0;
                        $cpu_count = 0;
                        $cpu_max = 0;
                    }
                    $prev_name = $name;
                    $self->{raw_alpha}{$name}{device_name} = $name;
                }
                

                my ($model, $stat) = $line[2] =~ /^regex$/;
                    
                if ($model =~ /^CISCO/) {
                    $self->{raw_alpha}{$name}{model} = "cisco";
                } elsif ($model =~ /^JUNIPER/) { 
                    $self->{raw_alpha}{$name}{model} = "juniper";
                }

                my $value = $line[4];

                if ($value) {
                    if ($stat eq "cpu" || $stat eq "other_cpu") {
                        $cpu_count++;
                        $cpu_total += $value;
                        if ($value > $cpu_max) {
                            $cpu_max = $value;
                        }
                    } elsif ($stat eq "temp" || $stat eq "temperature") {
                        $temp_count++;
                        $temp_total += $value;
                        if ($value > $temp_max) {
                            $temp_max = $value;
                        }
                    } elsif ($stat eq "latency") {
                        if ($group == 0) {
                            $self->{raw_alpha}{$prev_name}{ping_latency_avg}{$file_number} = $value;
                        } elsif ($group == 1) {
                            $self->{raw_alpha}{$prev_name}{ping_latency_max}{$file_number} = $value;
                        }
                    }
                }
            }

            if ($line_number == scalar @{$alpha}) {                      # if last line in file, stop and calc/push stats
                if ($temp_count >= 1) {        
                    if ($group == 0) {                                          # insert in avg "array"
                        my $temp_avg = $temp_total / $temp_count;
                        $self->{raw_alpha}{$prev_name}{temp_avg}{$file_number} = $temp_avg;
                    } elsif ($group == 1) {                                     # insert in max "array"
                        $self->{raw_alpha}{$prev_name}{temp_max}{$file_number} = $temp_max;
                    }
                }
                if ($cpu_count >= 1) {
                    if ($group == 0) {
                        my $cpu_avg = $cpu_total / $cpu_count;
                        $self->{raw_alpha}{$prev_name}{cpu_avg}{$file_number} = $cpu_avg;
                    } elsif ($group = 1) {
                        $self->{raw_alpha}{$prev_name}{cpu_max}{$file_number} = $cpu_max;
                    }  
                }
            }
        }
        $file_number++;
    }
    return;
}


# Subroutine Name: read_alpha_logs()
# Example use: training_merger->read_alpha_logs()
# Description: 
#     reads down alerts from alpha log database
# Parameters:
#     none
# Return:
#     none
sub read_alpha_logs {
    my $self = shift;
    my $raw_dir = $self->{directory} . "/raw/";

    opendir(DIR, $raw_dir) or die "Could not open $raw_dir\n";
    @filenames = readdir(DIR);
    closedir(DIR);
    
    foreach my $filename (@filenames) {    
        if (!($filename =~ /^raw_alpha_logs/)){          
            next;
        }

        print("...Merging from " . $filename . "...\n");

        my $path = $raw_dir . $filename;
        my $logs = $self->csv_file_to_list($path);

        foreach my $line (@{$logs}) {
            my @line = @$line;
            my $name = lc($line[1]);
            if ($name =~ /^regex$/) {
                if ( !($name =~ /^switch_regex/) ) {               # if not a switch, skip
                    next;
                }

                my $event_day = $self->unix_time_difference($line[0], $filename);

                # overwrite first and/or last event of the day, as appropriate
                my $event_type = $line[6];
                if ( !(exists($self->{raw_alpha}{$name}{events}{$event_day})) ) {
                    $self->{raw_alpha}{$name}{events}{$event_day}[0] = $event_type;
                    $self->{raw_alpha}{$name}{events}{$event_day}[1] = $event_type;
                } else {
                    $self->{raw_alpha}{$name}{events}{$event_day}[1] = $event_type;
                }
            }
        }
    }
    return;
}

# Subroutine Name: unix_time_difference()
# Example use: training_merger->unix_time_difference($down_timestamp, $filename)
# Description:
#     convert down-alert unix timestamp into equivalent day of training period
# Parameters:
#     $down_timestamp: string representing unix time of the downtime event
#     $filename: string representing current time in yyyy-mm-dd format
# Return:
#     $event_day: string representing time of the event in yyyy-mm-dd format
sub unix_time_difference {
    my $self = shift;
    my $down_timestamp = shift;
    my ($start_date_str) = shift =~ /(\d{4}-\d{2}-\d{2})/;
    my $start_date = Time::Piece->strptime($start_date_str, "%Y-%m-%d");
    my $start_timestamp = $start_date->epoch;
    my $difference_sec = $down_timestamp - $start_timestamp;
    my $event_day = int($difference_sec / (24 * 60 * 60));

    return $event_day;
}

# Subroutine Name: csv_file_to_list()
# Example use: training_merger->csv_file_to_list($path)
# Description:
#     reads data from a csv file and converts it to a list
# Parameters:
#     $path: string; path to the csv file
# Return:
#     \@list: array reference
#
sub csv_file_to_list {
    my $self = shift;
    my $path = shift;
   
    open my $file, '<', $path or die "Cannot read log database file for " . $filename . "\n";
    my $csv = '';
    while (my $line = <$file>) {
        $csv .= $line;
    }
    close $file; 

    # convert csv to list
    my @lines = split /\n/, $csv;
    my @list;
    foreach my $line (@lines) {
        my @fields = split /,/, $line;
        push @list, \@fields;
    }

    return \@list;
}

# Subroutine Name: merge_alpha()
# Example use: training_merger->merge_alpha()
# Description:
#     use alpha raw data to populate Site and Router objects
# Parameters: 
#     none
# Return:
#     none
sub merge_alpha {
    my $self = shift;
    my $raw_alpha = $self->{raw_alpha};

    print("...Merging alpha data into objects...\n");
    
    foreach my $dev_key (keys %$raw_alpha) {
        if ($dev_key =~ /^regex$/) {
            my $device_name = $1;
            my $site_code = $2;
            my $device_type = ($device_name =~ /^regex/)[0];                    # grab two characters from device name that define device type
          
            if (!exists($self->{sites_hash}{$site_code})) {                     # if the site does not exist, create a new one
                my %new_site_params = (
                    site_code => $site_code,
                );
                my $new_site = Site->new(\%new_site_params);
                
                $self->{sites_hash}{$site_code} = $new_site;
            }

            if ($device_type) {
                # check if router
                if ($device_type =~ /^regex/) {
                    $self->create_router($device_name, $site_code, $self->{raw_alpha}{$dev_key}{ping_state});
                    my %updated_params = (
                        routers => [$device_name]
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add router name to the existing site
                # check if switch
                } elsif ($device_type =~ /^regex/) {
                    $self->create_switch(   $device_name, 
                                            $self->{raw_alpha}{$dev_key}{model},
                                            $site_code,
                                            $self->{raw_alpha}{$dev_key}{alpha_ping},
                                            $self->{raw_alpha}{$dev_key}{ping_latency_avg},
                                            $self->{raw_alpha}{$dev_key}{ping_latency_max},
                                            $self->{raw_alpha}{$dev_key}{temp_avg},
                                            $self->{raw_alpha}{$dev_key}{temp_max},
                                            $self->{raw_alpha}{$dev_key}{cpu_avg},
                                            $self->{raw_alpha}{$dev_key}{cpu_max},
                                            $self->{raw_alpha}{$dev_key}{events}

                    );
                    my %updated_params = (
                        switches => [$device_name]
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add switch name to the existing site
                # check if AP
                } elsif ($device_type =~ /^regex/) {
                    $self->create_ap($device_name, $site_code, $self->{raw_alpha}{$dev_key}{ping_state});
                    my %updated_params = (
                        aps => [$device_name]
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add ap name to the existing site
                }
            }
            delete($self->{raw_alpha}{$dev_key});
        }
    } 
    return;
}

# Subroutine Name: create_router
# Example use: training_merger->create_router($device_name, $site_code, $ping)
# Description:
#     creates a new Router object and adds it to the routers hash
# Parameters:
#     $router_name
#     $site_code
#     $alpha_ping 
# Return:
#     none
sub create_router {
    my $self = shift;
    my ($router_name, $site_code, $alpha_ping) = (@_);

    my %new_router_params = (
        router_name => $router_name,
        site_code => $site_code,
        alpha_ping => $alpha_ping
    );
    my $new_router = Router->new(\%new_router_params);              # create a new Router object
    $self->{routers_hash}{$router_name} = $new_router; 
    return;
}


# Subroutine Name: create_switch
# Example use: training_merger->create_switch($device_name, $site_code, $ping)
# Description:
#     creates a new Switch object and adds it to the switches hash
# Parameters:
#     $switch_name
#     $site_code
#     $alpha_ping 
# Return:
#     none
sub create_switch {
    my $self = shift;
    my ($switch_name, $model, $site_code, $alpha_ping, $ping_latency_avg, $ping_latency_max, $temp_avg, $temp_max, $cpu_avg, $cpu_max, $events) = (@_);
   
    my %new_switch_params = (
        switch_name => $switch_name,
        model => $model,
        site_code => $site_code,
        alpha_ping => $alpha_ping,
        ping_latency_avg => $ping_latency_avg,
        ping_latency_max => $ping_latency_max,
        temp_avg => $temp_avg, 
        temp_max => $temp_max,
        cpu_avg => $cpu_avg,   
        cpu_max => $cpu_max,
        events => $events
    );
    my $new_switch = Switch->new(\%new_switch_params);              # create a new Switch object
    $self->{switches_hash}{$switch_name} = $new_switch; 
    return;
}


# Subroutine Name: create_ap
# Example use: training_merger->create_ap($device_name, $site_code, $ping)
# Description:
#     creates a new AP object and adds it to the AP hash
# Parameters:
#     $ap_name
#     $site_code
#     $alpha_ping 
# Return:
#     none
sub create_ap {
    my $self = shift;
    my ($ap_name, $site_code, $alpha_ping) = (@_);

    my %new_ap_params = (
        ap_name => $ap_name,
        site_code => $site_code,
        alpha_ping => $alpha_ping
    );
    my $new_ap = AP->new(\%new_ap_params);              # create a new AP object
    $self->{aps_hash}{$ap_name} = $new_ap; 
    return;
}
  

# Subroutine Name: create_starlink
# Example use: training_merger->create_starlink($device_name, $site_code, $ping)
# Description:
#     creates a new Starlink object and adds it to the starlinks hash
# Parameters:
#     $router_name
#     $site_code
#     $alpha_ping 
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
# Example use: training_merger->to_database()
# Description:
#     output json database of merged data (site/device objects)
# Parameters:
#     $filename
# Return:
#     none
sub to_database {
    my $self = shift;
    my @date_range = @_;
    my $half1 = join("-", @date_range[0..2]);
    my $half2 = join("-", @date_range[3..5]);
    my $filename_stub = "alpha_switches_" . $half1 . "_" . $half2;
    my $formatted_dir = $self->{directory} . "/formatted/";

    my $JSON = JSON->new->utf8;                                         # prepare JSON object for encoding
    $JSON->convert_blessed(1);

    my $file_number = 0;
    my $switch_count = 0;
    my %output_hash;

    foreach my $switch ( keys %{$self->{switches_hash}} ) {                 # add 200 keys to hash, then write to file
        $output_hash{$switch} = $self->{switches_hash}{$switch};
        $switch_count++;
        if ($switch_count % 200 == 0) {
            my $database_content = $JSON->encode(\%output_hash);
            my $filename = $filename_stub . "_" . $file_number . ".json";
            my $path = $formatted_dir . $filename;

            print("...Writing to " . $filename . "...\n");

            open my $file, '>', $path or die "Cannot write formatted database file: $!\n";
            print $file $database_content;
            close $file;
            
            %output_hash = ();                                          # clear hash and increment file
            $file_number++;
        }
    }

    if (scalar keys %output_hash) {                                     # write any leftover keys to last file
        my $database_content = $JSON->encode(\%output_hash);
        my $filename = $filename_stub . "_" . $file_number . ".json";
        my $path = $formatted_dir . $filename;

        print("...Writing to " . $filename . "...\n");

        open my $file, '>', $path or die "Cannot write formatted database file: $!\n";
        print $file $database_content;
        close $file;
    }
    return;
}

1;