# CPAN::Testers::Report - Creates CPAN Testers test-report objects
#
# Copyright (C) 2007, 2008 Adam J. Foxson and the CPAN Testers.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

package CPAN::Testers::Report;

use strict;
use vars qw($VERSION $__ERRSTR %__ERRSTRS $__RFC2822_RE $__CONFIG_RE);
use Config;
use Time::Local ();

local $^W = 1;

$VERSION = '0.04';

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

sub environment_variables {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        if (defined $arg && ref $arg && ref $arg eq 'HASH') {
            $self->{_environment_variables} = $arg;
        }
        else {
            return $self->{_environment_variables}->{$arg};
        }
    }

    return sort keys %{$self->{_environment_variables}};
}

sub errstr {
    my $self = shift;

    if (ref $self) {
        my $refaddr = $self->_refaddr();
        $__ERRSTRS{$refaddr} = shift if @_;
        return $__ERRSTRS{$refaddr};

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

sub have_prerequisites {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        if (defined $arg && ref $arg && ref $arg eq 'HASH') {
            $self->{_have_prerequisites} = $arg;
        }
        else {
            return $self->{_have_prerequisites}->{$arg};
        }
    }

    return sort keys %{$self->{_have_prerequisites}};
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

sub make_test_output {
    my $self = shift;
    $self->{_make_test_output} = shift if @_;
    return $self->{_make_test_output};
}

sub need_prerequisites {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        if (defined $arg && ref $arg && ref $arg eq 'HASH') {
            $self->{_need_prerequisites} = $arg;
        }
        else {
            return $self->{_need_prerequisites}->{$arg};
        }
    }

    return sort keys %{$self->{_need_prerequisites}};
}

sub new {
    my $type  = shift;
    my $class = ref($type) || $type;
    my $self  = {
        _comments => undef,     # user comments
        _config => {},          # container for local perl configuration
        _dist => undef,         # distribution; e.g.: CPAN-Testers-Report-0.03
        _dist_name => undef,    # distribution's name; e.g. CPAN-Testers-Report
        _dist_vers => undef,    # distribution's version; e.g.: 0.03
        _environment_variables => {}, # self-explanatory
        _from => undef,         # name & e-mail of tester: Foo Bar <foo@bar.com>
        _grade => undef,        # from 'make test'; pass, fail, unknown, or na
        _interpreter              => 'perl',
        _interpreter_vers_extra   => undef,  # patch 1234
        _interpreter_vers_float   => undef,  # 5.008008
        _interpreter_vers_numeric => undef,  # 5.8.8
        _make_test_output => undef,    # output of 'make test'
        _need_prerequisites => {},     # module and verions required by testee
        _have_prerequisites => {},     # module are versions locally installed
        _perl_special_variables => {}, # names and values for $^X, $UID, etc..
        _perl_toolchain_modules => {}, # modules and versions for cpan toolchain
        _report_vers => 1,      # uniquely identifies this test report format
                                # XXX - ^ - THIS MUST BE INCREMENTED ANY TIME
                                # XXX - | - ANY TEST REPORT STRUCTURE IS ALTERED
        _rfc2822_date => undef, # RFC2822-compliant date-time
        _via => undef,          # caller; e.g.: CPAN, CPANPLUS, CPAN::Reporter
    };

    bless $self, $class;

    $self->_init($class) || return;

    return $self;
}

sub perl_special_variables {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        if (defined $arg && ref $arg && ref $arg eq 'HASH') {
            $self->{_perl_special_variables} = $arg;
        }
        else {
            return $self->{_perl_special_variables}->{$arg};
        }
    }

    return sort keys %{$self->{_perl_special_variables}};
}

sub perl_toolchain_modules {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        if (defined $arg && ref $arg && ref $arg eq 'HASH') {
            $self->{_perl_toolchain_modules} = $arg;
        }
        else {
            return $self->{_perl_toolchain_modules}->{$arg};
        }
    }

    return sort keys %{$self->{_perl_toolchain_modules}};
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

