# CPAN::Testers::Report - Creates CPAN Testers test-report objects
# Copyright (c) 2007 Adam J. Foxson and the CPAN Testers. All rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

package CPAN::Testers::Report;

use strict;
use vars qw($VERSION);
use Time::Local ();

$VERSION = '0.01';

local $^W = 1;

sub archname {
    my $self = shift;
    $self->{_archname} = shift if @_;
    return $self->{_archname};
}

sub comments {
    my $self = shift;
    $self->{_comments} = shift if @_;
    return $self->{_comments};
}

sub config {
    my $self = shift;
    if (@_) {
        $self->{_config} = \shift;
        (my ($version1, $version2, $extra) = $self->_extract_perl_version($self->{_config})) || return;
        (my $osname = $self->_extract_osname($self->{_config})) || return;
        (my $osvers = $self->_extract_osvers($self->{_config})) || return;
        (my $archname = $self->_extract_archname($self->{_config})) || return;

        $self->interpreter_vers1($version1);
        $self->interpreter_vers2($version2);
        $self->interpreter_vers_extra($extra);
        $self->osname($osname);
        $self->osvers($osvers);
        $self->archname($archname);
    }
    return $self->{_config};
}

sub dist {
    my $self = shift;

    if (@_) {
        $self->{_dist} = shift;
        my ($dist, $version, $beta) = $self->_distname_info($self->{_dist});

        if (defined $dist) {
            $self->dist_name($dist);
        }
        else {
            $self->error("unable to determine distribution name for '$self->{_dist}'");
            return;
        }

        if (defined $version) {
            $self->dist_vers($version);
        }
        else {
            $self->error("unable to determine distribution version for '$self->{_dist}'");
            return;
        }

        if ($beta) {
            $self->maturity('developer');
        }
        else {
            $self->maturity('released');
        }
    }

    return $self->{_dist};
}

sub dist_name {
    my $self = shift;
    $self->{_dist_name} = shift if @_;
    return $self->{_dist_name};
}

sub dist_vers {
    my $self = shift;
    $self->{_dist_vers} = shift if @_;
    return $self->{_dist_vers};
}

sub error {
    my $self = shift;
    $self->{__error} = shift if @_;
    return $self->{__error};
}

sub from {
    my $self = shift;
    $self->{_from} = shift if @_;
    return $self->{_from};
}

sub grade {
    my $self = shift;
    if (@_) {
        $self->{_grade} = shift;
        unless ($self->{_grade} =~ /^(PASS|FAIL|UNKNOWN|NA)$/i) {
            $self->error('invalid grade; choose: pass, fail, unknown, na');
            return;
        }
        $self->{_grade} = uc $self->{_grade};
    }
    return $self->{_grade};
}

sub interpreter {
    my $self = shift;
    $self->{_interpreter} = shift if @_;
    return $self->{_interpreter};
}

sub interpreter_vers1 {
    my $self = shift;
    $self->{_interpreter_version1} = shift if @_;
    return $self->{_interpreter_version1};
}

sub interpreter_vers2 {
    my $self = shift;
    $self->{_interpreter_version2} = shift if @_;
    return $self->{_interpreter_version2};
}

sub interpreter_vers_extra {
    my $self = shift;
    $self->{_interpreter_version_extra} = shift if @_;
    return $self->{_interpreter_version_extra};
}

sub maturity {
    my $self = shift;
    $self->{_maturity} = shift if @_;
    return $self->{_maturity};
}

