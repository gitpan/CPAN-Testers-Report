use ExtUtils::MakeMaker;

my $extra_meta = <<EOF;
resources:
    license: http://dev.perl.org/licenses/
    homepage: http://code.google.com/p/cpan-testers-report/
    bugtracker: http://code.google.com/p/cpan-testers-report/issues/list
    Repository: http://eclipse.resort.org/git/gitweb.cgi?p=cpan-testers-report.git
    MailingList: http://groups.google.com/group/cpan-testers-report
EOF

WriteMakefile(
    ($ExtUtils::MakeMaker::VERSION >= 6.18 ?
        ((MM->can('signature_target') ? (SIGN => 1) : ())) : ()),
    'NAME' => 'CPAN::Testers::Report',
    'PM' => {
        'lib/CPAN/Testers/Report.pm' => '$(INST_LIBDIR)/Report.pm',
    },
    'PREREQ_PM' => {
        'Time::Local' => 0,
        'Config' => 0,
    },
    'VERSION_FROM' => 'lib/CPAN/Testers/Report.pm',
    'dist' => {
        'COMPRESS' => 'gzip --best',
        'SUFFIX' => '.gz',
    },
    (   
        $] >= 5.005 ?  (   
            ABSTRACT_FROM => 'lib/CPAN/Testers/Report.pm',
            AUTHOR => 'Adam J. Foxson <afoxson@pobox.com>',
        ) : ()
    ),
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.36 ? (EXTRA_META => $extra_meta) : ()),
);
