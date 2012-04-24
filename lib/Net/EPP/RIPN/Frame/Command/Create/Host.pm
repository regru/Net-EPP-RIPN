package Net::EPP::RIPN::Frame::Command::Create::Host;
use base qw(Net::EPP::RIPN::Frame::Command::Create);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Create::Host - an instance of L<Net::EPP::RIPN::Frame::Command::Create>
for host objects.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Create::Host;
    use strict;

    my $create = Net::EPP::RIPN::Frame::Command::Create::Host->new;
    $create->setHost('example.uk.com);

    print $create->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
      epp-1.0.xsd">
        <command>
          <create>
            <host:create
              xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
              xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
              contact-1.0.xsd">
                <host:name>ns1.example-1.tld</host:name>
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
                    +----L<Net::EPP::RIPN::Frame::Command::Create::Host>

=cut


sub new {
    my $package = shift;

    my $self = bless( $package->SUPER::new('create'), $package );

    $self->addObject(
        Net::EPP::RIPN::Frame::ObjectSpec->spec('host')
    );
    $self->addEl('name');

    return $self;
}


sub setHost {
    my ($self, $host) = @_;

    my $el = $self->getElementsByLocalName('host:name')->shift;
    $el->appendText($host);
    return $el;
}

sub addIP {
    my ($self, $ip, $version) = @_;

    my $el = $self->addEl('addr', $ip);

    $version ||= 'v4';
    $el->setAttribute( ip => $version );
    return $el;
}

sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement("host:$name");
    $el->appendText($value) if defined $value;
    $self->getNode('create')->firstChild->appendChild($el);

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
