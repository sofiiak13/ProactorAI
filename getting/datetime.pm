#
# Title: datetime.pm
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-07
# Description: 
#

package datetime;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub is_leap_year {
    my $self = shift;
    my ($year) = @_;
    return ($year % 4 == 0 && $year % 100 != 0) || ($year % 400 == 0);
}
 
sub days_in_month {
    my $self = shift;
    my ($year, $month) = @_;
    my @days_in_month = (31, $self->is_leap_year($year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    return $days_in_month[$month - 1];
}
 
sub format_date {
    my $self = shift;
    my ($year, $month, $day) = @_;
    return sprintf("%04d-%02d-%02d", $year, $month, $day);
}

# start and end dates are inclusive
sub dates_between {
    my $self = shift;
    my @date_range = @_;
    my $start_year = $date_range[0];
    my $start_month = $date_range[1];
    my $start_day = $date_range[2];

    my $end_year = $date_range[3];
    my $end_month = $date_range[4];
    my $end_day = $date_range[5];

    my @output_dates;
 
    my $current_year = $start_year;
    my $current_month = $start_month;
    my $current_day = $start_day;
 
    while (($current_year < $end_year) || 
           ($current_year == $end_year && $current_month < $end_month) || 
           ($current_year == $end_year && $current_month == $end_month && $current_day <= $end_day)) {
 
        my $date_string = $self->format_date($current_year, $current_month, $current_day);
        push(@output_dates, $date_string);
 
        $current_day++;
        if ($current_day > $self->days_in_month($current_year, $current_month)) {
            $current_day = 1;
            $current_month++;
            if ($current_month > 12) {
                $current_month = 1;
                $current_year++;
            }
        }
    }
    return @output_dates;
}

1;