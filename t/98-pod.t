BEGIN {
    if (!eval { require Test::More; 1 }) {
        print "1..0 # Skip Test::More not present; skipping";
        exit;
    }
    else {
        Test::More->import();
    }
};

plan skip_all => "Skipping author tests" if not $ENV{AUTHOR_TESTING};

my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
__END__
use Test::Pod; # Fake CPANTS
