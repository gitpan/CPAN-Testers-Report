# CPAN::Testers::Report - Creates CPAN Testers test-report objects
# Copyright (c) 2007 Adam J. Foxson and the CPAN Testers. All rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

package CPAN::Testers::Report;

use strict;
use vars qw($VERSION $__ERRSTR $__RFC2822_RE $__CONFIG_RE);
use Config;
use Time::Local ();

local $^W = 1;

$VERSION = '0.03';

__PACKAGE__->_rfc2822_compliance_regex(__PACKAGE__->_generate_rfc2822_compliance_regex());
__PACKAGE__->_configuration_regex(__PACKAGE__->_generate_configuration_regex());

sub comments {
    my $self = shift;
    $self->{_comments} = shift if @_;
    return $self->{_comments};
}

sub config {
    my $self = shift;

    if (@_) {
        my $key = shift;
        return $self->{_config}->{$key};
    }
    else {
        return sort keys %{$self->{_config}};
    }
}

sub dist {
    my $self = shift;

    if (@_) {
        $self->{_dist} = shift;

        unless (defined $self->{_dist}) {
            $self->errstr('distribution not specified');
            return;
        }

        my ($dist, $version, $beta) = $self->_distname_info($self->{_dist});

        $self->dist_name($dist);

        if (defined $version) {
            $self->dist_vers($version);
        }
        else {
            $self->errstr("unable to determine distribution version for '$self->{_dist}'");
            return;
        }

        if ($self->_is_a_perl_release($self->{_dist})) {
            $self->errstr('use perlbug for reporting test results against perl herself');
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

sub errstr {
    my $self = shift;

    if (ref $self) {
        $self->{__errstr} = shift if @_;
        return $self->{__errstr};
    }
    else {
        $__ERRSTR = shift if @_;
        return $__ERRSTR;
    }
}

sub from {
    my $self = shift;
    if (@_) {
        $self->{_from} = shift;
        $self->_check_from() || return;
    }
    return $self->{_from};
}

sub grade {
    my $self = shift;
    if (@_) {
        $self->{_grade} = shift;
        $self->{_grade} = uc $self->{_grade} if defined $self->{_grade};
        $self->_check_grade() || return;
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
        _comments => undef,     # output of failed 'make test'
        _config => {},          # container for local perl configuration
        _dist => undef,         # distribution; e.g.: CPAN-Testers-Report-0.03
        _dist_name => undef,    # distribution's name; e.g. CPAN-Testers-Report
        _dist_vers => undef,    # distribution's version; e.g.: 0.03
        _from => undef,         # name & e-mail of tester: Foo Bar <foo@bar.com>
        _grade => undef,        # from 'make test'; pass, fail, unknown, or na
        _interpreter              => 'perl', # pugs? (dare I say, ponie?) ...
        _interpreter_vers_extra   => undef,  # patch 1234
        _interpreter_vers_float   => undef,  # 5.008008
        _interpreter_vers_numeric => undef,  # 5.8.8
        _report_vers => 1,      # uniquely identifies this test report format
                                # XXX - ^ - THIS MUST BE INCREMENTED ANY TIME
                                # XXX - | - ANY TEST REPORT METADATA IS ALTERED
        _rfc2822_date => undef, # RFC2822-compliant date-time
        _via => undef,          # caller; e.g.: CPAN, CPANPLUS, CPAN::Reporter
        __errstr => undef,
    };

    bless $self, $class;

    $self->_init($class) || return;

    return $self;
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

sub validate {
    my $self = shift;

    $self->_check_grade() || return;
    $self->_check_from || return;

    unless (defined $self->dist()) {
        $self->errstr('distribution not specified');
        return;
    };

    unless (defined $self->dist_vers()) {
        $self->errstr("unable to determine distribution version for '${\($self->dist())}'");
        return;
    };

    if ($self->_is_a_perl_release($self->dist())) {
        $self->errstr('use perlbug for reporting test results against perl herself');
        return;
    }

    return 1;
}

sub via {
    my $self = shift;

    if (@_) {
        my $version;
        {
            no strict 'refs';
            $version = ${__PACKAGE__.'::VERSION'};
        }

        my $additional = shift;
        $self->{_via} = __PACKAGE__ . " $version, $additional";
    }

    return $self->{_via};
}

sub _check_from {
    my $self = shift;
    my $from = $self->from();
    my $rfc2822_compliance_regex = $self->_rfc2822_compliance_regex();

    unless (defined $from) {
        $self->errstr('from not specified');
        return;
    }

    unless ($from =~ $rfc2822_compliance_regex) {
        $self->errstr('invalid from; is not RFC 2822 compliant');
        return;
    }

    return $from;
}

sub _check_grade {
    my $self = shift;
    my $grade = $self->grade();

    unless (defined $grade) {
        $self->errstr('grade not specified');
        return;
    }

    unless ($grade =~ /^(PASS|FAIL|UNKNOWN|NA)$/i) {
        $self->errstr('invalid grade; choose: pass, fail, unknown, na');
        return;
    }

    return $grade;
}

sub _compute_via {
    my $self = shift;
    my $package = (caller(2))[0];
    my $version;

    {   
        no strict 'refs';
        $version = ${$package.'::VERSION'};
    }

    my $via = $package;
    $via .= " $version" if defined $version;

    return $via;
}

sub _configuration_regex {
    my $self = shift;
    no strict 'refs';
    ${__PACKAGE__.'::__CONFIG_RE'} = shift if @_;
    return ${__PACKAGE__.'::__CONFIG_RE'};
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

# Derived from CPAN::WWW::Testers::Generator::Article by Leon Brocard
# In the future, we may want to investigate alternate methods by
# which to collect this data without needing to parse myconfig()
sub _extract_perl_version {
    my $self = shift;
    my $config = Config::myconfig();
    my ($rev, $ver, $sub, $extra) = $config =~ /
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
        $self->errstr('unable to determine perl version');
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

sub _generate_configuration_regex {
    my $self = shift;
    my $config_keys_regex = join '|', keys %Config;

    return qr/($config_keys_regex)\s?=/;
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

sub _init {
    my ($self, $class) = @_;

    (my ($vers_numeric, $vers_float, $extra) = $self->_extract_perl_version()) || do {
        $class->errstr($self->errstr);
        return;
    };

    $self->interpreter_vers_numeric($vers_numeric);
    $self->interpreter_vers_float($vers_float);
    $self->interpreter_vers_extra($extra);
    $self->rfc2822_date($self->_format_rfc2822_date());
    $self->via($self->_compute_via());

    my $configuration_regex = $class->_configuration_regex();
    my @major_config_keys = Config::myconfig() =~ /$configuration_regex/g;
    my %major_config;

    for my $major_config_key (@major_config_keys) {
        if (defined $Config{$major_config_key}) {
            $major_config{$major_config_key} = $Config{$major_config_key};
        }
        else {
            $major_config{$major_config_key} = undef;
        }
    }

    $self->{_config} = \%major_config;
}

sub _is_a_perl_release {
    my ($self, $dist) = @_;
    return $dist =~ /^perl-?\d\.\d/;
}

sub _rfc2822_compliance_regex {
    my $self = shift;
    no strict 'refs';
    ${__PACKAGE__.'::__RFC2822_RE'} = shift if @_;
    return ${__PACKAGE__.'::__RFC2822_RE'};
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

  my $test_report = CPAN::Testers::Report->new() || die CPAN::Testers::Report->errstr();
  $test_report->comments('...This is a computer-generated test report...');
  $test_report->dist('Test-Reporter-1.34') || die $test_report->errstr();
  $test_report->from('Adam J. Foxson <afoxson@pobox.com>') || die $test_report->errstr();
  $test_report->grade('pass') || die $test_report->errstr();

=head1 DESCRIPTION

Welcome to CPAN::Testers::Report. This is the first distribution in the
CPAN::Testers namespace. This module is designed to be part of the
next-generation implementation of the CPAN Tester's stack. When complete,
this distribution and its constituents will obsolete Test::Reporter.

This module provides an abstraction for test reports. An object of this type
will encapsulate all data and information about a single, specific test report.
This object can then be submitted to a user's transport of choice for delivery.

This is a developer's release. The interface is not stable; The API may change
at any time without notice. This module is not yet recommended for general use.

=head1 SERIALIZATION

These objects are generated specifically with serialization in mind.

Below, please find a sample test report in YAML:

 --- !!perl/hash:CPAN::Testers::Report
 __errstr: ~
 _comments: |
  Dear Adam J. Foxson,
      
  This is a computer-generated report for CPAN-Testers-Report-0.03
  on perl-5.8.8, created automatically by CPAN-Reporter-0.99_15 and sent 
  to the CPAN Testers mailing list.  
  
  If you have received this email directly, it is because the person testing 
  your distribution chose to send a copy to your CPAN email address; there 
  may be a delay before the official report is received and processed 
  by CPAN Testers.
  
  Thank you for uploading your work to CPAN.  Congratulations!
  All tests were successful.
  
  <snip!>
 _config:
  alignbytes: 8
  archname: darwin-2level
  byteorder: 1234
  cc: /usr/bin/gcc-4.0
  cccdlflags: ' '
  ccdlflags: ' '
  ccflags: -I/opt/local/include -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -pipe -Wdeclaration-after-statement -I/opt/local/include
  ccversion: ''
  config_args: -des -Dprefix=/opt/local -Dccflags=-I'/opt/local/include' -Dldflags=-L/opt/local/lib -Dvendorprefix=/opt/local -Dcc=/usr/bin/gcc-4.0
  cppflags: -no-cpp-precomp -I/opt/local/include -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -pipe -Wdeclaration-after-statement -I/opt/local/include
  d_dlsymun: ~
  d_longdbl: define
  d_longlong: define
  d_sfio: ~
  d_sigaction: define
  dlext: bundle
  dlsrc: dl_dlopen.xs
  doublesize: 8
  gccosandvers: ''
  gccversion: '4.0.1 (Apple Computer, Inc. build 5367)'
  gnulibc_version: ''
  hint: recommended
  intsize: 4
  ivsize: 4
  ivtype: long
  ld: env MACOSX_DEPLOYMENT_TARGET=10.3 cc
  lddlflags: -L/opt/local/lib -bundle -undefined dynamic_lookup
  ldflags: -L/opt/local/lib
  libc: /usr/lib/libc.dylib
  libperl: libperl.a
  libpth: /opt/local/lib /usr/lib
  libs: -ldbm -ldl -lm -lc
  longdblsize: 16
  longlongsize: 8
  longsize: 4
  lseeksize: 8
  nvsize: 8
  nvtype: double
  optimize: -O3
  osname: darwin
  osvers: 8.10.1
  perllibs: -ldl -lm -lc
  prefix: /opt/local
  prototype: define
  ptrsize: 4
  so: dylib
  uname: uname
  use5005threads: ~
  use64bitall: ~
  use64bitint: ~
  useithreads: ~
  uselargefiles: define
  uselongdouble: ~
  usemultiplicity: ~
  usemymalloc: n
  useperlio: define
  useposix: true
  useshrplib: false
  usesocks: ~
  usethreads: ~
  vendorprefix: /opt/local
 _dist: CPAN-Testers-Report-0.03
 _dist_name: CPAN-Testers-Report
 _dist_vers: 0.03
 _from: 'Adam J. Foxson <afoxson@pobox.com>'
 _grade: PASS
 _interpreter: perl
 _interpreter_vers_extra: ~
 _interpreter_vers_float: 5.008008
 _interpreter_vers_numeric: 5.8.8
 _interpreter_version_extra: ''
 _report_vers: 1
 _rfc2822_date: 'Wed, 3 Oct 2007 23:30:13 -0400'
 _via: 'CPAN::Testers::Report 0.03, CPAN::Reporter 0.99_15'

=head1 METHODS

=over 4

=item * B<comments>

User-specified comments to include with the test report. This is oftentimes
the output of a failed 'make test'. Optional.

=item * B<config>

Without an argument returns a list of all of the major configuration items
(osname, osvers, archname, byteorder, cc, libs, et al...) If given an argument
will return the value associated with one of those configuration items

=item * B<dist>

Full distribution name and version of which this test report is about. For
example 'Test-Reporter-1.34'. Mandatory. If this method returns undef, it
failed. Attempts to call this method with anything resembling a distribution
of perl itself will not be honored (use perlbug).

=item * B<dist_name>

Automatically calculated but can be overridden. This represents the
distribution's name only. For example 'Test-Reporter'.

=item * B<dist_vers>

Automatically calculated but can be overridden. This represents the
distribution's version only. For example '1.34'.

=item * B<errstr>

Returns the error message from the last error that occurred.

=item * B<from>

Name and e-mail address of the tester. For example 'Adam J. Foxson
<afoxson@pobox.com>'. Mandatory, and must be RFC 2822 compliant. Name may be
omitted. If you ever need to parse this out to separate the name from the
e-mail address, visit Email::Address. If this method returns undef, it failed
(i.e., what was specified was not RFC 2822 compliant). This is metadata.

=item * B<grade>

Grade for the result of 'make test'. Must be pass, fail, na, or unknown.
'Pass' indicates that all tests passed. 'Fail' indicates one or more tests
failed. 'Na' indicates that the distribution will not work on this platform.
'Unknown' indicates that the distribution did not include tests. Mandatory.
If this method returns undef, it failed.

=item * B<interpreter>

At the moment always returns 'perl' but can be overridden.

=item * B<interpreter_vers_numeric>

Automatically calculated but can be overridden. This represents the
interpreter's version. For example in the format of '5.8.8'.

=item * B<interpreter_vers_float>

Automatically calculated but can be overridden. This represents the
interpreter's version. For example in the format of '5.008008'.

=item * B<interpreter_vers_extra>

Automatically calculated but can be overridden. This usually represents the
interpreter's patch/patchlevel, if available. For example 'patchlevel 12345'.

=item * B<new>

Constructor. Accepts no arguments at this time. If this method returns undef,
it failed.

=item * B<report_vers>

Revision of the internal test report object format.

=item * B<rfc2822_date>

Automatically calculated but can be overridden. This is the RFC2822-compliant
datetime. This is metadata.

=item * B<validate>

Accepts no arguments. Returns true if the object represents a valid test
report. Returns false and sets errstr() if the object does not represent a
valid test report. The ensures that that distribution specified is parseable
into its name/version constituents, that the grade is one of 'pass', 'fail',
'na', or 'unknown', and that from is present and RFC 2822 compliant

=item * B<via>

Automatically calculated (based on the caller) but can be overridden. This
represents the automation wrapping CPAN::Testers::Report. This is usually
something like CPAN::Reporter, CPAN::YACSmoke. This is metadata.

=back

=head1 TODO

=over 4

=item * Decide what to do about "interpreter"

The idea behind this is that CPAN modules might theoretically be able to be
run under interpreters other than perl itself. Therefore, it might be a
potentially valueable endeavor to test this. For example, in the past, ponie
would have been an example of where this might have occurred. Nowadays, would
pugs perhaps be a current example?

The question is whether or not we want to actually accomodate for this
possibility. Or to restate, do we want to have support for testing CPAN
distributions with interpreters that are "perl-like"?

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
