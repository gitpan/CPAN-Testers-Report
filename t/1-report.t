#!/usr/bin/perl -w

use strict;
use Test;
use Config;
use blib;
use CPAN::Testers::Report;
use vars qw($VERSION);

BEGIN { plan tests => 141 }

my $report = CPAN::Testers::Report->new();
ok(defined $report);

my $test_report = CPAN::Testers::Report->new();
ok(defined $test_report);
$test_report->comments('Rejoice!');
$test_report->dist('Test-Reporter-1.34');
$test_report->grade('pass');
$test_report->from('Adam J. Foxson <afoxson@pobox.com>');

ok($test_report->comments(), 'Rejoice!');
ok($test_report->dist(), 'Test-Reporter-1.34');
ok($test_report->dist_name(), 'Test-Reporter');
ok($test_report->dist_vers(), '1.34');
ok($test_report->from(), 'Adam J. Foxson <afoxson@pobox.com>');
ok($test_report->grade(), 'PASS');
ok($test_report->interpreter(), 'perl');
$test_report->interpreter('pugs');
ok($test_report->interpreter(), 'pugs');
ok(defined $test_report->interpreter_vers_numeric()); # hand-wave
ok(defined $test_report->interpreter_vers_float()); # hand-wave
ok(defined $test_report->interpreter_vers_extra()); # hand-wave
ok($test_report->report_vers(), 1);
ok(defined $test_report->rfc2822_date()); # hand-wave
ok($test_report->via(), 'CPAN::Testers::Report 0.04, main');
$test_report->via('woo');
ok($test_report->via(), 'CPAN::Testers::Report 0.04, woo');
ok(scalar(() = $test_report->config()) > 5);
ok(not defined $test_report->config('wibbleplinkifidosaysomyself'));

$VERSION = '0.03';
my $test_report2 = CPAN::Testers::Report->new();
ok(defined $test_report2);
ok($test_report2->via(), 'CPAN::Testers::Report 0.04, main 0.03');
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

my $test_report3 = CPAN::Testers::Report->new();
ok(defined $test_report3);
ok(not defined $test_report3->dist(undef));
ok($test_report3->errstr eq 'distribution not specified');
ok(not defined $test_report3->dist('Fluffy'));
ok($test_report3->errstr eq 'unable to determine distribution version for \'Fluffy\'');
ok(not defined $test_report3->dist('perl-5.6.1'));
ok($test_report3->errstr eq 'use perlbug for reporting test results against perl herself');
ok(not defined $test_report3->from(undef));
ok($test_report3->errstr eq 'from not specified');
ok(not defined $test_report3->from('mooooo'));
ok($test_report3->errstr eq 'invalid from; is not RFC 2822 compliant');
ok(not defined $test_report3->grade(undef));
ok($test_report3->errstr eq 'grade not specified');
ok(not defined $test_report3->grade('satisfactory'));
ok($test_report3->errstr eq 'invalid grade; choose: pass, fail, unknown, na');
my $foo = $test_report3->new();
ok(defined $foo);
ok(ref $foo eq 'CPAN::Testers::Report');

{
    no warnings 'redefine';
    local *Config::myconfig = sub {1};
    ok(not defined CPAN::Testers::Report->new());
    ok(CPAN::Testers::Report->errstr() eq 'unable to determine perl version');
}

my $test_report4 = CPAN::Testers::Report->new();
ok(defined $test_report4);
$test_report4->dist('Test-Reporter-1.34');
$test_report4->grade('pass');
$test_report4->from('Adam J. Foxson <afoxson@pobox.com>');
ok($test_report4->validate());

my $test_report5 = CPAN::Testers::Report->new();
ok(defined $test_report5);
$test_report5->dist('Test-Reporter-1.34');
$test_report5->grade('xass');
$test_report5->from('Adam J. Foxson <afoxson@pobox.com>');
ok(not $test_report5->validate());

my $test_report6 = CPAN::Testers::Report->new();
ok(defined $test_report6);
$test_report6->dist('Test-Reporter-1.34');
$test_report6->grade('pass');
$test_report6->from('blooooop');
ok(not $test_report6->validate());