sub new {
    my $type  = shift;
    my $class = ref($type) || $type;
    my $self  = {
        _archname => undef,     # architecture's name; e.g.: i686-linux-64int
        _interpreter            => 'perl', # pugs? (dare I say, ponie?) ...
        _interpreter_vers1      => undef,  # 5.8.8
        _interpreter_vers2      => undef,  # 5.008008
        _interpreter_vers_extra => undef,  # patch 1234
        _comments => undef,     # output of failed 'make test'
        _config => undef,       # output of Config::myconfig()
        _rfc2822_date => undef, # RFC2822-compliant date-time
        _dist => undef,         # distribution; e.g.: CPAN-Testers-Report-0.01
        _dist_name => undef,    # distribution's name; e.g. CPAN-Testers-Report
        _dist_vers => undef,    # distribution's version; e.g.: 0.01
        _grade => undef,        # from 'make test'; pass, fail, unknown, or na
        _maturity => undef,     # 'developer' or 'released'
        _osvers => undef,       # operating system version; e.g.: 2.6.22-1-k7
        _report_vers => 1,      # uniquely identifies this test report format
                                # XXX - ^ - THIS MUST BE INCREMENTED ANY TIME
                                # XXX - | - ANY TEST REPORT METADATA IS ALTERED
        _from => undef,         # name & e-mail of tester: Foo Bar <foo@bar.com>
        _via => undef,          # caller; e.g.: CPAN, CPANPLUS, CPAN::Reporter
        __error => undef,
    };

    bless $self, $class;

    $self->rfc2822_date($self->_format_rfc2822_date());

    return $self;
}

sub osname {
    my $self = shift;
    $self->{_osname} = shift if @_;
    return $self->{_osname};
}

sub osvers {
    my $self = shift;
    $self->{_osvers} = shift if @_;
    return $self->{_osvers};
}

sub report_vers {
    my $self = shift;
    return $self->{_report_vers};
}

sub rfc2822_date {
    my $self = shift;
    $self->{_rfc2822_date} = shift if @_;
    return $self->{_rfc2822_date};
}

sub via {
    my $self = shift;
    $self->{_via} = shift if @_;
    return $self->{_via};
}

# Derived from CPAN::DistnameInfo by Graham Barr
sub _distname_info {
    my $self = shift;
    my $file = shift or return;

    my ($dist, $version) = $file =~ /^
        ((?:[-+.]*(?:[A-Za-z0-9]+|(?<=\D)_|_(?=\D))*
        (?:
        [A-Za-z](?=[^A-Za-z]|$)
        |
        \d(?=-)
        )(?<![._-][vV])
        )+)(.*)
    $/xs or return ($file, undef, undef);

    if ($version =~ /^(-[Vv].*)-(\d.*)/) {
        # Catch names like Unicode-Collate-Standard-V3_1_1-0.1
        # where the V3_1_1 is part of the distname
        $dist .= $1;
        $version = $2;
    }

    $version = $1 if !length $version and $dist =~ s/-(\d+\w)$//;
    $version = $1 . $version if $version =~ /^\d+$/ and $dist =~ s/-(\w+)$//;

    if ($version =~ /\d\.\d/) {
        $version =~ s/^[-_.]+//;
    }
    else {
        $version =~ s/^[-_]+//;
    }

    my $dev;
    if (length $version) {
        if ($file =~ /^perl-?\d+\.(\d+)(?:\D(\d+))?(-(?:TRIAL|RC)\d+)?$/) {
            $dev = 1 if (($1 > 6 and $1 & 1) or ($2 and $2 >= 50)) or $3;
        }
        elsif ($version =~ /\d\D\d+_\d/) {
            $dev = 1;
        }
    }
    else {
        $version = undef;
    }

    ($dist, $version, $dev);
}

# perl -V:archname
# Derived from CPAN::WWW::Testers::Generator::Article by Leon Brocard
sub _extract_archname {
    my $self = shift;
    my $config = $self->config();
    my ($archname) = $$config =~ /archname=([^ ,]+)/m;

    if (defined $archname) {
        $archname =~ s/\n//;
    }
    else {
        $self->error('unable to determine archname');
    }

    return $archname;
}

# perl -V:osname
# Derived from CPAN::WWW::Testers::Generator::Article by Leon Brocard
sub _extract_osname {
    my $self = shift;
    my $config = $self->config();
    my ($osname) = $$config =~ /osname=(?:3D)?([^ ,]+)/;

    unless (defined $osname) {
        $self->error('unable to determine osname');
    }

    return $osname;
}

