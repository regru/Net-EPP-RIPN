package Net::EPP::RIPN::Frame::Command::Update::Host;
use base qw(Net::EPP::RIPN::Frame::Command::Update);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Update::Host - an instance of L<Net::EPP::RIPN::Frame::Command::Update>
for host objects.

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame::Command::Update::Host;
    use strict;

    my $info = Net::EPP::RIPN::Frame::Command::Update::Host->new;
    $info->setHost('ns0.example.tld');

    print $info->toString(1);

This results in an XML document like this:

    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
      epp-1.0.xsd">
        <command>
          <info>
            <host:update
              xmlns:host="urn:ietf:params:xml:ns:host-1.0"
              xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
              host-1.0.xsd">
                <host:name>example-1.tldE<lt>/host:name>
            </host:update>
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
                    +----L<Net::EPP::RIPN::Frame::Command::Update::Host>

=cut

sub new {
    my $package = shift;

    my $self = bless( $package->SUPER::new('update'), $package );

    my $host = $self->addObject(
        Net::EPP::RIPN::Frame::ObjectSpec->spec('host')
    );

    $self->addEl('name');
    $self->addEl($_) for qw/ add rem /;

    return $self;
}

sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement("host:$name");
    $el->appendText($value) if defined $value;

    $self->getNode('update')->firstChild->appendChild($el);
}

=pod

=head1 METHODS

    $frame->setHost($host_name);

This specifies the host object to be updated.

=cut

sub setHost {
    my ($self, $host) = @_;

    my $name = $self->getElementsByLocalName('host:name')->shift;
    $name->appendText($host);
}

sub addIP {
    my ($self, $ip, $version) = @_;
    
    return unless $ip && $version;

    my $el = $self->add->addNewChild(undef, 'host:addr');
    $version ||= 'v4';
    $el->setAttribute( ip => $version );
    $el->appendText($ip);
    return $el;
}

sub remIP {
    my ($self, $ip, $version) = @_;

    return unless $ip && $version;

    my $el = $self->rem->addNewChild(undef, 'host:addr');
    $version ||= 'v4';
    $el->setAttribute( ip => $version );
    $el->appendText($ip);
    return $el;
}

sub addStatus {
    my ($self, @statuses) = @_;

    for my $status ( @statuses ) {
        my $el = $self->add->addNewChild(undef, 'host:status');
        $el->setAttribute( s => $status );
    }
}

sub remStatus {
    my ($self, @statuses) = @_;

    for my $status ( @statuses ) {
        my $el = $self->rem->addNewChild(undef, 'host:status');
        $el->setAttribute( s => $status );
    }
}


sub chgName {
    my ($self, $name) = @_;

    my $chg = $self->chg || $self->addEl('chg');

    my $el = $chg->addNewChild(undef, 'host:name');
    $el->appendText($name);
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
