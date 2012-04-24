package Net::EPP::RIPN::Frame;

use strict;
use warnings;
use Carp;

use Net::EPP::RIPN::Frame::Command;
use Net::EPP::RIPN::Frame::Greeting;
use Net::EPP::RIPN::Frame::Hello;
use Net::EPP::RIPN::Frame::ObjectSpec;
use Net::EPP::RIPN::Frame::Response;

use XML::LibXML;
use base 'XML::LibXML::Document';

my $EPP_RIPN_URN = 'http://www.ripn.net/epp/ripn-epp-1.0';
my $EPP_RIPN_XSD = 'ripn-epp-1.0.xsd';
my $SCHEMA_URI   = 'http://www.w3.org/2001/XMLSchema-instance';

=head1 NAME

Net::EPP::RIPN::Frame - An EPP-RIPN XML frame system built on top of L<XML::LibXML>.

=cut


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::EPP::RIPN;

    my $foo = Net::EPP::RIPN->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new 

=cut

sub new {
    my ($package, $type, @args) = @_;

    if (!$type) {
        my @parts = split(/::/, $package);
        $type = lc(pop(@parts));
    }

    if ($type !~ /^(hello|greeting|command|response)$/) {
        croak qq{Net::EPP::RIPN::Frame::new(): 'type' must be one of: }
            . qq{hello, greeting, command, response, not '$type'.};
    }

    my $self = $package->SUPER::new('1.0', 'UTF-8');
    bless($self, $package);

    my $epp = $self->createElementNS($EPP_RIPN_URN, 'epp');
    $epp->setNamespace($SCHEMA_URI, 'xsi', 0);
    $epp->setAttributeNS(
        $SCHEMA_URI,
        'schemaLocation',
        "$EPP_RIPN_URN $EPP_RIPN_XSD"
    );
    $self->addChild($epp);

    my $el = $self->createElement($type);
    $epp->addChild($el);

    $self->_addExtraElements(@args);

    return $self;
 
}

sub _addExtraElements {

}

=head2 getNode

        my $node = $frame->getNode($id);
        my $node = $frame->getNode($ns, $id);

This is another convenience method. It uses C<$id> with the
I<getElementsByTagName()> method to get a list of nodes with that element name,
and simply returns the first L<XML::LibXML::Element> from the list.

If C<$ns> is provided, then I<getElementsByTagNameNS()> is used.

=cut

sub getNode {
    my ($self, @args) = @_;

    if (scalar(@args) == 2) {
        return ( $self->getElementsByTagNameNS(@args) )[0];

    } elsif (scalar(@args) == 1) {
        return ( $self->getElementsByTagName($args[0]) )[0];

    } else {
        croak('Invalid number of arguments to getNode()');
    }
}


# Accessors to get/set XML parameters

# EPP-RIPN URN
sub get_epp_urn {
    return $EPP_RIPN_URN;
}

sub set_epp_urn {
    my ($self, $new_urn) = @_;

    $EPP_RIPN_URN = $new_urn;
}

# EPP-RIPN XSD
sub get_epp_xsd {
    return $EPP_RIPN_XSD;
}

sub set_epp_xsd {
    my ($self, $new_xsd) = @_;

    $EPP_RIPN_XSD = $new_xsd;
}

# EPP-RIPN Schema URI
sub get_schema_uri {
    return $SCHEMA_URI;
}

sub set_schema_uri {
    my ($self, $new_uri) = @_;
    
    $SCHEMA_URI = $new_uri;
}


=head1 AUTHOR

Ilya Chesnokov, C<< <chesnokov.ilya at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-epp-ripn at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-EPP-RIPN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::EPP::RIPN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-EPP-RIPN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-EPP-RIPN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-EPP-RIPN>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-EPP-RIPN/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Ilya Chesnokov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::EPP::RIPN::Frame