# perl -V:osvers
# Derived from CPAN::WWW::Testers::Generator::Article by Leon Brocard
sub _extract_osvers {
    my $self = shift;
    my $config = $self->config();
    my ($osvers) = $$config =~ /osvers=([^ ,]+)/;

    unless (defined $osvers) {
        $self->error('unable to determine osvers');
    }

    return $osvers;
}

# Derived from CPAN::WWW::Testers::Generator::Article by Leon Brocard
sub _extract_perl_version {
    my $self = shift;
    my $config = $self->config();
    my ($rev, $ver, $sub, $extra) = $$config =~ /
        Summary\sof\smy\s(?:perl\d+)?\s    # Summary of my perl5
        \(                                 # (
        (?:revision\s)?(\d+(?:\.\d+)?)\s   # revision 5
        (?:version|patchlevel)\s(\d+)\s    # version 9
        subversion\s+(\d+)\s               # subversion 2
        ?(.*?)                             # patch 22511
        \)\s                               # )
        configuration                      # configuration
    /xs;
  
    unless (defined $rev) {
        $self->error('unable to determine perl version');
        return;
    }

    my $perl = $rev + ($ver / 1000) + ($sub / 1000000);
    $rev = int($perl);
    $ver = int(($perl * 1000) % 1000);
    $sub = int(($perl * 1000000) % 1000);

    my $version = sprintf "%d.%d.%d", $rev, $ver, $sub;
    return ($version, (sprintf "%0.6f", $perl), $extra);
}

# Derived from Email::Date by Casey West and Ricardo SIGNES
sub _format_rfc2822_date {
    my $self   = shift;
    my ($time) = @_;
    $time      = time unless defined $time;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = (localtime $time);
    my $day   = (qw[Sun Mon Tue Wed Thu Fri Sat])[$wday];
    my $month = (qw[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec])[$mon];
    $year += 1900;
    my ($direc, $tz_hr, $tz_mi) = $self->_tz_diff($time);

    sprintf "%s, %d %s %d %02d:%02d:%02d %s%02d%02d",
      $day, $mday, $month, $year, $hour, $min, $sec, $direc, $tz_hr, $tz_mi;
}

# Derived from Email::Date by Casey West and Ricardo SIGNES
sub _tz_diff {
    my $self   = shift;
    my ($time) = @_;
    my $diff   = Time::Local::timegm(localtime $time) - Time::Local::timegm(gmtime $time);

    my $direc = $diff < 0 ? '-' : '+';
       $diff  = abs $diff;
    my $tz_hr = int( $diff / 3600 );
    my $tz_mi = int( $diff / 60 - $tz_hr * 60 );

    return ($direc, $tz_hr, $tz_mi);
}

=head1 NAME

CPAN::Testers::Report - Creates CPAN Testers test-report objects

=head1 SYNOPSIS

  use CPAN::Testers::Report;
  use Config;

  my $test_report = CPAN::Testers::Report->new();
  $test_report->comments('Rejoice!');
  $test_report->config(Config::myconfig()) || die $test_report->error();
  $test_report->dist('Test-Reporter-1.34') || die $test_report->error();
  $test_report->grade('pass') || die $test_report->error();
  $test_report->from('Adam J. Foxson <afoxson@pobox.com>');

=head1 DESCRIPTION

Welcome to CPAN::Testers::Report. This is the first distribution in the
CPAN::Testers namespace. This module is designed to be part of the
next-generation implementation of the CPAN Tester's stack. When complete,
this distribution and its constituents will obsolete Test::Reporter.

This module provides an abstraction for test reports. Objects will encapsulate
all data and information about a single, specific test report. These objects
can then be submitted to a user's transport of choice for delivery.

This is a developer's release. The interface is not stable; The API may change
at any time without notice. This module is not yet recommended for general use.

=head1 METHODS

=over 4

=item * B<archname>

Automatically calculated but can be overriden. This is a short name to
characterize the current architecture.

=item * B<comments>

