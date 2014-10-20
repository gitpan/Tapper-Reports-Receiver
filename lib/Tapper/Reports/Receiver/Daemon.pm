package Tapper::Reports::Receiver::Daemon;
BEGIN {
  $Tapper::Reports::Receiver::Daemon::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::Reports::Receiver::Daemon::VERSION = '4.1.0';
}

use 5.010;

use strict;
use warnings;

use Tapper::Config;
use Tapper::Reports::Receiver;
use Log::Log4perl;
use Moose;

with 'MooseX::Daemonize';

after start => sub {
                    my $self = shift;

                    return unless $self->is_daemon;



                    my $logconf = Tapper::Config->subconfig->{files}{log4perl_cfg};
                    Log::Log4perl->init($logconf);

                    my $port = Tapper::Config->subconfig->{report_port};
                    Tapper::Reports::Receiver->new()->run($port);
};



sub run
{
        my ($self) = @_;
        my ($command) = @ARGV;
        return unless $command && grep /^$command$/, qw(start status restart stop);
        $self->$command;
        say $self->status_message;
}


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::Reports::Receiver::Daemon

=head2 run

Run daemon.

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

