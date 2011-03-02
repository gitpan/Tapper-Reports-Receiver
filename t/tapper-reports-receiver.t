#!/usr/bin/env perl

use strict;
use warnings;

use Class::C3;
use MRO::Compat;

use IO::Socket::INET;
use IO::Handle;


use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Reports::Receiver::Daemon;
use Tapper::Model 'model';
use File::Slurp 'slurp';
use Tapper::Config;

use Test::More;
use Test::Deep;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
construct_fixture( schema  => reportsdb_schema,  fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

$ENV{MX_DAEMON_STDOUT} ||= '/tmp/tapper_reports_receiver_daemon_test_'.(getpwuid($<) || "unknown").'-stdout.log';
$ENV{MX_DAEMON_STDERR} ||= '/tmp/tapper_reports_receiver_daemon_test_'.(getpwuid($<) || "unknown").'-stderr.log';

my $RECEIVED_RE = qr/^Tapper::Reports::Receiver\. Protocol is TAP\. Your report id: (\d+)/;

my $port = Tapper::Config->subconfig->{report_port};
my $pid = fork();
if ($pid == 0)
{
        my $EUID = `id -u`; chomp $EUID;
        my $EGID = `id -g`; chomp $EGID;
        my $receiver = Tapper::Reports::Receiver->new( );
        $receiver->run($port);
}
else
{
        sleep 3; # wait for receiver daemon to start
        my $sock = IO::Socket::INET->new( PeerAddr  => 'localhost',
                                          PeerPort  => $port,
                                          Proto     => 'tcp',
                                          ReuseAddr => 1,
                                        ) or die $!;

        is(ref($sock), 'IO::Socket::INET', "socket created");

        # ================================================== plain TAP ==========

        my $answer;
        my $taptxt = "1..2\nok 1 affe\nok 2 zomtec\n";
        eval {
                local $SIG{ALRM} = sub { die "Timeout!" };
                alarm (3);
                $answer = <$sock>;
                diag $answer;
                like ($answer, $RECEIVED_RE, "receiver api");
                my $success = $sock->print( $taptxt );
                close $sock; # must! --> triggers the daemon's post_processing hook
        };
        alarm(0);
        ok (!$@, "Read and write in time");

        sleep 2; # wait for server to update db

        if (my ($report_id) = $answer =~ $RECEIVED_RE){
                my $report = model('ReportsDB')->resultset('Report')->find($report_id);
                is(ref($report), 'Tapper::Schema::ReportsDB::Result::Report', 'Find report in db');
                like($report->tap->tap, qr($taptxt), 'Tap found in db');
        } else {
                diag ('No report ID. Can not search for report');
        }

        # # ================================================== TAP archive ==========

        
        $sock = IO::Socket::INET->new( PeerAddr  => 'localhost',
                                       PeerPort  => $port,
                                       Proto     => 'tcp',
                                       ReuseAddr => 1,
                                     ) or die $!;
        is(ref($sock), 'IO::Socket::INET', "socket created");

        $taptxt = slurp ("t/tap-archive-1.tgz");
        eval {
                local $SIG{ALRM} = sub { die "Timeout!" };
                alarm (3);
                $answer = <$sock>;
                diag $answer;
                like ($answer, $RECEIVED_RE, "receiver api");
                my $success = $sock->print( $taptxt );
                close $sock; # must! --> triggers the daemon's post_processing hook
        };
        alarm(0);
        ok (!$@, "Read and write in time");

        sleep 2; # wait for server to update db

        if (my ($report_id) = $answer =~ $RECEIVED_RE){
                my $report = model('ReportsDB')->resultset('Report')->find($report_id);
                is(ref($report), 'Tapper::Schema::ReportsDB::Result::Report', 'Find report in db');
                is($report->tap->tap_is_archive, 1, 'Tap is marked as archive in db');

                my $harness = Tapper::TAP::Harness->new( tap => $report->tap->tap, tap_is_archive => 1 );
                $harness->evaluate_report();
                is(scalar @{$harness->parsed_report->{tap_sections}}, 4, "stored TAP is an archive");
                is($harness->parsed_report->{report_meta}{'suite-name'},    'Tapper-Test',  "report meta suite name");
                is($harness->parsed_report->{report_meta}{'suite-version'}, '2.010012',      "report meta suite version");
                is($harness->parsed_report->{report_meta}{'suite-type'},    'software',      "report meta suite type");
        } else {
                diag ('No report ID. Can not search for report');
        }

        # ==================================================

        kill 15, $pid;
        sleep 3;
        kill 9, $pid;
}

ok(1);

# END {
#         $receiver->stop();
# }

done_testing();
