package Net::EPP::RIPN::Frame::Command::Info::Registrar;
use base qw(Net::EPP::RIPN::Frame::Command::Info);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Info::Registrar - an instance of
L<Net::EPP::RIPN::Frame::Command::Info> for registrars.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Info::Registrar;
    use strict;

    my $info = Net::EPP::RIPN::Frame::Command::Info::Registrar->new;
    $info->setRegistrar('REGRU-REG-RF');

    print $info->toString(1);

This results in an XML document like this:
    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="http://www.ripn.net/epp/ripn-epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.ripn.net/epp/ripn-epp-1.0
      ripn-epp-1.0.xsd">
        <command>
          <info>
            <registrar:info
              xmlns:registrar="http://www.ripn.net/epp/ripn-registrar-1.0"
              xsi:schemaLocation="http://www.ripn.net/epp/ripn-registrar-1.0
              ripn-registrar-1.0.xsd">
                <registrar:id>REGRU-REG-RF</registrar:id>
            </registrar:info>
          </info>
          <clTRID/>
        </command>
    </epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Info>
                    +----L<Net::EPP::RIPN::Frame::Command::Info::Registrar>

=cut

sub new {
    my $package = shift;
    my $self = bless($package->SUPER::new('info'), $package);

    my $registrar = $self->addObject(Net::EPP::RIPN::Frame::ObjectSpec->spec('registrar'));

    return $self;
}

=pod

=head1 METHODS

    $frame->setRegistrar($registrar_id);

This specifies the registrar id for which information is being requested.

=cut

sub setRegistrar {
    my ($self, $registrar) = @_;

    my $name = $self->createElement('registrar:id');
    $name->appendText($registrar);

    $self->getNode('info')->firstChild->appendChild($name);
}

=pod

=head1 AUTHOR

Ilya A. Chesnokov <chesnokov.ilya@gmail.com>

=head1 COPYRIGHT

This module is (c) 2010 Ilya A. Chesnokov <chesnokov.ilya@gmail.com>.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Net::EPP::RIPN::Frame>

=back

=cut

1;
