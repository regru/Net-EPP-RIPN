package Net::EPP::RIPN::Frame::Command::Update::Contact;
use base qw(Net::EPP::RIPN::Frame::Command::Update);
use Net::EPP::RIPN::Frame::ObjectSpec;
use Net::EPP::RIPN::Frame::Contact::Person;
use Net::EPP::RIPN::Frame::Contact::Organization;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Update::Contact - an instance of L<Net::EPP::RIPN::Frame::Command::Update>
for contact objects.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Update::Contact;
    use strict;

    my $info = Net::EPP::RIPN::Frame::Command::Update::Contact->new;
    $info->setID('REG-12345');

    print $info->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
      epp-1.0.xsd">
        <command>
          <info>REG-12345
            <contact:update
              xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
              xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
              contact-1.0.xsd">
                <contact:id>example-1.tldE<lt>/contact:id>
            </contact:update>
          </info>
          <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
        </command>
    </epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Update>
                    +----L<Net::EPP::RIPN::Frame::Command::Update::Contact>

=cut

sub new {
    my $package = shift;

    my $self = bless( $package->SUPER::new('update'), $package );

    $self->addObject( Net::EPP::RIPN::Frame::ObjectSpec->spec('contact') );

    $self->addEl('id');

    return $self;
}


sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement("contact:$name");
    $el->appendText($value) if defined $value;

    $self->getNode('update')->firstChild->appendChild($el);

    return $el;
}

=pod

=head1 METHODS

    $frame->setContact($id);

This specifies the contact object to be updated.

=cut

sub setContact {
    my ($self, $id) = @_;

    my $el = $self->getNode('contact:id');
    $el->appendText($id);
}


=pod

    $frame->addStatus($type);

Add a status of $type

=cut

sub addStatus {
    my ($self, $type) = @_;

    my $status = $self->createElement('contact:status');
    $status->setAttribute( s => $type );

    my $add = $self->getElementsByLocalName('contact:add')->shift
        || $self->addEl('add');

    $add->appendChild($status);
}

=pod

    $frame->remStatus($type);

Remove a status of $type.

=cut
sub remStatus {
    my ($self, $type) = @_;

    my $status = $self->createElement('contact:status');
    $status->setAttribute( s => $type );

    my $rem = $self->getElementsByLocalName('contact:rem')->shift
        || $self->addEl('rem');

    $rem->appendChild($status);
}


=pod

    my $person = $frame->chgPerson;
    $person->addTypePostalInfo(
        int => {
            name => 'John D. Doe',
            address => [ '12345, Russia, Moscow, Unknown st., 25' ],
        }
    );
    $person->addVoice('+7.4951234567');

Append a person object to 'chg'.

=cut


sub chgPerson {
    my ($self, $person) = @_;

    my $chg = $self->getElementsByLocalName('contact:chg')->shift
        || $self->addEl('chg');

    my $person_obj = $person && ref $person
        ? $person
        : Net::EPP::RIPN::Frame::Contact::Person->new;

    $chg->appendChild($person_obj);
    return $person_obj;
}

=pod

    my $org = $frame->chgOrganization;
    $org->addTypePostalInfo(
        int => {
            org     => 'Domain Name Registrar REG.RU',
            address => [ '12345, Russia, Moscow, Petushkova st., 3, 313' ],
        }
    );
    $person->addVoice('+7.4951234567');

Append a person object to 'chg'.

=cut

sub chgOrganization {
    my ($self, $organization) = @_;

    my $chg = $self->getElementsByLocalName('contact:chg')->shift
        || $self->addEl('chg');

    my $org_obj = $organization && ref $organization
        ? $organization
        : Net::EPP::RIPN::Frame::Contact::Organization->new;

    $chg->appendChild($org_obj);
    return $org_obj;
}


sub setVerified {
    my ($self) = @_;

    my $chg = $self->getElementsByLocalName('contact:chg')->shift
        || $self->addEl('chg');

    return $chg->addNewChild(undef, 'contact:verified');
}

sub setUnverified {
    my ($self) = @_;

    my $chg = $self->getElementsByLocalName('contact:chg')->shift
        || $self->addEl('chg');

    return $chg->addNewChild(undef, 'contact:unverified');
}



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
