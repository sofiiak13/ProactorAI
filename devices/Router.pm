#
# Title: Router.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-15
# Description: object to hold router info
#


package Router;
use Data::Dumper qw(Dumper);

# Subroutine Name: new()
# Example use: Router->new(\%params)
# Description:
#     creates a new Router object
# Parameters:
#     %params: hash with router's parameters
# Return:
#     $self: new Router object
sub new {
    my $class = shift;
    my $param = shift;

    # Default values
    my $router_name = defined($param->{router_name}) ? $param->{router_name} : 'no_router_name';
    my $site_code = defined($param->{site_code}) ? $param->{site_code} : 'no_site_code';
    my $alpha_ping = defined($param->{alpha_ping}) ? $param->{alpha_ping} : 'no_ping';

    my $self = {
        router_name => $router_name,
        site_code => $site_code,
        alpha_ping => $alpha_ping
    };

    bless $self, $class;
    return $self;
}

# Subroutine Name: TO_JSON
# Example use: 
# Description:
#     allows Router objects to be converted to a json with convert_blessed(1)
# Parameters:
#     none
# Return:
#     none
sub TO_JSON { return { %{ shift() } }; }

# Subroutine Name: update_router()
# Example use: router->update_router(\%params)
# Description:
#     updates all values in router's attribute hash
# Parameters:
#     %params: hash with new parameters
# Return:
#     none
sub update_router {
    my $self = shift;
    my $param = shift;

    $self->{router_name} = $param->{router_name} if defined($param->{router_name});
    $self->{site_code} = $param->{site_code} if defined($param->{site_code});
    $self->{alpha_ping} = $param->{alpha_ping} if defined($param->{alpha_ping});
}

sub get_router_info {
    $self = shift;
    return $self;
}

1;