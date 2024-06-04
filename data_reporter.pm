#
# Title: data_reporter.pl
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: 
#

package data_reporter;

# Subroutine Name: new()
# Example use: 
# Description:
#     create a data_reporter object to report analysis from data_analyzer
# Parameters:
#     $data_analyzer
# Return:
#     $self: new data_reporter object
sub new {
    my $class = shift;
    my $self = {
        analysis => {},
        report => ""
    };
    bless $self, $class;
    my $analyzer = shift;
    $self->{analysis} = $analyzer->get_analysis();
    $self->create_report();
    return $self;
}

# Subroutine Name: create_report()
# Example use: 
# Description:
#     generate the report based on analysis
# Parameters:
#     $data_analyzer
# Return:
#     report
sub create_report {
    my $self = shift;
    my $analysis = $self->{analysis};
    my $header = "This is a report.
==================================================================================
";
    my $content = "Site\tPercentage\n";
    foreach my $site_code (keys %$analysis) {
        $content .= $site_code . "\t" . $analysis->{$site_code} . "\n";
    };
    $self->{report} = $header . $content;
    return;
}

# Subroutine Name: to_file()
# Example use: 
# Description:
#     output report to file
# Parameters:
#     $filename
# Return:
#     none
sub to_file {
    my $self = shift;
    my $filename = shift;
    open my $file, '>', $filename or die "Cannot write output file: $!\n";
    print $file $self->{report};
    close $file;
}

1;