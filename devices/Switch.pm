#
# Title: Router.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-24
# Description: object to hold router info
#


package Switch;
use Data::Dumper qw(Dumper);

# Subroutine Name: new() 
# Example use: Switch->new(\%params)
# Description:
#     creates a new Switch object
# Parameters:
#     %params: hash with switch's parameters
# Return:
#     $self: new Switch object
sub new {
    my $class = shift;
    my $param = shift;

    # Default values
    my $switch_name = defined($param->{switch_name}) ? $param->{switch_name} : 'x';
    my $model = defined($param->{model}) ? $param->{model} : 'x';
    my $site_code = defined($param->{site_code}) ? $param->{site_code} : 'x';
    my $alpha_ping = defined($param->{alpha_ping}) ? $param->{alpha_ping} : 'x';
    my $ping_latency_avg = defined($param->{ping_latency_avg}) ? $param->{ping_latency_avg} : {};
    my $ping_latency_max = defined($param->{ping_latency_max}) ? $param->{ping_latency_max} : {};
    my $temp_avg = defined($param->{temp_avg}) ? $param->{temp_avg} : {};
    my $temp_max = defined($param->{temp_max}) ? $param->{temp_max} : {};
    my $cpu_avg = defined($param->{cpu_avg}) ? $param->{cpu_avg} : {};
    my $cpu_max = defined($param->{cpu_max}) ? $param->{cpu_max} : {};
    my $events = defined($param->{events}) ? $param->{events} : {};

    my $self = {
        switch_name => $switch_name,
        model => $model,
        site_code => $site_code,
        alpha_ping => $alpha_ping,
        ping_latency_avg => $ping_latency_avg,
        ping_latency_max => $ping_latency_max,
        temp_avg => $temp_avg,
        cpu_avg => $cpu_avg,
        temp_max => $temp_max,
        cpu_max => $cpu_max,
        events => $events
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

sub get_switch_info {
    $self = shift;
    return $self;
}

1;
