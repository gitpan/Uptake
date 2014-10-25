# ABSTRACT: List kernels on kernel.ubuntu.com/~kernel-ppa/mainline/.
package Uptake::Command::list;
use Uptake -command;

use autodie;
use strict;
use warnings;
use feature qw(say);

use Carp;
use List::Util qw(none);
use Mojo::UserAgent;

use Class::Tiny {
    ua => Mojo::UserAgent->new,
    url => 'http://kernel.ubuntu.com/~kernel-ppa/mainline/',
    exclude => [
        'Parent Directory',
        'daily',
        'testing',
        'fixes',
        'next',
        'nightly',
        'queue',
        'review',
    ],
};

sub execute {
    my ($self, $opt, $args) = @_;

    my $regex = delete $opt->{regex};

    if (my $no = delete $opt->{no}) {
        push @{$self->exclude}, $_ for @$no;
    }

    my @versions;
    $self->ua->get(
        $self->url => {DNT => 1})->res->dom('tr > td > a')->each(sub {
            push @versions, $_->text;
        });

    @versions =
    map { s/\///r }
    grep {
        my $val = $_;
        none { $val =~ /$_/ } @{$self->exclude} } @versions;

    @versions = grep { /$regex/ } @versions if $regex;

    say for @versions;
}

sub opt_spec {
    return (
        [ 'no=s@', 'exclude the specified word.' ],
        [ 'regex=s', 'kernel name will match the regex.' ],
    );
}

1;
