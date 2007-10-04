use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
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
    LICENSE => 'perl',
);
