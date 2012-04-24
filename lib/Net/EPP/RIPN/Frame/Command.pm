package Net::EPP::RIPN::Frame::Command;

use strict;
use warnings;
no warnings 'redefine';
use Carp;

use Net::EPP::RIPN::Frame::Command::Check;
use Net::EPP::RIPN::Frame::Command::Create;
use Net::EPP::RIPN::Frame::Command::Delete;
use Net::EPP::RIPN::Frame::Command::Info;
use Net::EPP::RIPN::Frame::Command::Login;
use Net::EPP::RIPN::Frame::Command::Logout;
use Net::EPP::RIPN::Frame::Command::Poll;
use Net::EPP::RIPN::Frame::Command::Renew;
use Net::EPP::RIPN::Frame::Command::Transfer;
use Net::EPP::RIPN::Frame::Command::Update;

use base 'Net::EPP::RIPN::Frame';

=head1 NAME

Net::EPP::RIPN::Frame - An EPP-RIPN XML frame system built on top of L<XML::LibXML>.

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::EPP::RIPN;

    my $foo = Net::EPP::RIPN->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new 

=cut

sub new {
    my $package = shift;
    my $self = $package->SUPER::new( 'command', @_ );
    return bless( $self, $package );
}

sub addObject {
    my ( $self, $object, $ns, $schema ) = @_;

    my $obj = $self->createElement( $self->getCommandType );
    $obj->setNamespace( $ns, $object );
    $self->getNode( $self->getCommandType )->addChild($obj);
    $obj->setAttributeNS( $self->get_schema_uri, schemaLocation => $schema );

    return $obj;
}

sub _addExtraElements {
    my $self = shift;

    $self->command->addChild( $self->createElement( $self->getCommandType ) )
        if $self->getCommandType ne '';

    $self->command->addChild( $self->createElement('clTRID') );

    $self->_addCommandElements(@_);
    return 1;
}

sub _addCommandElements {
}

=head2 getNode

    my $node = $frame->getNode($id);
    my $node = $frame->getNode($ns, $id);

This is another convenience method. It uses C<$id> with the
I<getElementsByTagName()> method to get a list of nodes with that element name,
and simply returns the first L<XML::LibXML::Element> from the list.

If C<$ns> is provided, then I<getElementsByTagNameNS()> is used.

=cut

sub getCommandType {
    my $self = shift;

    my $type = ref($self);
    my $me   = __PACKAGE__;
    $type =~ s/^$me\:+//;
    $type =~ s/\:{2}.+//;
    return lc($type);
}

sub getCommandNode {
    my $self = shift;
    return $self->getNode( $self->getCommandType );
}

sub command { $_[0]->getNode('command') }
sub clTRID  { $_[0]->getNode('clTRID') }

=head1 AUTHOR

Ilya Chesnokov, C<< <chesnokov.ilya at gmail.com> >>

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


=head1 COPYRIGHT & LICENSE

Copyright 2010 Ilya Chesnokov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Net::EPP::RIPN::Frame
