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

$VERSION = '0.02';

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
        (my ($vers_numeric, $vers_float, $extra) = $self->_extract_perl_version($self->{_config})) || return;
        (my $osname = $self->_extract_osname($self->{_config})) || return;
        (my $osvers = $self->_extract_osvers($self->{_config})) || return;
        (my $archname = $self->_extract_archname($self->{_config})) || return;

        $self->interpreter_vers_numeric($vers_numeric);
        $self->interpreter_vers_float($vers_float);
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

        if ($self->_is_a_perl_release($self->{_dist})) {
            $self->error('use perlbug for reporting test results against perl herself');
            return;
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
    if (@_) {
        $self->{_from} = shift;

        my $rfc2822_compliance_regex = $self->_rfc2822_compliance_regex();

        unless ($self->{_from} =~ $rfc2822_compliance_regex) {
            $self->error('invalid from; is not RFC 2822 compliant');
            return;
        }
    }
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

sub interpreter_vers_numeric {
    my $self = shift;
    $self->{_interpreter_vers_numeric} = shift if @_;
    return $self->{_interpreter_vers_numeric};
}

sub interpreter_vers_float {
    my $self = shift;
    $self->{_interpreter_vers_float} = shift if @_;
    return $self->{_interpreter_vers_float};
}

sub interpreter_vers_extra {
    my $self = shift;
    $self->{_interpreter_version_extra} = shift if @_;
    return $self->{_interpreter_version_extra};
}

sub new {
    my $type  = shift;
    my $class = ref($type) || $type;
    my $self  = {
        _archname => undef,     # architecture's name; e.g.: i686-linux-64int
        _comments => undef,     # output of failed 'make test'
        _config => undef,       # output of Config::myconfig()
        _dist => undef,         # distribution; e.g.: CPAN-Testers-Report-0.02
        _dist_name => undef,    # distribution's name; e.g. CPAN-Testers-Report
        _dist_vers => undef,    # distribution's version; e.g.: 0.02
        _from => undef,         # name & e-mail of tester: Foo Bar <foo@bar.com>
        _grade => undef,        # from 'make test'; pass, fail, unknown, or na
        _interpreter              => 'perl', # pugs? (dare I say, ponie?) ...
        _interpreter_vers_extra   => undef,  # patch 1234
        _interpreter_vers_float   => undef,  # 5.008008
        _interpreter_vers_numeric => undef,  # 5.8.8
        _osname => undef,       # operating system name
        _osvers => undef,       # operating system version; e.g.: 2.6.22-1-k7
        _report_vers => 1,      # uniquely identifies this test report format
                                # XXX - ^ - THIS MUST BE INCREMENTED ANY TIME
                                # XXX - | - ANY TEST REPORT METADATA IS ALTERED
        _rfc2822_date => undef, # RFC2822-compliant date-time
        _rfc2822_compliance_regex => undef,
        _via => undef,          # caller; e.g.: CPAN, CPANPLUS, CPAN::Reporter
        __error => undef,
    };

    bless $self, $class;

    $self->rfc2822_date($self->_format_rfc2822_date());
    $self->via($self->_compute_via());
    $self->_rfc2822_compliance_regex($self->_generate_rfc2822_compliance_regex());

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

    my $version;
    {
        no strict 'refs';
        $version = ${__PACKAGE__.'::VERSION'};
    }

    if (defined $self->{_via}) {
        return __PACKAGE__ . " $version, $self->{_via}";
    }
    else {
        return __PACKAGE__ . " $version";
    }
}

sub _compute_via {
    my $self = shift;
    my $package = (caller(1))[0];
    my $version;

    {   
        no strict 'refs';
        $version = ${$package.'::VERSION'};
    }

    my $via = $package;
    $via .= " $version" if defined $version;

    return $via;
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

# Derived from Email::Address by Casey West and Ricardo SIGNES
sub _generate_rfc2822_compliance_regex {
    my $self                 = shift;
    my $COMMENT_NEST_LEVEL   = 2;
    my $CTL                  = q{\x00-\x1F\x7F};
    my $special              = q{()<>\\[\\]:;@\\\\,."};
    my $text                 = qr/[^\x0A\x0D]/;
    my $quoted_pair          = qr/\\$text/;
    my $ctext                = qr/(?>[^()\\]+)/;
    my ($ccontent, $comment) = (q{})x2;

    for (1 .. $COMMENT_NEST_LEVEL) {
        $ccontent = qr/$ctext|$quoted_pair|$comment/;
        $comment  = qr/\s*\((?:\s*$ccontent)*\s*\)\s*/;
    }

    my $cfws           = qr/$comment|\s+/;
    my $atext          = qq/[^$CTL$special\\s]/;
    my $atom           = qr/$cfws*$atext+$cfws*/;
    my $dot_atom_text  = qr/$atext+(?:\.$atext+)*/;
    my $dot_atom       = qr/$cfws*$dot_atom_text$cfws*/;
    my $qtext          = qr/[^\\"]/;
    my $qcontent       = qr/$qtext|$quoted_pair/;
    my $quoted_string  = qr/$cfws*"$qcontent+"$cfws*/;
    my $word           = qr/$atom|$quoted_string/;
    my $simple_word    = qr/$atom|\.|\s*"$qcontent+"\s*/;
    my $obs_phrase     = qr/$simple_word+/;
    my $phrase         = qr/$obs_phrase|(?:$word+)/;
    my $local_part     = qr/$dot_atom|$quoted_string/;
    my $dtext          = qr/[^\[\]\\]/;
    my $dcontent       = qr/$dtext|$quoted_pair/;
    my $domain_literal = qr/$cfws*\[(?:\s*$dcontent)*\s*\]$cfws*/;
    my $domain         = qr/$dot_atom|$domain_literal/;
    my $display_name   = $phrase;
    my $addr_spec      = qr/$local_part\@$domain/;
    my $angle_addr     = qr/$cfws*<$addr_spec>$cfws*/;
    my $name_addr      = qr/$display_name?$angle_addr/;
    my $mailbox        = qr/(?:$name_addr|$addr_spec)$comment*/;

    return $mailbox;
}

sub _is_a_perl_release {
    my ($self, $dist) = @_;
    return $dist =~ /^perl-?\d\.\d/;
}

sub _rfc2822_compliance_regex {
    my $self = shift;
    $self->{_rfc2822_compliance_regex} = shift if @_;
    return $self->{_rfc2822_compliance_regex};
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
  $test_report->from('Adam J. Foxson <afoxson@pobox.com>') || die $test_report->error();
  $test_report->grade('pass') || die $test_report->error();

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
failed. Attempts to call this method with anything resembling a distribution
of perl itself will not be honored (use perlbug).

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
<afoxson@pobox.com>'. Optional, but if specified it must be RFC 2822
compliant. If you ever need to parse this out to separate the name from the
e-mail address, visit Email::Address. If this method returns undef, it failed
(i.e., what you specified was not RFC 2822 compliant).

=item * B<grade>

Grade for the result of 'make test'. Must be pass, fail, na, or unknown.
'Pass' indicates that all tests passed. 'Fail' indicates one or more tests
failed. 'Na' indicates that the distribution will not work on this platform.
'Unknown' indicates that the distribution did not include tests. Mandatory.
If this method returns undef, it failed.

=item * B<interpreter>

At the moment always returns 'perl'.

=item * B<interpreter_vers_numeric>

Automatically calculated but can be overriden. This represents the
interpreter's version. For example in the format of '5.8.8'.

=item * B<interpreter_vers_float>

Automatically calculated but can be overriden. This represents the
interpreter's version. For example in the format of '5.008008'.

=item * B<interpreter_vers_extra>

Automatically calculated but can be overriden. This usually represents the
interpreter's patch/patchlevel, if available. For example 'patchlevel 12345'.

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

Automatically calculated (based on the caller) but can be overriden. This
represents the automation wrapping CPAN::Testers::Report. This is usually
something like CPAN::Reporter, CPAN::YACSmoke.

=back

=head1 TODO

Please excuse me for a few moments while I think aloud publically. :-)

=over 4

=item * Add tests for error conditions

At a minimum:

=over 4

=item * dist()

=item * from()

=item * grade()

=item * config()

=back

=item * Add a validate() method to ensure overall consistency?

This is not intended to indicate suitablity for any particular transport. This
is more about verifying that the object contains the minimum necessary data
and in a correct form to even be considered a valid test report. A transport
could call this as a sanity check before attempting delivery.

=over 4

=item * a distribution that is parseable into its name and version components

=item * a config that is parseable into its archname, osvers, and perl version components

=item * a from, if specified, must be RFC 2822 compliant

=item * a grade that is one of 'pass', 'fail', 'na', or 'unknown'

=back

=item * Decide what to do about "interpreter"

The idea behind this is that CPAN modules might theoretically be able to be
run under interpreters other than perl itself. Therefore, it might be a
potentially valueable endeavor to test this. For example, in the past, ponie
would have been an example of where this might have occurred. Nowadays, would
pugs perhaps be a current example?

The question is whether or not we want to actually accomodate for this
possibility. Or to restate, do we want to have support for testing CPAN
distributions with interpreters that are "perl-like"?

=item * Shall the metadata be handled specially (from/date/via) ?

These are all three bits of data that are arguably part of a test-report, but
a test-report can be fully 100% valid in all of their absence. As such, I'm
wondering if we want to handle these differently/specially. Food for thought!

=item * RFC 2822 compliance regex shouldn't be assembled on a per object basis

This is inefficient and needs to be addressed.

=item * Hmm. What to do about the subject...

Doesn't really belong in this module (because the concept of 'Subject' is
specfic only to a particular class of transport), but we don't want each e-mail
based transport reimplementing this functionality or duplicating code. And, we
need the flexibility to change it in the future without major disruption. So
then, what we might want to do is create a new distribution that provides
methods to do both parsing and generating of subjects, once passed a
previously generated subject or CPAN::Testers::Report object.

=item * Hmm. What to do about the "stringified formatted report"...

Almost 3am! Time for bed... More to come tomorrow...

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
