#!/usr/bin/perl -w

use strict;
use Test;
use Config;
use CPAN::Testers::Report;

BEGIN { plan tests => 19 }

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
ok(defined $test_report->interpreter_vers1()); # hand-wave
ok(defined $test_report->interpreter_vers2()); # hand-wave
ok(defined $test_report->interpreter_vers_extra()); # hand-wave
ok($test_report->maturity(), 'released');
ok($test_report->osname(), $Config{osname});
ok($test_report->osvers(), $Config{osvers});
ok($test_report->report_vers(), 1);
ok(defined $test_report->rfc2822_date()); # hand-wave
ok(not defined $test_report->via());
