#
# Title: data_merger.pl
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: object to collect and organize API data from data_getter
#

package data_merger;

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
    my $filename = shift;
    my $self = {
        raw_data => {},
        sites_hash => {},
        routers_hash => {}
    };
    bless $self, $class;
    $self->read_raw_data($filename);
    $self->merge_data();
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

# Subroutine Name: read_raw_data()
# Example use: data_merger->read_raw_data()
# Description:
#     read raw data from input raw_database to set unmerged_data attribute
# Parameters:
#     $filename
# Return:
#     raw_data
sub read_raw_data {
    my $self = shift;
    my $raw_filename = shift;
    open my $file, '<', $raw_filename or die "Cannot read raw database file: $!\n";
    my $raw_database_content = do {local $/; <$file> };
    close $file;
    $self->{raw_data} = JSON::decode_json($raw_database_content);
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
    my $raw_data = $self->{raw_data};
    $self->read_alpha();
    $self->read_gamma();
    return;
}

# Subroutine Name: read_alpha()
# Example use: data_merger->read_alpha()
# Description:
#     read from alpha raw data and populate the trusted fields of Site and Router objects
# Parameters:
#     none
# Return:
#     none
sub read_alpha {
    my $self = shift;
    my $raw_alpha = $self->{raw_data}{alpha};                                   # access raw alpha
    foreach my $dev_key (keys %$raw_alpha) {
        if ($dev_key =~ /anonymized regex$/) {
            my $device_name = $1;
            my $site_code = $2;
            my $device_type = ($device_name =~ /anonymized regex/)[0];           # grab two characters from device name that define device type
          
            if (!exists($self->{sites_hash}{$site_code})) {                     # if the site does not exist, create a new one
                my %new_site_params = (
                    site_code => $site_code,
                );
                my $new_site = Site->new(\%new_site_params);
                
                $self->{sites_hash}{$site_code} = $new_site;
            }
            
            if ($device_type) {
                if ($device_type =~ /anonymized regex/) {                                   # now site exists, so check if the device is a router
                    $self->create_router($device_name, $site_code, $self->{raw_data}{alpha}{$dev_key}{ping_state});
                    my %updated_params = (
                        routers => [$device_name]
                    );
                    $self->{sites_hash}{$site_code}->update_site(\%updated_params);  # add router name to the existing site
                }
            }
        }
    } 
    return;
}

# Subroutine Name: read_gamma()
# Example use: data_merger->read_gamma()
# Description:
#     read from gamma raw data and populate the trusted fields of Site and Router objects
# Parameters:
#     none
# Return:
#     none
sub read_gamma {
    my $self = shift;
    my $raw_gamma = $self->{raw_data}{gamma};                                   # access raw gamma

    foreach my $dev_key (keys %$raw_gamma) {
        if ($dev_key =~ /anonymized regex$/){
            my $site_code = $1;
            if (exists($self->{sites_hash}{$site_code})){
                my $latlng = $self->{raw_data}{gamma}{$dev_key}{latlng};
                $latlng =~ /anonymized regex$/;
                my $lat = $1;
                my $lng = $2;
                my %updated_params = (
                    address => $self->{raw_data}{gamma}{$dev_key}{address},
                    lat => $lat,
                    lng => $lng,
                );
                $self->{sites_hash}{$site_code}->update_site(\%updated_params);
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
#     $alpha_ping 
# Return:
#     none
sub create_router {
    my $self = shift;
    my $router_name = shift;
    my $site_code = shift;
    my $alpha_ping = shift;

    my %new_router_params = (
        router_name => $router_name,
        site_code => $site_code,
        alpha_ping => $alpha_ping
    );
    my $new_router = Router->new(\%new_router_params);              # create a new router object
    $self->{routers_hash}{$router_name} = $new_router; 
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
    my $database_content = $JSON->encode(\%output_hash);
    open my $file, '>', $database_filename or die "Cannot write database file: $!\n";
    print $file $database_content;
    close $file;
    return;
}

1;