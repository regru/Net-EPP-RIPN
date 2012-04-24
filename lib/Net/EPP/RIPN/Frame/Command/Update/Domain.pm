package Net::EPP::RIPN::Frame::Command::Update::Domain;
use base qw(Net::EPP::RIPN::Frame::Command::Update);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Update::Domain - an instance of L<Net::EPP::RIPN::Frame::Command::Update>
for domain names.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Update::Domain;
    use strict;

    my $info = Net::EPP::RIPN::Frame::Command::Update::Domain->new;
    $info->setDomain('example.tld');

    print $info->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
      epp-1.0.xsd">
        <command>
          <info>
            <domain:update
              xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"
              xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0
              domain-1.0.xsd">
                <domain:name>example-1.tldE<lt>/domain:name>
            </domain:update>
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
                    +----L<Net::EPP::RIPN::Frame::Command::Update::Domain>

=cut

sub new {
    my $package = shift;

    my $self = bless( $package->SUPER::new('update'), $package );

    my $domain = $self->addObject(
        Net::EPP::RIPN::Frame::ObjectSpec->spec('domain')
    );

    $self->addEl('name');
    $self->addEl($_) for qw/ add rem chg /;

    return $self;
}

sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement("domain:$name");
    $el->appendText($value) if defined $value;

    $self->getNode('update')->firstChild->appendChild($el);
}

=pod

=head1 METHODS

    $frame->setDomain($domain_name);

This specifies the domain name to be updated.

=cut

sub setDomain {
    my ($self, $domain) = @_;

    my $name = $self->getElementsByLocalName('domain:name')->shift;
    $name->appendText($domain);
}


=pod

    $frame->addNS($host);

Add DNS server $host.

=cut

sub addNS {
    my ($self, @ns) = @_;
    
    my $ns = $self->createElement('domain:ns');

    for my $host (@ns) {
        my $el = $self->createElement('domain:hostObj');
        $el->appendText($host);
        $ns->appendChild($el);
    }
    $self->add->appendChild($ns);
}

=pod

    $frame->addStatus('clientRenewProhibited', 'clientTransferProhibited');

Add statuses listed.

=cut
sub addStatus {
    my ($self, @statuses) = @_;

    for my $type ( @statuses ) {
        my $status = $self->createElement('domain:status');
        $status->setAttribute( s => $type );
        $self->add->appendChild($status);
    }
}


=pod

    my @status_list = qw/ clientUpdateProhibited /;
    $frame->remStatus(@status_list);

Remove statuses listed.

=cut
sub remStatus {
    my ($self, @statuses) = @_;

    for my $type ( @statuses ) {
        my $status = $self->createElement('domain:status');
        $status->setAttribute( s => $type );
        $self->rem->appendChild($status);
    }
}


sub remNS {
    my ($self, @ns) = @_;
    
    my $ns = $self->createElement('domain:ns');

    for my $host (@ns) {
        my $el = $self->createElement('domain:hostObj');
        $el->appendText($host);
        $ns->appendChild($el);
    }
    $self->rem->appendChild($ns);
}


# Change actions

sub chgRegistrant {
    my ($self, $registrant) = @_;

    my $el = $self->createElement('domain:registrant');
    $el->appendText($registrant);

    $self->chg->appendChild($el);
}

sub chgDescription {
    my ($self, @descriptions) = @_;

    for my $line (@descriptions) {
        my $el = $self->createElement('domain:description');
        $el->appendText($line);
        $self->chg->appendChild($el);
    }
    return 1;
}

sub chgAuthInfo {
    my ($self, $password) = @_;

    my $authinfo = $self->createElement('domain:authInfo');
    my $pw;
    if ( length $password ) {
        $pw = $self->createElement('domain:pw');
        $pw->appendText($password);
    }
    else {
        $pw = $self->createElement('domain:null');
    }
    $authinfo->appendChild($pw);
    $self->chg->appendChild($authinfo);
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
