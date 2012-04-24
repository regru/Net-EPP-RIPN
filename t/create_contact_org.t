#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Carp;
use Net::EPP::RIPN;

use Test::XML tests => 2;

my $org_info = {
  'verified' => '',
  'id' => 'test-org',
  'organization' => {
    'email' => [
      'info@example.com'
    ],
    'voice' => [
      '+7 499 3333333'
    ],
    'locPostalInfo' => {
      'org' => 'ЗАО "Домейнер"',
      'address' => [
        '123456, Москва, ул. Примерная, д. 89, ЗАО "Домейнер"'
      ]
    },
    'intPostalInfo' => {
      'org' => 'Domeiner, CJSC'
    },
    'fax' => [
      '+7 499 3333333'
    ],
    'legalInfo' => {
      'address' => [
        '123456, Москва, ул. Примерная, д. 89, ЗАО "Домейнер"'
      ]
    },
    'taxpayerNumbers' => '2222222222'
  }
};

my $good_org_xml = <<'END_XML';
<?xml version="1.0" encoding="UTF-8"?>
<epp xmlns="http://www.ripn.net/epp/ripn-epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.ripn.net/epp/ripn-epp-1.0 ripn-epp-1.0.xsd">
  <command>
    <create>
      <contact:create xmlns:contact="http://www.ripn.net/epp/ripn-contact-1.0" xsi:schemaLocation="http://www.ripn.net/epp/ripn-contact-1.0 ripn-contact-1.0.xsd">
        <contact:id>test-org</contact:id>
        <contact:organization>
          <contact:intPostalInfo>
            <contact:org>Domeiner, CJSC</contact:org>
          </contact:intPostalInfo>
          <contact:locPostalInfo>
            <contact:org>ЗАО "Домейнер"</contact:org>
            <contact:address>123456, Москва, ул. Примерная, д. 89, ЗАО "Домейнер"</contact:address>
          </contact:locPostalInfo>
          <contact:legalInfo>
            <contact:address>123456, Москва, ул. Примерная, д. 89, ЗАО "Домейнер"</contact:address>
          </contact:legalInfo>
          <contact:taxpayerNumbers>2222222222</contact:taxpayerNumbers>
          <contact:voice>+7 499 3333333</contact:voice>
          <contact:fax>+7 499 3333333</contact:fax>
          <contact:email>info@example.com</contact:email>
        </contact:organization>
        <contact:unverified/>
      </contact:create>
    </create>
    <clTRID/>
  </command>
</epp>
END_XML

my $org_xml = create_contact($org_info)->toString(1);

is_well_formed_xml($org_xml);
is_xml($org_xml, $good_org_xml);

sub create_contact {
    my ($contact) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Create::Contact->new;
    $frame->setContact( $contact->{id} );

    my ($entity_el, $entity_ref, $entity_type);
    if ( exists $contact->{person} && ref $contact->{person} eq 'HASH' ) {

        $entity_ref  = $contact->{person};
        $entity_el   = $frame->addPerson;
        $entity_type = 'person';
    }
    if ( exists $contact->{organization}
        && ref $contact->{organization} eq 'HASH' ) {

        $entity_ref  = $contact->{organization};
        $entity_el   = $frame->addOrganization;
        $entity_type = 'organization';
    }

    croak "'person' or 'organization' element must present"
        unless defined $entity_type;


    # Add postal info
    for my $type ( qw/ int loc / ) {
        $entity_el->addTypePostalInfo(
            $type => $entity_ref->{ $type . 'PostalInfo' }
        ) if $entity_ref->{ $type . 'PostalInfo' };
    }

    # Add specific fields
    $entity_type eq 'person'
        ? _add_person_fields($entity_el, $entity_ref)
        : _add_org_fields($entity_el, $entity_ref);

    # Add voice, fax, email fields
    for my $field ( qw/ voice fax email / ) {
        $entity_el->addEl($field, $_) for @{ $entity_ref->{$field} };
    }

    # Add disclose or undisclose elements
    if ( $entity_ref->{disclose} && ref $entity_ref->{disclose} eq 'ARRAY' ) {
        $entity_el->addDisclose( 1, @{ $entity_ref->{disclose} } );
    }

    if ( $entity_ref->{undisclose}
         && ref $entity_ref->{undisclose} eq 'ARRAY' ) {

        $entity_el->addDisclose( 0, @{ $entity_ref->{undisclose} } );
    }

    # Other properties
    if ( exists $contact->{verified} ) {
        $contact->{verified} ? $frame->setVerified : $frame->setUnverified;
    }

    $frame->addAuthInfo( $contact->{authInfo} ) if defined $contact->{authInfo};
    return $frame;
}

sub _add_person_fields {
    my ($entity, $info) = @_;

    $entity->addTaxpayerNumbers( $info->{taxpayerNumbers} )
        if defined $info->{taxpayerNumbers};
    $entity->addBirthday( $info->{birthday} ) if defined $info->{birthday};

    if ( exists $info->{passport} && ref $info->{passport} eq 'ARRAY' ) {
        $entity->addPassport($_) for @{ $info->{passport} };
    }
}

sub _add_org_fields {
    my ($entity, $info) = @_;

    if ( exists $info->{legalInfo} && ref $info->{legalInfo} eq 'HASH' ) {
        my $legal = $info->{legalInfo};
        if ( exists $legal->{address} && ref $legal->{address} eq 'ARRAY' ) {
            $entity->addLegalInfo( @{ $legal->{address} } );
        }
    }

    $entity->addTaxpayerNumbers( $info->{taxpayerNumbers} )
        if defined $info->{taxpayerNumbers};
}


