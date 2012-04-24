package Net::EPP::RIPN::Frame::Command::Create::Domain;
use base qw(Net::EPP::RIPN::Frame::Command::Create);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Create::Domain - an instance of L<Net::EPP::RIPN::Frame::Command::Create>
for domain objects.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Create::Domain;
    use strict;

    my $create = Net::EPP::RIPN::Frame::Command::Create::Domain->new;
    $create->setDomain('example.uk.com);

    print $create->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
      epp-1.0.xsd">
        <command>
          <create>
            <domain:create
              xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
              xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
              contact-1.0.xsd">
                <domain:name>example-1.tldE<lt>/domain:name>
            </domain:create>
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
                    +----L<Net::EPP::RIPN::Frame::Command::Create::Domain>

=cut

sub new {
    my $package = shift;

    my $self = bless($package->SUPER::new('create'), $package);

    $self->addObject(
        Net::EPP::RIPN::Frame::ObjectSpec->spec('domain')
    );

    $self->addEl('name');

    return $self;
}

=pod

=head1 METHODS

    my $element = $frame->setDomain($domain_name);

This sets the name of the object to be created. Returns the
C<E<lt>domain:nameE<gt>> element.

=cut

sub setDomain {
    my ($self, $domain) = @_;

    my $el = $self->getElementsByLocalName('domain:name')->shift;
    $el->appendText($domain);
    return $el;
}

sub addPeriod {
    my ($self, $period, $unit) = @_;

    $unit = 'y' if (!defined($unit) || $unit eq '');

    my $el = $self->addEl('period', $period);
    $el->setAttribute( unit => $unit );

    return $el;
}

sub addRegistrant {
    my ($self, $contact_id) = @_;

    return $self->addEl('registrant', $contact_id);
}

sub addNS {
    my ($self, @ns) = @_;

    my $ns = $self->createElement('domain:ns');

    foreach my $host (@ns) {
        my $el = $self->createElement('domain:hostObj');
        $el->appendText($host);
        $ns->appendChild($el);
    }
    $self->getNode('create')->firstChild->appendChild($ns);

    return 1;
}

sub addDescription {
    my ($self, @description) = @_;

    foreach my $line ( @description ) {
        next unless $line; # skip empty lines
        $self->addEl('description', $line);
    }
    return 1;
}

sub addAuthInfo {
    my ($self, $authInfo) = @_;

    my $el = $self->addEl('authInfo');
    my $pw = $self->createElement('domain:pw');
    $pw->appendText($authInfo);
    $el->appendChild($pw);
    return $el;
}

sub appendStatus {
    my ($self, $status) = @_;

    return $self->addEl('status', $status);
}

sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement('domain:'.$name);
    $el->appendText($value) if defined $value;

    $self->getNode('create')->firstChild->appendChild($el);

    return $el;
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
