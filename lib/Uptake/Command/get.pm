# ABSTRACT: Download kernels on kernel.ubuntu.com/~kernel-ppa/mainline/.
package Uptake::Command::get;
use Uptake -command;

use autodie;
use strict;
use warnings;
use feature qw(say);

use Carp;
use File::chdir;
use List::Util qw(none);
use Mojo::UserAgent;

use Class::Tiny {
    ua => Mojo::UserAgent->new,
    url => 'http://kernel.ubuntu.com/~kernel-ppa/mainline/',
    path => "$ENV{HOME}/.cache/kernels",
};

$ENV{MOJO_MAX_MESSAGE_SIZE} = 0;

sub execute {
    my ($self, $opt, $args) = @_;

    $self->{path} = delete $opt->{dir} if $opt->dir;
    mkdir $self->path unless -d $self->path;

    @ARGV = @$args == 0 ? () : @$args;

    local $CWD = $self->path;
    while (<>) {
        chomp;
        mkdir $_ unless -d $_;
        local $CWD = $_;

        $self->_download({
                url => $self->url . $_ . '/',
                no => $opt->{no},
                suffix => '[.]deb$',
            })
    }
};

sub opt_spec {
    return (
        [ 'dir=s', 'download directory.' ],
        [ 'no=s@', 'file name will exclude the specified word.' ],
    );
}

sub _download {
    my ($self, $args) = @_;
    exists $args->{url} && 
    exists $args->{suffix} or confess;

    my @debs;
    $self->ua->get(
        $args->{url} => {DNT => 1})->res->dom('tr > td > a')->each(sub {
            push @debs, $_->text if $_->text =~ /$args->{suffix}/;
        });

    @debs = grep {
        my $deb = $_;
        none { $deb =~ /$_/ } @{$args->{no}};
    } @debs if exists $args->{no};

    for (@debs) {
        say 'Downloading ' . $_;
        $self->ua->get($args->{url} . $_)
        ->res->content->asset->move_to($CWD . '/' . $_);
    }
}

1;
