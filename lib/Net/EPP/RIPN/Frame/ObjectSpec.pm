package Net::EPP::RIPN::Frame::ObjectSpec;
use strict;
use warnings;

our $SPEC = {
    'domain' => [
        'http://www.ripn.net/epp/ripn-domain-1.0',
        'http://www.ripn.net/epp/ripn-domain-1.0 ripn-domain-1.0.xsd'
    ],
    'contact' => [
        'http://www.ripn.net/epp/ripn-contact-1.0',
        'http://www.ripn.net/epp/ripn-contact-1.0 ripn-contact-1.0.xsd'
    ],
    'host' => [
        'http://www.ripn.net/epp/ripn-host-1.0',
        'http://www.ripn.net/epp/ripn-host-1.0 ripn-host-1.0.xsd'
    ],
    'registrar' => [
        'http://www.ripn.net/epp/ripn-registrar-1.0',
        'http://www.ripn.net/epp/ripn-registrar-1.0 ripn-registrar-1.0.xsd'
    ],
};

sub spec {
    my ($self, $type) = @_;

    return (!defined($SPEC->{$type}) ? undef : ($type, @{$SPEC->{$type}}));
    return ( $type, @{ $SPEC->{$type} } ) if defined $SPEC->{$type};
    return;
}

=pod

=head1 NAME

Net::EPP::RIPN::Frame::ObjectSpec - metadata about EPP object types

=head1 SYNOPSIS

    use Net::EPP::RIPN::Frame;
    use strict;

    # create an EPP frame:
    my $check = Net::EPP::RIPN::Frame::Command::Check->new;

    # get the spec:
    my @spec = Net::EPP::RIPN::Frame::ObjectSpec->spec('domain');

    # create an object:
    my $domain = $check->addObject(@spec);

    # set the attributes:
    my $name = $check->createElement('domain:name');
    $name->addText('example.tld');

    # assemble the frame:
    $domain->appendChild($name);
    $check->getCommandNode->appendChild($domain);

    print $check->toString;

=head1 DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in RFC 4930) is an
application layer client-server protocol for the provisioning and management of
objects stored in a shared central repository. Specified in XML, the protocol
defines generic object management operations and an extensible framework that
maps protocol operations to objects. As of writing, its only well-developed
application is the provisioning of Internet domain names, hosts, and related
contact details.

Net::EPP::RIPN::Frame::ObjectSpec is a simple module designed to provide easy access to
metadata for the object types defined in the EPP specification.

=head1 USAGE

    my @spec = Net::EPP::RIPN::Frame::ObjectSpec->spec($type);

This function returns an array containing metadata for the given object type.
If no metadata is registered then the function returns undef.

The array contains three members:

    @spec = (
        $type,
        $xmlns,
        $schemaLocation,
    );

C<$type> is the same as the supplied argument, and the other two members
correspond to the XML attributes used to specify the object in an EPP
C<E<lt>commandE<gt>> or C<E<lt>responseE<gt>> frame.

The objects currently registered are:

=over

=item * C<domain>, for domain names.

=item * C<host>, for DNS server hosts.

=item * C<contact>, for contact objects.

=back

=head1 AUTHOR

Ilya Chesnokov L<chesnokov.ilya@gmail.com>.

=head1 COPYRIGHT

Copyright (c) 2009-2010, Ilya Chesnokov.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 SEE ALSO

=over

=item * the L<Net::EPP::RIPN::Frame> module, for constructing valid EPP frames.

=item * the L<Net::EPP::RIPN::Client> module, for communicating with EPP servers.

=item * RFCs 5730 and RFC 5734, available from L<http://www.ietf.org/>.

=item * EPP-RIPN protocol specification (in Russian) at L<http://www.tcinet.ru/content/documents>.

=back

=cut

1;