my $test_report7 = CPAN::Testers::Report->new();
ok(defined $test_report7);
$test_report7->grade('pass');
$test_report7->from('Adam J. Foxson <afoxson@pobox.com>');
ok(not $test_report7->validate());

my $test_report8 = CPAN::Testers::Report->new();
ok(defined $test_report8);
$test_report8->dist('Test-Reporter');
$test_report8->grade('pass');
$test_report8->from('Adam J. Foxson <afoxson@pobox.com>');
ok(not $test_report8->validate());

my $test_report9 = CPAN::Testers::Report->new();
ok(defined $test_report9);
$test_report9->dist('perl-5.6.1');
$test_report9->grade('pass');
$test_report9->from('Adam J. Foxson <afoxson@pobox.com>');
ok(not $test_report9->validate());

my $test_report10 = CPAN::Testers::Report->new();
ok(defined $test_report10);
ok(not defined $test_report10->_distname_info());
ok(not defined $test_report10->_distname_info(undef));
ok(not defined $test_report10->_distname_info(1));
my ($c, $d, $e) = $test_report10->_distname_info('Unicode-Collate-Standard-V3_1_1-0.1');
ok($c, 'Unicode-Collate-Standard-V3_1_1');
ok($d, '0.1');
ok(not defined $e);
($c, $d, $e) = $test_report10->_distname_info('foo-55r');

my $test_report11 = CPAN::Testers::Report->new();
ok(defined $test_report11);
$test_report11->make_test_output('test blah blah');
ok($test_report11->make_test_output() eq 'test blah blah');
ok(not $test_report11->make_test_output() eq 'test blah bla');

my $test_report12 = CPAN::Testers::Report->new();
ok(defined $test_report12);
$test_report12->environment_variables({foo => 'bar', wibble => 'plink'});
ok((() = $test_report12->environment_variables()) == 2);
ok($test_report12->environment_variables('foo') eq 'bar');
ok($test_report12->environment_variables('wibble') eq 'plink');
ok(not $test_report12->environment_variables('wibble') eq 'plinx');

my $test_report13 = CPAN::Testers::Report->new();
ok(defined $test_report13);
$test_report13->have_prerequisites({foo => 'bar', wibble => 'plink'});
ok((() = $test_report13->have_prerequisites()) == 2);
ok($test_report13->have_prerequisites('foo') eq 'bar');
ok($test_report13->have_prerequisites('wibble') eq 'plink');
ok(not $test_report13->have_prerequisites('wibble') eq 'plinx');

my $test_report14 = CPAN::Testers::Report->new();
ok(defined $test_report14);
$test_report14->need_prerequisites({foo => 'bar', wibble => 'plink'});
ok((() = $test_report14->need_prerequisites()) == 2);
ok($test_report14->need_prerequisites('foo') eq 'bar');
ok($test_report14->need_prerequisites('wibble') eq 'plink');
ok(not $test_report14->need_prerequisites('wibble') eq 'plinx');

my $test_report15 = CPAN::Testers::Report->new();
ok(defined $test_report15);
$test_report15->perl_special_variables({foo => 'bar', wibble => 'plink'});
ok((() = $test_report15->perl_special_variables()) == 2);
ok($test_report15->perl_special_variables('foo') eq 'bar');
ok($test_report15->perl_special_variables('wibble') eq 'plink');
ok(not $test_report15->perl_special_variables('wibble') eq 'plinx');

my $test_report16 = CPAN::Testers::Report->new();
ok(defined $test_report16);
$test_report16->perl_toolchain_modules({foo => 'bar', wibble => 'plink'});
ok((() = $test_report16->perl_toolchain_modules()) == 2);
ok($test_report16->perl_toolchain_modules('foo') eq 'bar');
ok($test_report16->perl_toolchain_modules('wibble') eq 'plink');
ok(not $test_report16->perl_toolchain_modules('wibble') eq 'plinx');
