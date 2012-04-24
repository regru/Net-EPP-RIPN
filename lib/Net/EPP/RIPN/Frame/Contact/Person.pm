use strict;
use warnings;

package Net::EPP::RIPN::Frame::Contact::Person;
use XML::LibXML;
use Carp;
use base 'Net::EPP::RIPN::Frame::Contact';

=head2 new
    Create new person object
=cut
sub new {
    my $self = shift;
    return $self->SUPER::new('person');
}

# name/org, postal info (person, organization)
sub addTypePostalInfo {
    my ($self, $type, $info) = @_;

    croak "'info' parameter must be hashref, have '$info'"
        unless $info && ref $info eq 'HASH';

    my $postalInfo = $self->addEl( $type . 'PostalInfo' );

    if ( $info->{name} ) {
        my $name = $postalInfo->addNewChild(undef, 'contact:name');
        $name->appendText( $info->{name} );
    }

    if ( $info->{address} && ref $info->{address} eq 'ARRAY' ) {
        for my $address ( @{ $info->{address} } ) {
            my $addr = $postalInfo->addNewChild(undef, 'contact:address');
            $addr->appendText($address);
        }
    }

    return $postalInfo;
}


# birthday date (person)
sub addBirthday {
    my ($self, $date) = @_;

    $self->addEl('birthday', $date);
}

# passport (person)
sub addPassport {
    my ($self, $passport) = @_;

    $self->addEl('passport', $passport);
}


1;
