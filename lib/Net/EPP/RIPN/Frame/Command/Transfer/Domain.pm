package Net::EPP::RIPN::Frame::Command::Transfer::Domain;
use base qw(Net::EPP::RIPN::Frame::Command::Transfer);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Transfer::Domain - an instance of L<Net::EPP::RIPN::Frame::Command::Transfer>
for domain objects.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Transfer::Domain;
    use strict;

    my $info = Net::EPP::RIPN::Frame::Command::Transfer::Domain->new;
    $info->setOp('query');
    $info->setDomain('example.tld');
    $info->addAcID('TEST2-REG-RF');

    print $info->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="http://www.ripn.net/epp/ripn-epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.ripn.net/epp/ripn-epp-1.0
      ripn-epp-1.0.xsd">
      <command>
        <transfer op="query">
          <domain:transfer
            xmlns:domain="http://www.ripn.net/epp/ripn-domain-1.0"
            xsi:schemaLocation="http://www.ripn.net/epp/ripn-domain-1.0
            ripn-domain-1.0.xsd">
              <domain:name>example.tld</domain:name>
              <domain:period unit="y">1</domain:period>
              <domain:acID>TEST2-REG-RF</domain:acID>
          </domain:transfer>
        </transfer>
        <clTRID/>
      </command>
    </epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Transfer>
                    +----L<Net::EPP::RIPN::Frame::Command::Transfer::Domain>

=cut

sub new {
    my $package = shift;

    my $self = bless( $package->SUPER::new('transfer'), $package );

    $self->addObject(
        Net::EPP::RIPN::Frame::ObjectSpec->spec('domain')
    );

    my $name = $self->createElement('domain:name');
    $self->getNode('transfer')->firstChild->appendChild($name);

    return $self;
}

=pod

=head1 METHODS

    $frame->setDomain('example.tld');

This method specifies the domain name for the transfer.

=cut

sub setDomain {
    my ($self, $domain) = @_;

    my $name = $self->getNode('domain:name');
    $name->appendText($domain);
}

=pod

    $frame->addAcID('NEW-REGISTRAR-ID');

This sets the authInfo code for the transfer.

=cut

sub addAcID {
    my ($self, $acID) = @_;

    my $el = $self->getNode('transfer')
        ->firstChild->addNewChild( undef, 'domain:acID' );
    $el->appendText($acID);
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
