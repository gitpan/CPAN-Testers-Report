#!/usr/bin/perl -w

use strict;
use Test;
use Config;
use CPAN::Testers::Report;
use vars qw($VERSION);

BEGIN { plan tests => 74 }

my $report = CPAN::Testers::Report->new();
ok(defined $report);

my $test_report = CPAN::Testers::Report->new();
$test_report->comments('Rejoice!');
$test_report->config(Config::myconfig()) || die $test_report->error();
$test_report->dist('Test-Reporter-1.34') || die $test_report->error();
$test_report->grade('pass') || die $test_report->error();
$test_report->from('Adam J. Foxson <afoxson@pobox.com>');

ok($test_report->archname(), $Config{archname});
ok($test_report->comments(), 'Rejoice!');
ok(${$test_report->config()}, Config::myconfig());
ok($test_report->dist(), 'Test-Reporter-1.34');
ok($test_report->dist_name(), 'Test-Reporter');
ok($test_report->dist_vers(), '1.34');
ok($test_report->from(), 'Adam J. Foxson <afoxson@pobox.com>');
ok($test_report->grade(), 'PASS');
ok($test_report->interpreter(), 'perl');
ok(defined $test_report->interpreter_vers_numeric()); # hand-wave
ok(defined $test_report->interpreter_vers_float()); # hand-wave
ok(defined $test_report->interpreter_vers_extra()); # hand-wave
ok($test_report->osname(), $Config{osname});
ok($test_report->osvers(), $Config{osvers});
ok($test_report->report_vers(), 1);
ok(defined $test_report->rfc2822_date()); # hand-wave
ok($test_report->via(), 'CPAN::Testers::Report 0.02, main');

$VERSION = '0.02';
my $test_report2 = CPAN::Testers::Report->new();
ok(defined $test_report2);
ok($test_report2->via(), 'CPAN::Testers::Report 0.02, main 0.02');
ok($test_report2->_is_a_perl_release('perl-5.9.3'));
ok($test_report2->_is_a_perl_release('perl-5.9.2'));
ok($test_report2->_is_a_perl_release('perl-5.9.1'));
ok($test_report2->_is_a_perl_release('perl-5.9.0'));
ok($test_report2->_is_a_perl_release('perl-5.8.7'));
ok($test_report2->_is_a_perl_release('perl-5.8.6'));
ok($test_report2->_is_a_perl_release('perl-5.8.5'));
ok($test_report2->_is_a_perl_release('perl-5.8.4'));
ok($test_report2->_is_a_perl_release('perl-5.8.3'));
ok($test_report2->_is_a_perl_release('perl-5.8.2'));
ok($test_report2->_is_a_perl_release('perl-5.8.1'));
ok($test_report2->_is_a_perl_release('perl-5.8.0'));
ok($test_report2->_is_a_perl_release('perl-5.7.3'));
ok($test_report2->_is_a_perl_release('perl-5.7.2'));
ok($test_report2->_is_a_perl_release('perl-5.7.1'));
ok($test_report2->_is_a_perl_release('perl-5.7.0'));
ok($test_report2->_is_a_perl_release('perl-5.6.2'));
ok($test_report2->_is_a_perl_release('perl-5.6.1-TRIAL3'));
ok($test_report2->_is_a_perl_release('perl-5.6.1-TRIAL2'));
ok($test_report2->_is_a_perl_release('perl-5.6.1-TRIAL1'));
ok($test_report2->_is_a_perl_release('perl-5.6.1'));
ok($test_report2->_is_a_perl_release('perl-5.6.0'));
ok($test_report2->_is_a_perl_release('perl-5.6-info'));
ok($test_report2->_is_a_perl_release('perl5.005_04'));
ok($test_report2->_is_a_perl_release('perl5.005_03'));
ok($test_report2->_is_a_perl_release('perl5.005_02'));
ok($test_report2->_is_a_perl_release('perl5.005_01'));
ok($test_report2->_is_a_perl_release('perl5.005'));
ok($test_report2->_is_a_perl_release('perl5.004_05'));
ok($test_report2->_is_a_perl_release('perl5.004_04'));
ok($test_report2->_is_a_perl_release('perl5.004_03'));
ok($test_report2->_is_a_perl_release('perl5.004_02'));
ok($test_report2->_is_a_perl_release('perl5.004_01'));
ok($test_report2->_is_a_perl_release('perl5.004'));
ok($test_report2->_is_a_perl_release('perl5.003_07'));
ok($test_report2->_is_a_perl_release('perl-1.0_16'));
ok($test_report2->_is_a_perl_release('perl-1.0_15'));
ok(not $test_report2->_is_a_perl_release('Perl-BestPractice-0.01'));
ok(not $test_report2->_is_a_perl_release('Perl-Compare-0.10'));
ok(not $test_report2->_is_a_perl_release('Perl-Critic-0.2'));
ok(not $test_report2->_is_a_perl_release('Perl-Dist-0.0.5'));
ok(not $test_report2->_is_a_perl_release('Perl-Dist-Strawberry-0.1.2'));
ok(not $test_report2->_is_a_perl_release('Perl-Dist-Vanilla-7'));
ok(not $test_report2->_is_a_perl_release('Perl-Editor-0.02'));
ok(not $test_report2->_is_a_perl_release('Perl-Editor-Plugin-Squish-0.01'));
ok(not $test_report2->_is_a_perl_release('Perl-Metrics-0.06'));
ok(not $test_report2->_is_a_perl_release('Perl-MinimumVersion-0.13'));
ok(not $test_report2->_is_a_perl_release('Perl-Repository-APC-1.216'));
ok(not $test_report2->_is_a_perl_release('Perl-SAX-0.07'));
ok(not $test_report2->_is_a_perl_release('Perl-Signature-0.08'));
ok(not $test_report2->_is_a_perl_release('Perl-Tags-0.23'));
ok(not $test_report2->_is_a_perl_release('Perl-Tidy-20060719'));
ok(not $test_report2->_is_a_perl_release('Perl-Squish-0.02'));
ok(not $test_report2->_is_a_perl_release('Perl-Visualize-1.02'));
