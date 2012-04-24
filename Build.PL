use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Net::EPP::RIPN',
    license           => 'perl',
    dist_author       => q{Ilya Chesnokov <chesnokov.ilya@gmail.com>},
    dist_version_from => 'lib/Net/EPP/RIPN.pm',
    requires          => {
        'XML::LibXML'  => 0,
        'Time::HiRes'  => 0,
        'Digest::SHA1' => 0,
    },
    build_requires      => {
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'Net-EPP-RIPN-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
