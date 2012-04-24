use strict;
use warnings;

package Net::EPP::RIPN::Frame::Contact::Organization;
use XML::LibXML;
use Carp;
use base 'Net::EPP::RIPN::Frame::Contact';

=head2 new
    Create new organization object
=cut
sub new {
    my $self = shift;
    return $self->SUPER::new('organization');
}

# Add postal info of type $type
sub addTypePostalInfo {
    my ($self, $type, $info) = @_;

    croak "'info' parameter must be hashref, have '$info'"
        unless $info && ref $info eq 'HASH';

    my $postalInfo = $self->addEl( $type . 'PostalInfo' );

    if ( $info->{org} ) {
        my $org = $postalInfo->addNewChild(undef, 'contact:org');
        $org->appendText( $info->{org} );
    }

    if ( $info->{address} && ref $info->{address} eq 'ARRAY' ) {
        for my $address ( @{ $info->{address} } ) {
            my $addr = $postalInfo->addNewChild(undef, 'contact:address');
            $addr->appendText($address);
        }
    }

    return $postalInfo;
}

# legal address (organization)
sub addLegalInfo {
    my ($self, @addresses) = @_;

    my $addr = $self->addEl('legalInfo');
    for my $address (@addresses) {
        my $el = $addr->addNewChild(undef, 'contact:address');
        $el->appendText($address);
    }
}

1;