User-specified comments to include with the test report. This is oftentimes
the output of a failed 'make test'. Optional.

=item * B<config>

This method should be the recipient of Config::myconfig(). Mandatory. If this
method returns undef, it failed.

=item * B<dist>

Full distribution name and version of which this test report is about. For
example 'Test-Reporter-1.34'. Mandatory. If this methods returns undef, it
failed.

=item * B<dist_name>

Automatically calculated but can be overriden. This represents the
distribution's name only. For example 'Test-Reporter'.

=item * B<dist_vers>

Automatically calculated but can be overriden. This represents the
distribution's version only. For example '1.34'.

=item * B<error>

Returns an error message when an error has occurred.

=item * B<from>

Name and e-mail address of the tester. For example 'Adam J. Foxson
<afoxson@pobox.com>'. Optional at the moment, but should probably be
mandatory, and possibly even rfc2822-compliant.

=item * B<grade>

Grade for the result of 'make test'. Must be pass, fail, na, or unknown.
'Pass' indicates that all tests passed. 'Fail' indicates one or more tests
failed. 'Na' indicates that the distribution will not work on this platform.
'Unknown' indicates that the distribution did not include tests. Mandatory.
If this method returns undef, it failed.

=item * B<interpreter>

At the moment always returns 'perl'.

=item * B<interpreter_vers1>

Automatically calculated but can be overriden. This represents the
interpreter's version. For example in the format of '5.8.8'. I need to find a
better name for this method.

=item * B<interpreter_vers2>

Automatically calculated but can be overriden. This represents the
interpreter's version. For example in the format of '5.008008'. I need to find
a better name for this method.

=item * B<interpreter_vers_extra>

Automatically calculated but can be overriden. This usually represents the
interpreter's patch/patchlevel, if available. For example 'patchlevel 12345'.

=item * B<maturity>

Automatically calculated but can be overriden. This represents the maturity of
the distribution as determined by a heuristic. Will be one of 'released' or
'developer'. I'm not entirely convinced this method should be exposed.

=item * B<new>

Constructor. Accepts no arguments at this time.

=item * B<osname>

Automatically calculated but can be overriden. This is the operating system
name.

=item * B<osvers>

Automatically calculated but can be overriden. This is the operating system
version.

=item * B<report_vers>

Revision of the internal test report object format.

=item * B<rfc2822_date>

Automatically calculated but can be overriden. This is the RFC2822-compliant
datetime.

=item * B<via>

The automation wrapping CPAN::Testers::Report. This is usually something like
CPAN::Reporter, CPAN::YACSmoke. Optional. Not automatically calculated at the
moment, but will be in short-order.

=back

=head1 TODO

=over 4

=item * Make via() work automatically

=item * Do validation on from() ?

=item * Come up with better names for interpreter_vers1 and 2

=item * Improve upon and add more tests

=item * Add tests for error conditions

=item * Enforce rfc2822 semantics on from() ?

=item * Add a validate() method to ensure overall consistency?

=item * Decide what to do about "interpreter"

=item * Not sure I like from(). Separate name and e-mail?

=item * Hmm. What to do about the subject.....

=item * Make sure via() includes self!

=item * Hm. It's 2am, I'll surely think up more tomorrow!

=back

=head1 COPYRIGHT

Copyright (c) 2007 Adam J. Foxson and the CPAN Testers. All rights reserved.

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<perl>

=item * L<CPAN::Testers>

=back

=head1 AUTHOR

Adam J. Foxson E<lt>F<afoxson@pobox.com>E<gt>

With many thanks to:

=over 4

=item * Richard Soderberg E<lt>F<rsod@cpan.org>E<gt>

=item * Kirrily "Skud" Robert E<lt>F<skud@cpan.org>E<gt>

=item * Kurt Starsinic E<lt>F<Kurt.Starsinic@isinet.com>E<gt>

=item * Barbie E<lt>F<barbie@missbarbell.co.uk>E<gt>

=item * David Golden E<lt>F<dagolden@cpan.org>E<gt>

=back

=cut

1;
