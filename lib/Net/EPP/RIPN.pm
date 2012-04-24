package Net::EPP::RIPN;

use strict;
use warnings;

use Net::EPP::RIPN::Client;
use Net::EPP::RIPN::Frame;

=head1 NAME

Net::EPP::RIPN - EPP-RIPN protocol.

=cut

our $VERSION = '0.013';


=head1 SYNOPSIS

use Net::EPP::RIPN;

my $client = Net::EPP::RIPN::Client->new(
    host => $host,
    port => $port,
);

my $frame = Net::EPP::RIPN::Command::Login->new(
    clID => $user,
    pw   => $pass,
    lang => 'en'
);

my $response = $client->request($frame)
    or die "Connection error";


=head1 AUTHOR

Ilya Chesnokov, L<chesnokov.ilya@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-epp-ripn at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-EPP-RIPN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::EPP::RIPN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-EPP-RIPN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-EPP-RIPN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-EPP-RIPN>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-EPP-RIPN/>

=back


=head1 ACKNOWLEDGEMENTS

Big thanks to CentralNic Ltd for the great Net::EPP module distribution,
from which this distribution is forked.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Ilya Chesnokov L<chesnokov.ilya@gmail.com>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
