package Net::EPP::RIPN::Frame::Command::Renew::Domain;
use base 'Net::EPP::RIPN::Frame::Command::Renew';
use Net::EPP::RIPN::Frame::ObjectSpec;
use strict;

sub new {
    my ($package) = @_;

    my $self = bless($package->SUPER::new('renew'), $package);

    $self->addObject(
        Net::EPP::RIPN::Frame::ObjectSpec->spec('domain')
    );

    $self->addEl('name');

    return $self;
}

sub addEl {
    my ($self, $name, $value) = @_;

    my $el = $self->createElement('domain:'.$name);
    $el->appendText($value) if defined $value;

    $self->getNode('renew')->firstChild->appendChild($el);

    return $el;
}


sub setDomain {
    my ($self, $domain) = @_;

    my $el = $self->getElementsByLocalName('domain:name')->shift;
    $el->appendText($domain);
    return $el;
}


sub addCurExpDate {
    my ($self, $curExpDate) = @_;

    return $self->addEl('curExpDate', $curExpDate);
}

sub addPeriod {
    my ($self, $period, $unit) = @_;

    $unit ||= 'y';

    my $el = $self->addEl('period', $period);
    $el->setAttribute( unit => $unit );

    return $el;
}


1;
