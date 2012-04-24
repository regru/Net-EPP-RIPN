package Net::EPP::RIPN::Frame::Command::Update;
use Net::EPP::RIPN::Frame::Command::Update::Contact;
use Net::EPP::RIPN::Frame::Command::Update::Domain;
use Net::EPP::RIPN::Frame::Command::Update::Host;
use Net::EPP::RIPN::Frame::Command::Update::Registrar;
use base qw(Net::EPP::RIPN::Frame::Command);
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Update - an instance of L<Net::EPP::RIPN::Frame::Command>
for the EPP C<E<lt>updateE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Update>

=head1 METHODS

=cut

sub add {
    my $self = shift;

    for my $el ($self->getNode('update')->firstChild->getChildNodes) {
        my (undef, $name) = split(/:/, $el->localName, 2);
        return $el if ($name eq 'add');
    }
    return;
}

sub rem {
    my $self = shift;

    for my $el ($self->getNode('update')->firstChild->getChildNodes) {
        my (undef, $name) = split(/:/, $el->localName, 2);
        return $el if ($name eq 'rem');
    }
    return;
}

sub chg {
    my $self = shift;

    for my $el ($self->getNode('update')->firstChild->getChildNodes) {
        my (undef, $name) = split(/:/, $el->localName, 2);
        return $el if ($name eq 'chg');
    }
    return;
}

=pod

    my $el = $frame->add;
    my $el = $frame->rem;
    my $el = $frame->chg;

These methods return the elements that should be used to contain the changes
to be made to the object (ie C<domain:add>, C<domain:rem>, C<domain:chg>).

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
