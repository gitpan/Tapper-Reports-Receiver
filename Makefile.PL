
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - Receiver for Tapper test reports as TAP or TAP::Archive",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Class::C3" => 0,
    "DateTime::Format::Mail" => 0,
    "File::Slurp" => 0,
    "HTTP::Daemon" => 0,
    "IO::Socket::INET" => 0,
    "MRO::Compat" => 0,
    "Tapper::Schema::TestTools" => 0,
    "Test::Deep" => 0,
    "Test::Fixture::DBIC::Schema" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-Reports-Receiver",
  "EXE_FILES" => [
    "bin/tapper-reports-receiver",
    "bin/tapper-reports-receiver-daemon"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::Reports::Receiver",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::Handle" => 0,
    "AnyEvent::Socket" => 0,
    "App::Daemon" => 0,
    "Data::DPath" => 0,
    "Data::Dumper" => 0,
    "DateTime::Format::Natural" => 0,
    "Devel::Backtrace" => 0,
    "File::MimeInfo::Magic" => 0,
    "IO::Handle" => 0,
    "IO::Scalar" => 0,
    "LWP::UserAgent" => 0,
    "LockFile::Simple" => "0.208",
    "Log::Log4perl" => 0,
    "Module::Find" => "0.11",
    "Moose" => 0,
    "MooseX::Log::Log4perl" => 0,
    "Scalar::Util" => 0,
    "Tapper::Base" => 0,
    "Tapper::Config" => 0,
    "Tapper::Model" => 0,
    "Tapper::TAP::Harness" => 0,
    "YAML::Syck" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.0.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