# Derived from Scalar::Util by Graham Barr
sub _blessed ($) {
    local($@, $SIG{__DIE__}, $SIG{__WARN__});
    length(ref($_[0]))
    ? eval { $_[0]->a_sub_not_likely_to_be_here }
    : undef
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

# Derived from Scalar::Util by Graham Barr
sub _refaddr($) {
    my $pkg = ref($_[0]) or return undef;
    if ($_[0]->_blessed($_[0])) {
        bless $_[0], 'Scalar::Util::Fake';
    }
    else {
        $pkg = undef;
    }
    "$_[0]" =~ /0x(\w+)/;
    my $i = do { local $^W; hex $1 };
    bless $_[0], $pkg if defined $pkg;
    $i;
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

sub DESTROY {
    my $self = shift;
    my $refaddr = $self->_refaddr();

    delete $__ERRSTRS{$refaddr};
}

1;

=head1 NAME

CPAN::Testers::Report - Creates CPAN Testers test-report objects

=head1 SYNOPSIS

  use CPAN::Testers::Report;
  use JSON::DWIW;

  my $serialized_report;

  {
    my $test_report = CPAN::Testers::Report->new() ||
        die CPAN::Testers::Report->errstr();
    $test_report->comments('..This is a computer-generated test report..');
    $test_report->dist('Test-Reporter-1.34') || die $test_report->errstr();
    $test_report->from('Adam J. Foxson <afoxson@pobox.com>') ||
        die $test_report->errstr();
    $test_report->grade('pass') || die $test_report->errstr();

    # generate a JSON serialization of test-report object ("client side")
    my $json_obj = JSON::DWIW->new({pretty => 1});
    $serialized_report = $json_obj->to_json($test_report);
  }

  # transport magic pixie dust! ($serialized_report transmitted via HTTP)

  {
    # reconstitue the object ("server side")
    my $json_obj = JSON::DWIW->new();
    my $test_report = $json_obj->from_json($serialized_report);
    bless $test_report, 'CPAN::Testers::Report';

    # methods may now be called against the reconstituted object..
    print $test_report->grade(), "\n";
  }

=head1 DESCRIPTION

This module is a component of the next-generation implementation of the CPAN
Tester's stack. Once completed, this distribution and its constituents will
obsolete Test::Reporter.

This module provides an abstraction for test reports. An object of this type
will encapsulate all data and information about a single, specific test report.
This object can then be submitted to a user's transport of choice for delivery.

This is a developer's release. The interface is not stable (but will be soon);
The API may change at any time without notice. This module is not yet
recommended for general use, but testing is highly encouraged.

=head1 SERIALIZATION

These objects are generated specifically with serialization in mind.

Below, please find a sample test report in JSON:

{
    "_interpreter_vers_numeric":"5.8.8",
    "_grade":"PASS",
    "_from":"Adam J. Foxson <afoxson@pobox.com>",
    "_config":
        {
            "gnulibc_version":"",
            "uname":"uname",
            "longdblsize":"16",
            "nvtype":"double",
            "ccdlflags":" ",
            "cppflags":"-no-cpp-precomp -g -pipe -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -Wdeclaration-after-statement -I\/usr\/local\/include",
            "cc":"cc",
            "archname":"darwin-thread-multi-2level",
            "config_args":"-ds -e -Dprefix=\/usr -Dccflags=-g  -pipe  -Dldflags=-Dman3ext=3pm -Duseithreads -Duseshrplib",
            "libc":"\/usr\/lib\/libc.dylib",
            "byteorder":"1234",
            "osname":"darwin",
            "d_longdbl":"define",
            "libpth":"\/usr\/local\/lib \/usr\/lib",
            "prototype":"define",
            "useperlio":"define",
            "so":"dylib",
            "ccflags":"-arch i386 -arch ppc -g -pipe -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -Wdeclaration-after-statement -I\/usr\/local\/include",
            "gccversion":"4.0.1 (Apple Inc. build 5465)",
            "ldflags":"-arch i386 -arch ppc -L\/usr\/local\/lib",
            "useposix":"true",
            "useshrplib":"true",
            "longsize":"4",
            "uselongdouble":null,
            "alignbytes":"8",
            "d_longlong":"define",
            "use64bitall":"define",
            "ccversion":"",
            "man3ext":"3pm",
            "doublesize":"8",
            "usemymalloc":"n",
            "hint":"recommended",
            "use5005threads":null,
            "usemultiplicity":"define",
            "perllibs":"-ldl -lm -lutil -lc",
            "dlext":"bundle",
            "ivsize":"4",
            "usesocks":null,
            "lddlflags":"-arch i386 -arch ppc -bundle -undefined dynamic_lookup -L\/usr\/local\/lib",
            "libperl":"libperl.dylib",
            "osvers":"9.0",
            "cccdlflags":" ",
            "ptrsize":"4",
            "uselargefiles":"define",
            "useithreads":"define",
            "longlongsize":"8",
            "usethreads":"define",
            "d_sfio":null,
            "lseeksize":"8",
            "n":"",
            "libs":"-ldbm -ldl -lm -lutil -lc",
            "dlsrc":"dl_dlopen.xs",
            "use64bitint":"define",
            "d_dlsymun":null,
            "ld":"cc -mmacosx-version-min=10.5",
            "gccosandvers":"",
            "d_sigaction":"define",
            "ivtype":"long",
            "optimize":"-O3",
            "nvsize":"8",
            "intsize":"4",
            "prefix":"\/"
        },
    "_report_vers":1,
    "_need_prerequisites":
        {
            "Test::More":"0.74"
        },
    "_interpreter_vers_extra":null,
    "_via":"CPAN::Testers::Report 0.03, cpantest",
    "_make_test_output":"PERL_DL_NONLAZY=1 \/usr\/bin\/perl \"-MExtUtils::Command::MM\" \"-e\" \"test_harness(0, 'blib\/lib', 'blib\/arch')\" t\/*.t\nt\/0-signature........skipped\n        all skipped: Set the environment variable TEST_SIGNATURE to enable this test.\nt\/1-report...........ok                                                      \nt\/98-pod.............skipped\n        all skipped: Skipping author tests\nt\/99-pod_coverage....skipped\n        all skipped: Skipping author tests\nAll tests successful, 3 tests skipped.\nFiles=4, Tests=113,  0 wallclock secs ( 0.38 cusr +  0.02 csys =  0.40 CPU)\n",
    "__errstr":null,
    "_dist":"Test-Reporter-1.34",
    "_dist_name":"Test-Reporter",
    "_environment_variables":
        {
            "HOME":"\/Users\/afoxson",
            "PERL5LIB":"\/sw\/lib\/perl5:\/sw\/lib\/perl5\/darwin"
        },
    "_interpreter_version_extra":"",
    "_interpreter_vers_float":"5.008008",
    "_interpreter":"perl",
    "_have_prerequisites":
        {
            "Test::More":"0.47"
        },
    "_perl_special_variables":
        {
            "$GID":"500 500",
            "$^X":"\/usr\/bin\/perl",
            "$EGID":"500 500",
            "$UID\/$EUID":"500 \/ 500"
        },
    "_dist_vers":"1.34",
    "_rfc2822_date":"Sun, 13 Jan 2008 03:03:03 -0500",
    "_perl_toolchain_modules":
        {
            "Module::Signature":"0.55",
            "YAML":"0.66",
            "File::Spec":"3.25",
            "ExtUtils::Install":"1.44",
            "ExtUtils::Command":"1.13",
            "Module::Build":"0.2808",
            "ExtUtils::CBuilder":"0.21",
            "ExtUtils::Manifest":"1.51",
            "Test::Harness":"3.05",
            "ExtUtils::MakeMaker":"6.42",
            "ExtUtils::ParseXS":"2.18",
            "version":"0.74",
            "YAML::Syck":"1.00",
            "Test::More":"0.74",
            "CPAN":"1.9205",
            "Cwd":"3.25"
        },
    "_comments":"...This is a computer-generated test report..."
}

=head1 METHODS

=over 4

=item * B<comments>

User-specified comments to include with the test report.

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

Automatically calculated but can instead be specified. This represents the
distribution's name only. For example 'Test-Reporter'.

=item * B<dist_vers>

Automatically calculated but can instead be specified. This represents the
distribution's version only. For example '1.34'.

=item * B<environment_variables>

Store environment variable name and value pairs inside the object:

$test_report->environment_variables({HOME => '/home/foo', PATH => '/bin'});

Get the environment variable names:

$test_report->environment_variables(); # ('HOME', 'PATH')

Get the value for a particular environment variable:

$test_report->environment_variables('HOME'); # '/home/foo'

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

=item * B<have_prerequisites>

Store prerequisite module and version pairs that the user had, inside the object:

$test_report->have_prerequisites({DBI => '1.23', CGI => '1.04'});

Get the prerequisite modules that the user had:

$test_report->have_prerequisites(); # ('DBI', 'CGI')

Get the version of a particular prerequisite module that user had:

$test_report->have_prerequisites('DBI'); # '1.23'

=item * B<interpreter>

At the moment always returns 'perl' but can instead be specified.

=item * B<interpreter_vers_numeric>

Automatically calculated but can instead be specified. This represents the
interpreter's version. For example in the format of '5.8.8'.

=item * B<interpreter_vers_float>

Automatically calculated but can instead be specified. This represents the
interpreter's version. For example in the format of '5.008008'.

=item * B<interpreter_vers_extra>

Automatically calculated but can instead be specified. This usually represents
the interpreter's patch/patchlevel, if available. For example 'patchlevel
12345'.

=item * B<make_test_output>

Output of "make test".

=item * B<need_prerequisites>

Store prerequisite module and version pairs that the user needed, inside the object:

$test_report->need_prerequisites({DBI => '1.23', CGI => '1.04'});

Get the prerequisite modules that the user needed:

$test_report->need_prerequisites(); # ('DBI', 'CGI')

Get the version of a particular prerequisite module that user needed:

$test_report->need_prerequisites('DBI'); # '1.23'

=item * B<new>

Constructor. Accepts no arguments at this time. If this method returns undef,
it failed.

=item * B<perl_special_variables>

Store perl special variable name and value pairs inside the object:

$test_report->perl_special_variables({'$^X' => '/usr/bin/perl'});

Get the perl special variable names:

$test_report->perl_special_variables(); # ('$^X')

Get the value for a particular perl special variable:

$test_report->perl_special_variables('$^X'); # '/usr/bin/perl'

=item * B<perl_toolchain_modules>

Store perl toolchain module and version pairs inside the object:

$test_report->perl_toolchain_modules({CPAN => '1.9205'});

Get the perl toolchain modules:

$test_report->perl_toolchain_modules(); # ('CPAN')

Get the version of a particular perl toolchain module:

$test_report->perl_toolchain_modules('CPAN'); # '1.9205'

=item * B<report_vers>

Revision of the internal test report object format. This will be incremented
any time the format changes.

=item * B<rfc2822_date>

Automatically calculated but can instead be specified. This is the
RFC2822-compliant datetime. This is metadata.

=item * B<validate>

Accepts no arguments. Returns true if the object represents a valid test
report. Returns false and sets errstr() if the object does not represent a
valid test report. This ensures that that distribution specified is parseable
into its name/version constituents, that the grade is one of 'pass', 'fail',
'na', or 'unknown', and that from is present and RFC 2822 compliant

=item * B<via>

Automatically calculated (based on the caller) but can instead be specified.
This represents the automation wrapping CPAN::Testers::Report. This is usually
something like CPAN::Reporter, CPAN::YACSmoke. This is metadata.

=back

=head1 COPYRIGHT

 Copyright (C) 2007, 2008 Adam J. Foxson and the CPAN Testers.
 All rights reserved.

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

=item * Barbie E<lt>F<barbie@missbarbell.co.uk>E<gt>

=item * David Golden E<lt>F<dagolden@cpan.org>E<gt>

=item * Kirrily "Skud" Robert E<lt>F<skud@cpan.org>E<gt>

=item * Richard Soderberg E<lt>F<rsod@cpan.org>E<gt>

=item * Kurt Starsinic E<lt>F<Kurt.Starsinic@isinet.com>E<gt>

=back

=cut
