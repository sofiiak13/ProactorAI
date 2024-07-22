#
# Title: data_reporter.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-05-13
# Description: 
#

package data_reporter;
use Data::Dumper qw(Dumper);

# Subroutine Name: new()
# Example use: data_reporter->new($data_analyzer)
# Description:
#     create a data_reporter object to report analysis from data_analyzer
# Parameters:
#     $data_analyzer
# Return:
#     $self: new data_reporter object
sub new {
    my $class = shift;
    my $self = {
        type => "",
        analysis => {},
        report => ""
    };
    bless $self, $class;

    my $analyzer = shift;
    $self->{type} = $analyzer->get_type();
    $self->{analysis} = $analyzer->get_analysis();

    if ($self->{type} eq "pru") {
        $self->pru_report();
    }

    return $self;
}

# Subroutine Name: pru_report()
# Example use: data_reporter->pru_report()
# Description:
#     generate PRU report based on analysis
# Parameters:
#     none
# Return:
#     none
sub pru_report {
    my $self = shift;
    my $analysis = $self->{analysis};

    my $header = "ProactorAI Report: Percentage Routers Up
========================================
Sites with less than 100% of routers up:
========================================
";
    my $content = sprintf("%-12s %-12s\n", "Site Code", "% Routers Up");
    foreach my $site_code (keys %$analysis) {
        my $percent = $analysis->{$site_code};
        $percent = substr($percent, 0, 5);
        $content .= sprintf("%-12s %-12s\n", $site_code, $percent);
    };
    $self->{report} = $header . $content;
    return;
}

# Subroutine Name: to_file()
# Example use: data_reporter->to_file($filename)
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

# Subroutine Name: to_email()
# Example use: data_reporter->to_email($to)
# Description:
#     output report to email
# Parameters:
#     $to: email address of recipient
# Return:
#     none
sub to_email {
    my $self = shift;
    my $recipients = shift;       
    my ($to, $cc);  

    if ($recipients =~ /^([^,]+),?(.*)$/){
        $to = $1;
        $cc = $2;
        #print $to . " and " . $cc;
    }              
    
    my $from = 'email.address@email.domain.ca';
    my $subject = 'ProactorAI Report';
    my $body = $self->{report};
    
    open(MAIL, "|/usr/sendmail/path/here -t");
    print MAIL "To: $to\n";
    print MAIL "From: $from\n";

    if ($cc) {
        print "check cc \n";
        print MAIL "Cc: $cc\n";
    }
    
    print MAIL "Subject: $subject\n\n";
    print MAIL $body;
    close(MAIL);
    
    #print "Email Sent Successfully\n";      
    return;
}

1;