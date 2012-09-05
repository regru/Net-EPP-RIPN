package Net::EPP::RIPN::Frame::Command::Delete::Host;
use base qw(Net::EPP::RIPN::Frame::Command::Delete);
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Delete::Host - an instance of L<Net::EPP::RIPN::Frame::Command::Delete>
for contact objects.

=head1 SYNOPSIS

        use Net::EPP::RIPN::Frame::Command::Delete::Host;
        use strict;

        my $delete = Net::EPP::RIPN::Frame::Command::Delete::Host->new;
        $delete->setHost('example.tld');

        print $delete->toString(1);

This results in an XML document like this:

        <?xml version="1.0" encoding="UTF-8"?>
        <epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
          epp-1.0.xsd">
            <command>
              <delete>
                <host:delete
                  xmlns:host="urn:ietf:params:xml:ns:host-1.0"
                  xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
                  host-1.0.xsd">
                    <host:name>ns0.example.tldE<lt>/host:name>
                </host:delete>
              </delete>
              <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
            </command>
        </epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Delete>
                    +----L<Net::EPP::RIPN::Frame::Command::Delete::Host>

=cut

sub new {
    my $package = shift;
    my $self = bless( $package->SUPER::new('delete'), $package );

    my $host
        = $self->addObject( Net::EPP::RIPN::Frame::ObjectSpec->spec('host') );

    return $self;
}

=pod

=head1 METHODS

        $frame->setHost($domain_name);

This specifies the host object to be deleted.

=cut

sub setHost {
    my ( $self, $host ) = @_;

    my $name = $self->createElement('host:name');
    $name->appendText($host);

    $self->getNode('delete')->firstChild->appendChild($name);

    return 1;
}

=pod

=head1 AUTHOR

Ilya Chesnokov <chesnokov.ilya@gmail.com>.

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
