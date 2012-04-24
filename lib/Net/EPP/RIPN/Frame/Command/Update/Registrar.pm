package Net::EPP::RIPN::Frame::Command::Update::Registrar;
use base qw(Net::EPP::RIPN::Frame::Command::Update);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Update::Registrar - an instance of L<Net::EPP::RIPN::Frame::Command::Update>
for registrar objects.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Update::Registrar;
    use strict;

    my $info = Net::EPP::RIPN::Frame::Command::Update::Registrar->new;
    $info->setRegistrar('ns0.example.tld');

    print $info->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
      epp-1.0.xsd">
        <command>
          <info>
            <registrar:update
              xmlns:registrar="urn:ietf:params:xml:ns:registrar-1.0"
              xsi:schemaLocation="urn:ietf:params:xml:ns:registrar-1.0
              registrar-1.0.xsd">
                <registrar:name>example-1.tldE<lt>/registrar:name>
            </registrar:update>
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
                    +----L<Net::EPP::RIPN::Frame::Command::Update::Registrar>

=cut

sub new {
    my $package = shift;

    my $self = bless( $package->SUPER::new('update'), $package );

    my $registrar = $self->addObject(
        Net::EPP::RIPN::Frame::ObjectSpec->spec('registrar')
    );

    $self->addEl('id');
    $self->addEl($_) for qw/ add rem chg /;

    return $self;
}

sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement("registrar:$name");
    $el->appendText($value) if defined $value;

    $self->getNode('update')->firstChild->appendChild($el);
}

=pod

=head1 METHODS

    $frame->setRegistrar($registrar_name);

This specifies the registrar object to be updated.

=cut

sub setRegistrar {
    my ($self, $registrar) = @_;

    my $name = $self->getElementsByLocalName('registrar:id')->shift;
    $name->appendText($registrar);
}

sub addEmail {
    my ($self, $email, $type) = @_;

    my $el = $self->rem->addNewChild(undef, 'registrar:email');
    $el->setAttribute( type => $type ) if defined $type;
    $el->appendText($email) if defined $email;
    return $el;
}

sub addIP {
    my ($self, $ip, $version) = @_;
    
    my $el = $self->add->addNewChild(undef, 'registrar:addr');
    $version ||= 'v4';
    $el->setAttribute( ip => $version );
    $el->appendText($ip);
    return $el;
}

sub remIP {
    my ($self, $ip, $version) = @_;

    my $el = $self->rem->addNewChild(undef, 'registrar:addr');
    $version ||= 'v4';
    $el->setAttribute( ip => $version );
    $el->appendText($ip);
    return $el;
}

sub chgVoice {
    my ($self, @phones) = @_;

    for my $phone (@phones) {
        my $el = $self->chg->addNewChild(undef, 'registrar:voice');
        $el->appendText($phone);
    }
}

sub chgFax {
    my ($self, @faxes) = @_;

    for my $fax (@faxes) {
        my $el = $self->chg->addNewChild(undef, 'registrar:fax');
        $el->appendText($fax);
    }
}

sub chgWhois {
    my ($self, $whois) = @_;

    my $el = $self->chg->addNewChild(undef, 'registrar:whois');
    $el->appendText($whois);
    return $el;
}

sub chgWWW {
    my ($self, $www) = @_;

    my $el = $self->chg->addNewChild(undef, 'registrar:www');
    $el->appendText($www);
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
