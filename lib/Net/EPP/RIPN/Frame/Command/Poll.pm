package Net::EPP::RIPN::Frame::Command::Poll;
use Net::EPP::RIPN::Frame::Command::Poll::Req;
use Net::EPP::RIPN::Frame::Command::Poll::Ack;
use base qw(Net::EPP::RIPN::Frame::Command);
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Poll - an instance of L<Net::EPP::RIPN::Frame::Command>
for the EPP C<E<lt>PollE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Poll>

=head1 METHODS

This module does not define any methods in addition to those it inherits from
its ancestors.

=head1 AUTHOR

Ilya Chesnokov L<chesnokov.ilya@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010, Ilya Chesnokov.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 SEE ALSO

=over

=item * L<Net::EPP::RIPN::Frame>

=back

=cut

1;
