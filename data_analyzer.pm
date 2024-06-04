#
# Title: data_analyzer.pl
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: object to analyze data from data_merger
#

package data_analyzer;

# Subroutine Name: new()
# Example use: 
# Description:
#     create a data_analyzer object to analyze data from data_merger
# Parameters:
#     $filename
# Return:
#     $self: new data_analyzer object
sub new {
    my $class = shift;
    my $self = {
        data => {},
        sites_hash => {},
        routers_hash => {},
        analysis => {}
    };
    bless $self, $class;
    my $arg = shift;
    # multiple constructors
    if ($arg =~ /\w/ && !ref($arg)) {  # if the argument passed is a string
        my $filename = $arg;           # JSON to be analyzed
        $self->read_data($filename);
        $self->build_sites();
        $self->build_routers();
    } else {
        my $data_merger = $arg;
        $self->get_devices($data_merger);
    }
    $self->analyze_data();
    return $self;
}

# Subroutine Name: read_data()
# Example use: 
# Description:
#     analyze data from input database file
# Parameters:
#     $filename
# Return:
#     data
sub read_data {
    my $self = shift;
    my $filename = shift;
    open my $file, '<', $filename or die "Cannot read database file: $!\n";
    my $database_content = do {local $/; <$file> };
    close $file;
    $self->{data} = JSON::decode_json($database_content);
    return;
}

# Subroutine Name: build_sites()
# Example use: 
# Description:
#     read data from a string representing sites, turn them back into Site objects and update sites_hash
# Parameters:
#     none
# Return:
#     none
sub build_sites {
    my $self = shift;
    my $sites = $self->{data}{sites};
    foreach my $site (keys %$sites) {
        my $new_site_params = $sites->{$site};
        my $new_site = Site->new($new_site_params);
        $self->{sites_hash}{$site} = $new_site;
    }
    return;
}

# Subroutine Name: build_routers()
# Example use: 
# Description:
#     read data from a string representing routers, turn them back into Router objects and update routers_hash
# Parameters:
#     none
# Return:
#     none
sub build_routers {
    my $self = shift;
    my $routers = $self->{data}{routers};

    foreach my $router (keys %$routers) {
        my $new_router_params = $routers->{$router};
        my $new_router = Router->new($new_router_params);
        $self->{routers_hash}{$router} = $new_router;
    }
    return;
}

# Subroutine Name: get_devices()
# Example use: 
# Description:
#     gets data of all devices directly from data_merger object and updates attributes of data_analyzer
# Parameters:
#     none
# Return:
#     none
sub get_devices {
    my $self = shift;
    my $data_merger = shift;

    $self->{sites_hash} = $data_merger->get_sites();
    $self->{routers_hash} = $data_merger->get_routers();
    return;
}

# Subroutine Name: analyze_data()
# Example use: 
# Description:
#     analyze data
# Parameters:
#     none
# Return:
#     analysis
sub analyze_data {
    my $self = shift;
    my $sites = $self->{sites_hash};
    my $routers = $self->{routers_hash};

    foreach my $site (%$sites) {
        if ($site->{routers}) {
            my @router_list = @{$site->{routers}};
            my $router_count = scalar @router_list;
            my $total_ping = 0;
            foreach my $router_name (@router_list) {
                my $router = $routers->{$router_name};
                my $ping = $router->{alpha_ping};
                if ($ping) {
                    if ($ping eq "up") {
                        $total_ping += 100;
                    } elsif ($ping eq "down") {
                        $total_ping += 0;
                    }
                } else {
                    $router_count--;
                }
            }
            if ($router_count < 1) {
                next;
            }
            my $avg_ping = $total_ping / $router_count;
            if ($avg_ping < 100) {
                $self->{analysis}{$site->{site_code}} = $avg_ping;
            }
        }
    }
    return;
}

# Subroutine Name: get_analysis()
# Example use: data_analyzer->get_analysis()
# Description:
#     used to get analysis
# Parameters:
#     none
# Return:
#     $analysis
sub get_analysis {
    my $self = shift;
    return $self->{analysis};
}

1;