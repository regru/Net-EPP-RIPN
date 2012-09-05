package Net::EPP::RIPN::Frame::Greeting;
use base qw(Net::EPP::RIPN::Frame);

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Greeting - an instance of L<Net::EPP::RIPN::Frame> for server greetings

=head1 DESCRIPTION

This module is a subclass of L<Net::EPP::RIPN::Frame> that represents EPP server
greetings.

According to the EPP RFC, the server must transmit an EPP greeting frame to the
client upon connection, and in response to an EPP C<E<lt>helloE<gt>> command.
The C<E<lt>greetingE<gt>> frame provides information about the server,
including the server time, access control rules, and a list of the object
types that are provisioned by the server.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Greeting>


=cut

sub _addExtraElements {
    my $self = shift;

    $self->greeting->addChild( $self->createElement('svID') );
    $self->greeting->addChild( $self->createElement('svDate') );
    $self->greeting->addChild( $self->createElement('svcMenu') );
    $self->greeting->addChild( $self->createElement('dcp') );
    return 1;
}

=pod

=head1 METHODS

        my $node = $frame->greeting;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>greetingE<gt>> element.

        my $node = $frame->svID;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>svIDE<gt>> element.

        my $node = $frame->svDate;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>svDateE<gt>> element.

        my $node = $frame->svcMenu;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>svcMenuE<gt>> element.

        my $node = $frame->dcp;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>dcpE<gt>> element.

=cut

sub greeting { $_[0]->getNode('greeting') }
sub svID     { $_[0]->getNode('svID') }
sub svDate   { $_[0]->getNode('svDate') }
sub svcMenu  { $_[0]->getNode('svcMenu') }
sub dcp      { $_[0]->getNode('dcp') }

=pod

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
