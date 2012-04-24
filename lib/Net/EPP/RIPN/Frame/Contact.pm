use strict;
use warnings;

package Net::EPP::RIPN::Frame::Contact;
use XML::LibXML;
use base 'XML::LibXML::Element';

use Carp;

=head2 new
    New contact info frame of type $type (person or organization)
=cut
sub new {
    my ($package, $type) = @_;

    my $self = bless( $package->SUPER::new("contact:$type"), $package );
}


sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->addNewChild(undef, "contact:$name");
    $el->appendText($value) if defined $value;
    return $el;
}


=head2 addTaxpayerNumbers
    add taxpayerNumbers element
    applies to: person, organization
=cut
sub addTaxpayerNumbers {
    my ($self, $code) = @_;

    $self->addEl('taxpayerNumbers', $code);
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

# voice (person, organization)
sub addVoice {
    my ($self, @phones) = @_;

    $self->addEl('voice', $_) for @phones;
}

# fax (person, organization)
sub addFax {
    my ($self, @faxes) = @_;

    $self->addEl('fax', $_) for @faxes;
}


# e-mail (person, organization)
sub addEmail {
    my ($self, @emails) = @_;

    $self->addEl('email', $_) for @emails;
}

# Disclose (or undisclose, depending on $flag) some elements
sub addDisclose {
    my ($self, $flag, @elements) = @_;

    my $disclose = $self->getElementsByLocalName('contact:disclose')->shift;
    if ( ! defined $disclose ) {
        $disclose = $self->addEl('disclose');
        $disclose->setAttribute( flag => $flag );
    }

    $disclose->addNewChild(undef, "contact:$_") for @elements;
}


1;

