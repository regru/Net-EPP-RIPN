#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::EPP::RIPN' );
}

diag( "Testing Net::EPP::RIPN $Net::EPP::RIPN::VERSION, Perl $], $^X" );
