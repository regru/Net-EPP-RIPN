package Net::EPP::RIPN::Frame::Command::Poll::Ack;
use base qw(Net::EPP::RIPN::Frame::Command::Poll);
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Poll::Ack - an instance of L<Net::EPP::RIPN::Frame::Command>
for the EPP C<E<lt>PollE<gt>> acknowledge command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Poll>

=cut

sub new {
    my $package = shift;
    my $self = bless( $package->SUPER::new('poll'), $package );
    $self->getCommandNode->setAttribute( op => 'ack' );
    return $self;
}

=pod

=head1 METHODS

        $frame->setMsgID($id);

This method sets the C<msgID> attribute on the C<E<lt>pollE<gt>> element that
is used to specify the message ID being acknowleged.

=cut

sub setMsgID {
    my ( $self, $id ) = @_;
    $self->getCommandNode->setAttribute( msgID => $id );
    return 1;
}

=pod

=head1 AUTHOR

Ilya Chesnokov L<chesnokov.ilya@gmail.com>.

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
