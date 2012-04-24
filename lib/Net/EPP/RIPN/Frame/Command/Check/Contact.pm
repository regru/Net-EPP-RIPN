package Net::EPP::RIPN::Frame::Command::Check::Contact;
use base qw(Net::EPP::RIPN::Frame::Command::Check);
use Net::EPP::RIPN::Frame::ObjectSpec;

use strict;
use warnings;

=pod

=head1 NAME

Net::EPP::RIPN::Frame::Command::Check::Contact - an instance of L<Net::EPP::RIPN::Frame::Command::Check>
for contact objects.

=head1 SYNOPSIS

	use Net::EPP::RIPN::Frame::Command::Check::Contact;
	use strict;

	my $check = Net::EPP::RIPN::Frame::Command::Check::Contact->new;
	$check->addContact('contact-id-01');
	$check->addContact('contact-id-02');
	$check->addContact('contact-id-03');

	print $check->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <check>
	        <contact:check
	          xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
	          contact-1.0.xsd">
	            <contact:id>contact-id-01E<lt>/contact:id>
	            <contact:id>contact-id-02E<lt>/contact:id>
	            <contact:id>contact-id-03E<lt>/contact:id>
	        </contact:check>
	      </check>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::RIPN::Frame>
            +----L<Net::EPP::RIPN::Frame::Command>
                +----L<Net::EPP::RIPN::Frame::Command::Check>
                    +----L<Net::EPP::RIPN::Frame::Command::Check::Contact>

=cut

sub new {
    my $package = shift;
    my $self = bless( $package->SUPER::new('check'), $package );

    $self->addObject( Net::EPP::RIPN::Frame::ObjectSpec->spec('contact') );

    return $self;
}

=pod

=head1 METHODS

	$frame->addContact($contact_id);

This adds a contact ID to the list of contacts to be checked.

=cut

sub addContact {
    my ( $self, $contact ) = @_;

    my $name = $self->createElement('contact:id');
    $name->appendText($contact);

    $self->getNode('check')->getChildNodes->shift->appendChild($name);

    return 1;
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
