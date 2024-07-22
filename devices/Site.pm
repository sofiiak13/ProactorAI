#
# Title: Site.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-15
# Description: object to hold site info
#

package Site;
use Data::Dumper qw(Dumper);
# Subroutine Name: new()
# Example use: Site->new(\%params)
# Description:
#     creates a new site object
# Parameters:
#     %params: hash with site's parameters
# Return:
#     $self: new site object
sub new {
    my $class = shift;
    my $param = shift;

    # Default values
    my $site_code = defined($param->{site_code}) ? $param->{site_code} : 'no_site_code';
    my $address = defined($param->{address}) ? $param->{address} : 'no_address';
    my $lat = defined($param->{lat}) ? $param->{lat} : 0;
    my $lng = defined($param->{lng}) ? $param->{lng} : 0;
    my $routers = defined($param->{routers}) ? $param->{routers} : [];
    my $switches = defined($param->{switches}) ? $param->{switches} : [];
    my $aps = defined($param->{aps}) ? $param->{aps} : [];
    my $starlinks = defined($param->{starlinks}) ? $param->{starlinks} : [];

    my $self = {
        site_code => $site_code,
        address => $address,
        lat => $lat,
        lng => $lng,
        routers => $routers,
        switches => $switches,
        aps => $aps,
        starlinks => $starlinks
    };

    bless $self, $class;
    return $self;
}


# Subroutine Name: TO_JSON
# Example use: 
# Description:
#     allows Site objects to be converted to a json with convert_blessed(1)
# Parameters:
#     none
# Return:
#     none
sub TO_JSON { return { %{ shift() } }; }


# Subroutine Name: update_site()
# Example use: Site->update_site(\%params)
# Description:
#     updates all values in site's attribute hash
# Parameters:
#     %params: hash with site's new parameters
# Return:
#     none
sub update_site {
    my $self = shift;
    my $param = shift;

    $self->{site_code} = $param->{site_code} if defined($param->{site_code});
    $self->{address} = $param->{address} if defined($param->{address});
    $self->{lat} = $param->{lat} if defined($param->{lat});
    $self->{lng} = $param->{lng} if defined($param->{lng});
    push @{$self->{routers}}, @{$param->{routers}} if defined($param->{routers});
    push @{$self->{switches}}, @{$param->{switches}} if defined($param->{switches});
    push @{$self->{aps}}, @{$param->{aps}} if defined($param->{aps});
    push @{$self->{starlinks}}, @{$param->{starlinks}} if defined($param->{starlinks});

    return;
}

sub get_site_info {
    $self = shift;
    return $self;
}

1;