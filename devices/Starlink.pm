#
# Title: Starlink.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-24
# Description: object to hold Starlink device info
#

package Starlink;
use Data::Dumper qw(Dumper);

# Subroutine Name: new()
# Example use: Starlink->new(\%params)
# Description:
#     creates a new Starlink object
# Parameters:
#     %params: hash with Starlink device's parameters
# Return:
#     $self: new Starlink object
sub new {
    my $class = shift;
    my $param = shift;

    # Default values
    my $starlink_name = defined($param->{starlink_name}) ? $param->{starlink_name} : 'no_starlink_name';
    my $site_code = defined($param->{site_code}) ? $param->{site_code} : 'no_site_code';
    my $starlink_ping = defined($param->{starlink_ping}) ? $param->{starlink_ping} : 'no_ping';

    my $self = {
        starlink_name => $starlink_name,
        site_code => $site_code,
        starlink_ping => $starlink_ping
    };

    bless $self, $class;
    return $self;
}

# Subroutine Name: TO_JSON
# Example use: 
# Description:
#     allows Starlink objects to be converted to a json with convert_blessed(1)
# Parameters:
#     none
# Return:
#     none
sub TO_JSON { return { %{ shift() } }; }

# Subroutine Name: update_starlink()
# Example use: Starlink->update_starlink(\%params)
# Description:
#     updates all values in router's attribute hash
# Parameters:
#     %params: hash with new parameters
# Return:
#     none
sub update_router {
    my $self = shift;
    my $param = shift;

    $self->{starlink_name} = $param->{starlink_name} if defined($param->{starlink_name});
    $self->{site_code} = $param->{site_code} if defined($param->{site_code});
    $self->{starlink_ping} = $param->{starlink_ping} if defined($param->{starlink_ping});
}

sub get_starlink_info {
    $self = shift;
    return $self;
}

1;