use strict;
use warnings;

package Net::EPP::RIPN::Frame::Command::Login;
use base qw(Net::EPP::RIPN::Frame::Command);

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Login - an instance of L<Net::EPP::RIPN::Frame::Command>
for the EPP C<E<lt>loginE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Login>

=cut

sub _addCommandElements {
    my ($self, $arg_ref) = @_;

    # Add 'login' element and children
    my $login = $self->getNode('login');

    my $clID = $login->addChild($self->createElement('clID'));
    $clID->appendText( $arg_ref->{clID} ) if exists $arg_ref->{clID};

    my $pw = $login->addChild( $self->createElement('pw') );
    $pw->appendText( $arg_ref->{pw} ) if exists $arg_ref->{pw};

    # Add 'options' element and it's children
    my $options = $login->addChild( $self->createElement('options') );

    my $version = $options->addChild( $self->createElement('version') );
    $version->appendText( $arg_ref->{version} ) if exists $arg_ref->{version};

    my $lang = $options->addChild( $self->createElement('lang') );
    $lang->appendText( $arg_ref->{lang} ) if exists $arg_ref->{lang};

    my $svcs = $self->getNode('login')->addChild( $self->createElement('svcs') );

    if ( $arg_ref->{objURIs} ) {
        for my $obj_uri ( @{ $arg_ref->{objURIs} } ) {
            my $el = $self->createElement('objURI');
            $el->appendText($obj_uri);
            $svcs->appendChild($el);
        }
    }
}

=pod

=head1 METHODS

    my $node = $frame->clID;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>clIDE<gt>> element.

    my $node = $frame->pw;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>pwE<gt>> element.

    my $node = $frame->svcs;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>svcsE<gt>> element.

    my $node = $frame->options;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>optionsE<gt>> element.

    my $node = $frame->version;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>versionE<gt>> element.

    my $node = $frame->lang;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>langE<gt>> element.

=cut

sub clID    { $_[0]->getNode('clID'    ) }
sub pw      { $_[0]->getNode('pw'      ) }
sub svcs    { $_[0]->getNode('svcs'    ) }
sub options { $_[0]->getNode('options' ) }
sub version { $_[0]->getNode('version' ) }
sub lang    { $_[0]->getNode('lang'    ) }

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
