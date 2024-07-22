#
# Title: AP.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-24
# Description: object to hold Access Point info
#

package AP;
use Data::Dumper qw(Dumper);

# Subroutine Name: new()
# Example use: AP->new(\%params)
# Description:
#     creates a new AP object
# Parameters:
#     %params: hash with AP's parameters
# Return:
#     $self: new AP object
sub new {
    my $class = shift;
    my $param = shift;

    # Default values
    my $ap_name = defined($param->{ap_name}) ? $param->{ap_name} : 'no_ap_name';
    my $site_code = defined($param->{site_code}) ? $param->{site_code} : 'no_site_code';
    my $alpha_ping = defined($param->{alpha_ping}) ? $param->{alpha_ping} : 'no_ping';

    my $self = {
        ap_name => $ap_name,
        site_code => $site_code,
        alpha_ping => $alpha_ping
    };

    bless $self, $class;
    return $self;
}

# Subroutine Name: TO_JSON
# Example use: 
# Description:
#     allows AP objects to be converted to a json with convert_blessed(1)
# Parameters:
#     none
# Return:
#     none
sub TO_JSON { return { %{ shift() } }; }

# Subroutine Name: update_ap()
# Example use: ap->update_ap(\%params)
# Description:
#     updates all values in AP's attribute hash
# Parameters:
#     %params: hash with new parameters
# Return:
#     none
sub update_ap {
    my $self = shift;
    my $param = shift;

    $self->{ap_name} = $param->{ap_name} if defined($param->{ap_name});
    $self->{site_code} = $param->{site_code} if defined($param->{site_code});
    $self->{alpha_ping} = $param->{alpha_ping} if defined($param->{alpha_ping});
}

sub get_ap_info {
    $self = shift;
    return $self;
}

1;