package Net::EPP::RIPN::Frame::Command::Create::Contact;
use base qw(Net::EPP::RIPN::Frame::Command::Create);

use strict;
use Carp;

use Net::EPP::RIPN::Frame::ObjectSpec;
use Net::EPP::RIPN::Frame::Contact::Person;
use Net::EPP::RIPN::Frame::Contact::Organization;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Create::Contact - an instance of L<Net::EPP::RIPN::Frame::Command::Create>
for contact objects.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Create::Contact;
    use strict;

    my $create = Net::EPP::RIPN::Frame::Command::Create::Contact->new;
    $create->setContact('contact-id);

    print $create->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
      epp-1.0.xsd">
        <command>
          <create>
            <contact:create
              xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
              xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
              contact-1.0.xsd">
                <contact:id>example-1.tldE<lt>/contact:id>
            </contact:create>
          </create>
          <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
        </command>
    </epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Create>
                    +----L<Net::EPP::RIPN::Frame::Command::Create::Contact>

=cut

sub new {
    my $package = shift;
    my $self = bless($package->SUPER::new('create'), $package);

    $self->addObject( Net::EPP::RIPN::Frame::ObjectSpec->spec('contact') );
    $self->addEl('id');

    return $self;
}

sub newEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement($name);
    $el->appendText($value) if defined $value;
    return $el;
}

sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->newEl("contact:$name", $value);
    $self->getNode('create')->firstChild->appendChild($el);

    return $el;
}


=pod

=head1 METHODS

    my $element = $frame->setContact($contact_id);

This sets the contact ID of the object to be created. Returns the
C<E<lt>contact:nameE<gt>> element.

=cut

sub setContact {
    my ($self, $id) = @_;

    my $el = $self->getElementsByLocalName('contact:id')->shift;
    $el->appendText($id);
    return $el;
}



sub addPerson {
    my ($self, $person) = @_;

    my $parent = $self->getNode('create')->firstChild;

    my $person_obj = $person && ref $person
        ? $person
        : Net::EPP::RIPN::Frame::Contact::Person->new;

    $parent->appendChild($person_obj);
    return $person_obj;
}

sub addOrganization {
    my ($self, $organization) = @_;

    my $parent = $self->getNode('create')->firstChild;

    my $org_obj = $organization && ref $organization
        ? $organization : Net::EPP::RIPN::Frame::Contact::Organization->new;

    $parent->appendChild($org_obj);
    return $org_obj;
}

sub setVerified {
    my ($self) = @_;

    my $verified = $self->getNode('contact:verified');
    return $verified if $verified;

    $verified = $self->newEl('contact:verified');

    my $unverified = $self->getNode('contact:unverified');
    if ( $unverified ) {
        return $unverified->replaceNode($verified);
    }

    my $parent = $self->getNode('create')->firstChild;
    $parent->insertBefore( $verified, $self->getNode('contact:authInfo') || undef );
}

sub setUnverified {
    my ($self) = @_;

    my $unverified = $self->getNode('contact:unverified');
    return $unverified if $unverified;

    $unverified = $self->newEl('contact:unverified');

    my $verified = $self->getNode('contact:verified');
    if ( $verified ) {
        return $verified->replaceNode($unverified);
    }

    my $parent = $self->getNode('create')->firstChild;
    $parent->insertBefore( $unverified, $self->getNode('contact:authInfo') || undef );
}


sub addAuthInfo {
    my ($self, $authInfo) = @_;
    my $el = $self->addEl('authInfo');
    my $pw = $self->createElement('contact:pw');
    $pw->appendText($authInfo);
    $el->appendChild($pw);
    return $el;
}


=pod

=head1 AUTHOR

Ilya Chesnokov <chesnokov.ilya@gmail.com>

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
