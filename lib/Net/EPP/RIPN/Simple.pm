package Net::EPP::RIPN::Simple;
use strict;
use warnings;

use utf8;
use Carp;
use Digest::SHA1 qw(sha1_hex);
use Data::Dumper;
use Time::HiRes qw(time);

use Net::EPP::RIPN::Frame;
use Net::EPP::RIPN::ResponseCodes;
use base qw(Net::EPP::RIPN::Client);

use constant EPP_XMLNS => Net::EPP::RIPN::Frame->get_epp_urn;

our $Error   = '';
our $Code    = OK;
our $Message = '';

=pod

=head1 NAME

Net::EPP::RIPN::Simple - a simple EPP-RIPN client interface for the most common jobs

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Net::EPP::RIPN::Simple;
    use strict;

    my $epp = Net::EPP::RIPN::Simple->new(
        host    => 'epp.nic.tld',
        user    => 'my-id',
        pass    => 'my-password',
    );

    my $domain = 'example.tld';

    if ($epp->check_domain($domain) == 1) {
        print "Domain is available\n" ;

    } else {
        my $info = $epp->domain_info($domain);
        printf("Domain was registered on %s by %s\n", $info->{crDate}, $info->{crID});

    }

=head1 DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in RFC 4930) is an
application layer client-server protocol for the provisioning and management of
objects stored in a shared central repository. Specified in XML, the protocol
defines generic object management operations and an extensible framework that
maps protocol operations to objects. As of writing, its only well-developed
application is the provisioning of Internet domain names, hosts, and related
contact details.

This module provides a high level interface to the EPP protocol. It hides all
the boilerplate of connecting, logging in, building request frames and parsing
response frames behind a simple, Perlish interface.

It is based on the C<Net::EPP::RIPN::Client> module and uses C<Net::EPP::RIPN::Frame>
to build request frames.

=head1 CONSTRUCTOR

The constructor for C<Net::EPP::RIPN::Simple> has the same general form as the
one for C<Net::EPP::RIPN::Client>, but with the following exceptions:

=over

=item * Unless otherwise set, C<port> defaults to 700

=item * Unless the C<no_ssl> parameter is set, SSL is always on

=item * You can use the C<user> and C<pass> parameters to supply authentication information.

=item * The C<timeout> parameter controls how long the client waits for a response from the server before returning an error.

=back

The constructor will establish a connection to the server and retrieve the
greeting (which is available via C<$epp-E<gt>{greeting}>) and then send a
C<E<lt>loginE<gt>> request.

If the login fails, the constructor will return C<undef> and set
C<$Net::EPP::RIPN::Simple::Error> and C<$Net::EPP::RIPN::Simple::Code>.

=cut

sub new {
    my ( $package, %params ) = @_;

    $params{dom} = 1;
    my $self = $package->SUPER::new(%params);

    $self->{user}    = $params{user};
    $self->{pass}    = $params{pass};
    $self->{lang}    = $params{lang};

    $self->{debug}   = $params{debug};
    $self->{timeout} = $params{timeout} || 10;

    $self->{authenticated} = $params{authenticated} || 0;
    $self->{connected}     = $params{authenticated} || 0;

    bless( $self, $package );

    if ( $self->{authenticated} ) {
        $self->debug("We are already connected and authenticated");
        return $self;
    };

    $self->_connect
        ? return $self
        : return;
}


sub hello {
    my $self = shift;

    my $hello = Net::EPP::RIPN::Frame::Hello->new;
    my $response = $self->request($hello);
    $self->{greeting} = $response;
    return $self->{greeting};
}

sub login {
    my ($self, $user, $pass, $lang) = @_;

    $user ||= $self->{user};
    $pass ||= $self->{pass};
    $lang ||= $self->{lang};

    my $greeting = $self->greeting;

    # Get nessessary info from greeting
    my $version  = $greeting->getElementsByTagNameNS(EPP_XMLNS, 'version')
        ->shift->firstChild->data;
    
    $lang ||= $greeting->getElementsByTagNameNS(EPP_XMLNS, 'lang')
        ->shift->firstChild->data;

    my @obj_uris = map {
            (my $objURI = $_->firstChild->data) =~ s/\s.*$//;
            $objURI;
        } $greeting->getElementsByTagNameNS(EPP_XMLNS, 'objURI');
    
    # Make Login command
    my $login = Net::EPP::RIPN::Frame::Command::Login->new({
        clID    => $user,
        pw      => $pass,
        version => $version,
        lang    => $lang,
        objURIs => \@obj_uris,
    });

    my $response = $self->request($login)
        or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);
    if ( $Code > 1999 ) {
        $Error = "Error logging in ($Code, $Message)";
        $self->debug($Error);
        return;
    }

    # Save session id in object
    $self->browser->cookie_jar->scan(
        # extract EPPSESSIONID cookie value
        sub {
            my ( $version, $key, $val, @other_params ) = @_;
            if ( uc $key eq 'EPPSESSIONID' ) {
                $self->{session_id} = $val;
                $self->{session_cookie_params} = [
                    $version, $key, $val, @other_params
                ];
                return;
            }
        }
    );

    return 1;
}

sub _connect {
    my $self = shift;

    # Connecting...
    $self->debug("Attempting to connect to $self->{host}:$self->{port}");
    eval { $self->connect; };
    if ( $@ ) {
        chomp($@);
        $@ =~ s/ at .+ line .+$//;
        $self->debug("Connect failed: $@");
        $Code = COMMAND_FAILED;
        $Error = $Message = $@;
        return;
    }
    $self->{connected} = 1;
    $self->debug("Connected.");

    # Send 'hello' and receive greeting
    $self->debug("Sending 'hello' frame to server");
    my $greeting = $self->hello;

    if ( ref($greeting) ne 'Net::EPP::RIPN::Frame::Response' ) {
        chomp($@);
        $@ =~ s/ at .+ line .+$//;
        $self->debug($@);
        $Code  = COMMAND_FAILED;
        $Error = $Message = $@;
        return;
    }

    # Got error response instead of normal greeting?
    if ( $greeting->response ) {
        $Code    = $self->_get_response_code($greeting);
        $Message = $self->_get_message($greeting);
        if ( $Code > 1999 ) {
            $Error = "Error in greeting (response code $Code)";
            $self->debug($Error);
            return;
        }
    }

    # Sending login
    $self->debug('Connected OK, preparing login frame');
    $self->login( $self->{user}, $self->{pass} )
        or return;

    $self->{authenticated} = 1; 
    return 1;
}




=pod

=head1 Availability Checks

You can do a simple C<E<lt>checkE<gt>> request for an object like so:

    my $result = $epp->check_domain($domain);

    my $result = $epp->check_host($host);

    my $result = $epp->check_contact($contact);

Each of these methods has the same profile. They will return one of the
following:

=over

=item * C<undef> in the case of an error (check C<$Net::EPP::RIPN::Simple::Error> and C<$Net::EPP::RIPN::Simple::Code>).

=item * C<0> if the object is already provisioned.

=item * C<1> if the object is available.

=back

=cut

sub check_domain {
    my ( $self, $domain ) = @_;
    return ( $self->check_domains($domain) )[1];
}

sub check_domains {
    my ($self, @domains) = @_;
    return $self->_check('domain', @domains);
}

sub check_host {
    my ( $self, $host ) = @_;
    return ( $self->check_hosts($host) )[1];
}

sub check_hosts {
    my ($self, @hosts) = @_;
    return $self->_check('host', @hosts);
}

sub check_contact {
    my ( $self, $contact ) = @_;
    return ( $self->check_contacts($contact) )[1];
}

sub check_contacts {
    my ($self, @contacts) = @_;
    return $self->_check('contact', @contacts);
}

sub _check {
    my ( $self, $type, @identifiers ) = @_;

    my $frame;
    if ( $type eq 'domain' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Check::Domain->new;
        $frame->addDomain($_) for @identifiers;

    }
    elsif ( $type eq 'contact' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Check::Contact->new;
        $frame->addContact($_) for @identifiers;

    }
    elsif ( $type eq 'host' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Check::Host->new;
        $frame->addHost($_) for @identifiers;

    }
    else {
        $Error = "Unknown object type '$type'";
        return;
    }

    my $response = $self->request($frame)
        or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = "Error $Code ($Message) in $type\_check";
        return;
    }

    my $xmlns = ( Net::EPP::RIPN::Frame::ObjectSpec->spec($type) )[1];
    my $key;
    if ( $type eq 'domain' || $type eq 'host' ) {
        $key = 'name';

    }
    elsif ( $type eq 'contact' ) {
        $key = 'id';

    }

    my @elements = $response->getElementsByTagNameNS($xmlns, $key);

    return map { $_->textContent, $_->getAttribute('avail') } @elements;
}

=pod

=head1 Prolongation of domain registration

    You can prolong domain registration period using the following:

    $epp->renew_domain($domain, $expires, $period);

    $expires is a current domain expiration date.

=cut

sub renew_domain {
    my ($self, $domain, $expires, $period) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Renew::Domain->new;
    
    $frame->setDomain($domain);
    $frame->addCurExpDate($expires);
    $frame->addPeriod($period);


    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }

    return 1;
}

=pod

=head1 Retrieving Object Information

You can retrieve information about an object by using one of the following:

    my $info = $epp->domain_info($domain, $authInfo, $follow);

    my $info = $epp->host_info($host);

    my $info = $epp->contact_info($contact, $authInfo);

C<Net::EPP::RIPN::Simple> will construct an C<E<lt>infoE<gt>> frame and send
it to the server, then parse the response into a simple hash ref. The
layout of the hash ref depends on the object in question. If there is an
error, these methods will return C<undef>, and you can then check
C<$Net::EPP::RIPN::Simple::Error> and C<$Net::EPP::RIPN::Simple::Code>.

If C<$authInfo> is defined, it will be sent to the server as per RFC
4931, Section 3.1.2 and RRC 4933, Section 3.1.2. If the supplied
authInfo code is validated by the registry, additional information will
appear in the response. If it is invalid, you should get an error.

If the C<$follow> parameter is true, then C<Net::EPP::RIPN::Simple> will also
retrieve the relevant host and contact details for a domain: instead of
returning an object name or ID for the domain's registrant, contact
associations, DNS servers or subordinate hosts, the values will be
replaced with the return value from the appropriate C<host_info()> or
C<contact_info()> command (unless there was an error, in which case the
original object ID will be used instead).

=cut

sub domain_info {
    my ( $self, $domain, $authInfo, $follow ) = @_;

    my $result = $self->_info( 'domain', $domain, $authInfo );
    return $result if ( ref($result) ne 'HASH' || !$follow );

    if ( defined( $result->{'ns'} ) && ref( $result->{'ns'} ) eq 'ARRAY' ) {
        for ( my $i = 0; $i < scalar( @{ $result->{'ns'} } ); $i++ ) {
            my $info = $self->host_info( $result->{'ns'}->[$i] );
            $result->{'ns'}->[$i] = $info if ( ref($info) eq 'HASH' );
        }
    }

    if ( defined( $result->{'hosts'} )
        && ref( $result->{'hosts'} ) eq 'ARRAY' )
    {
        for ( my $i = 0; $i < scalar( @{ $result->{'hosts'} } ); $i++ ) {
            my $info = $self->host_info( $result->{'hosts'}->[$i] );
            $result->{'hosts'}->[$i] = $info if ( ref($info) eq 'HASH' );
        }
    }

    my $info = $self->contact_info( $result->{'registrant'} );
    $result->{'registrant'} = $info if ( ref($info) eq 'HASH' );

    return $result;
}

sub host_info {
    my ( $self, $host ) = @_;
    return $self->_info( 'host', $host );
}

sub contact_info {
    my ( $self, $contact, $authInfo ) = @_;
    return $self->_info( 'contact', $contact, $authInfo );
}

sub registrar_info {
    my ( $self, $registrar ) = @_;
    return $self->_info( 'registrar', $registrar );
}

sub _info {
    my ( $self, $type, $identifier, $authInfo ) = @_;
    my $frame;
    if ( $type eq 'domain' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Info::Domain->new;
        $frame->setDomain($identifier);
    }
    elsif ( $type eq 'contact' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Info::Contact->new;
        $frame->setContact($identifier);
    }
    elsif ( $type eq 'host' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Info::Host->new;
        $frame->setHost($identifier);
    }
    elsif ( $type eq 'registrar' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Info::Registrar->new;
        $frame->setRegistrar($identifier);
    }
    else {
        $Error = "Unknown object type '$type'";
        return;
    }

    my @spec = Net::EPP::RIPN::Frame::ObjectSpec->spec($type);

    if ( defined($authInfo) && $authInfo ne '' ) {
        $self->debug('adding authInfo element to request frame');
        my $el = $frame->createElement( $spec[0] . ':authInfo' );
        my $pw = $frame->createElement( $spec[0] . ':pw'       );
        $pw->appendText($authInfo);
        $el->appendChild($pw);
        $frame->getNode( $spec[1], 'info' )->appendChild($el);
    }

    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = "Error $Code ($Message) in $type\_info.";
        return;
    }

    my $infData = $response->getNode( $spec[1], 'infData' );

    return {
        'domain'    => \&_domain_infData_to_hash,
        'host'      => \&_host_infData_to_hash,
        'contact'   => \&_contact_infData_to_hash,
        'registrar' => \&_registrar_infData_to_hash,
    }->{$type}->($self, $infData);
}

sub _get_common_properties_from_infData {
    my ( $self, $infData, @extra ) = @_;
    my $hash = {};

    my @default = qw/ roid clID crID crDate upID upDate trDate /;

    foreach my $name ( @default, @extra ) {
        my $els = $infData->getElementsByLocalName($name);
        $hash->{$name} = $els->shift->textContent if $els->size > 0;
    }

    my $codes = $infData->getElementsByLocalName('status');
    while ( my $code = $codes->shift ) {
        push( @{ $hash->{status} }, $code->getAttribute('s') );
    }

    return $hash;
}

=pod

=head2 Domain Information

The hash ref returned by C<domain_info()> will usually look something
like this:

    $info = {
      'contacts' => {
        'admin' => 'contact-id'
        'tech' => 'contact-id'
        'billing' => 'contact-id'
      },
      'registrant' => 'contact-id',
      'clID' => 'registrar-id',
      'roid' => 'tld-12345',
      'status' => [
        'ok'
      ],
      'authInfo' => 'abc-12345',
      'name' => 'example.tld',
      'trDate' => '2007-01-18T11:08:03.0Z',
      'description' => [
        'Description line #1',
        'Description line #2',
      ],
      'ns' => [
        'ns0.example.com',
        'ns1.example.com',
      ],
      'crDate' => '2001-02-16T12:06:31.0Z',
      'exDate' => '2009-02-16T12:06:31.0Z',
      'crID' => 'registrar-id',
      'upDate' => '2007-08-29T04:02:12.0Z',
      hosts => [
        'ns0.example.tld',
        'ns1.example.tld',
      ],
    };

Members of the C<contacts> hash ref may be strings or, if there are
multiple associations of the same type, an anonymous array of strings.
If the server uses the "hostAttr" model instead of "hostObj", then the
C<ns> member will look like this:

    $info->{ns} = [
      {
        name => 'ns0.example.com',
        addrs => [
          type => 'v4',
          addr => '10.0.0.1',
        ],
      },
      {
        name => 'ns1.example.com',
        addrs => [
          type => 'v4',
          addr => '10.0.0.2',
        ],
      },
    ];

Note that there may be multiple members in the C<addrs> section and that
the C<type> attribute is optional.

=cut

sub _domain_infData_to_hash {
    my ( $self, $infData ) = @_;

    my $hash = $self->_get_common_properties_from_infData(
        $infData,
        qw/ registrant name exDate /
    );

    my $descriptions = $infData->getElementsByLocalName('description');
    while ( my $description = $descriptions->shift ) {
        push( @{ $hash->{description} }, $description->textContent );
    }

    my $ns = $infData->getElementsByLocalName('ns');
    if ( $ns->size == 1 ) {
        my $el       = $ns->shift;
        my $hostObjs = $el->getElementsByLocalName('hostObj');
        while ( my $hostObj = $hostObjs->shift ) {
            push( @{ $hash->{ns} }, $hostObj->textContent );
        }
    }

    my $hosts = $infData->getElementsByLocalName('host');
    while ( my $host = $hosts->shift ) {
        push( @{ $hash->{hosts} }, $host->textContent );
    }

    my $auths = $infData->getElementsByLocalName('authInfo');
    if ( $auths->size == 1 ) {
        my $authInfo = $auths->shift;
        my $pw       = $authInfo->getElementsByLocalName('pw');
        $hash->{authInfo} = $pw->shift->textContent if ( $pw->size == 1 );
    }

    return $hash;
}

=pod

=head2 Host Information

The hash ref returned by C<host_info()> will usually look something like
this:

    $info = {
      'crDate' => '2007-09-17T15:38:56.0Z',
      'clID' => 'registrar-id',
      'crID' => 'registrar-id',
      'roid' => 'tld-12345',
      'status' => [
        'linked',
        'serverDeleteProhibited',    
      ],
      'name' => 'ns0.example.tld',
      'addrs' => [
        {
          'version' => 'v4',
          'addr' => '10.0.0.1'
        }
      ]
    };

Note that hosts may have multiple addresses, and that C<version> is
optional.

=cut

sub _host_infData_to_hash {
    my ( $self, $infData ) = @_;

    my $hash = $self->_get_common_properties_from_infData( $infData, 'name' );

    for my $addr ( $infData->getElementsByLocalName('addr') ) {
        my $version = $addr->getAttribute('ip');
        push @{ $hash->{addrs}->{$version} }, $addr->textContent;
    }

    return $hash;
}

=pod

=head2 Contact Information

The hash ref returned by C<contact_info()> will usually look something
like this:

    $VAR1 = {
      'id' => 'contact-id',
      'postalInfo' => {
        'int' => {
          'name' => 'John Doe',
          'org' => 'Example Inc.',
          'addr' => {
            'street' => [
              '123 Example Dr.'
              'Suite 100'
            ],
            'city' => 'Dulles',
            'sp' => 'VA',
            'pc' => '20166-6503'
            'cc' => 'US',
          }
        }
      },
      'clID' => 'registrar-id',
      'roid' => 'CNIC-HA321983',
      'status' => [
        'linked',
        'serverDeleteProhibited'
      ],
      'voice' => '+1.7035555555x1234',
      'fax' => '+1.7035555556',
      'email' => 'jdoe@example.com',
      'crDate' => '2007-09-23T03:51:29.0Z',
      'upDate' => '1999-11-30T00:00:00.0Z'
    };

There may be up to two members of the C<postalInfo> hash, corresponding
to the C<int> and C<loc> internationalised and localised types.

=cut

sub _contact_infData_to_hash {
    my ( $self, $infData ) = @_;

    my $hash = $self->_get_common_properties_from_infData(
        $infData, 'id'
    );

    my $persons = $infData->getElementsByLocalName('person');
    if ( $persons->size > 0 ) {
        $hash->{person} = $self->_parse_contact_info( $persons->shift );

        # If there is any info about closed contact fields, then put it to hash
        my $disclose_els = $infData->getElementsByLocalName('disclose');
        if ( $disclose_els->size > 0 ) {

            my $disclose = $disclose_els->shift;

            my $flag = $disclose->getAttribute('flag');

            if ( defined $flag && $flag == 0 ) {
                $hash->{undisclose} = [
                    map { $_->localname } $disclose->nonBlankChildNodes
                ];
            }
            # By default "Private Person" flag is not set (disclose everything)
        }
    }

    my $orgs = $infData->getElementsByLocalName('organization');
    if ( $orgs->size > 0 ) {
        $hash->{organization} = $self->_parse_contact_info( $orgs->shift );
    }

    my $auths = $infData->getElementsByLocalName('authInfo');
    if ( $auths->size == 1 ) {
        my $authInfo = $auths->shift;
        my $pw       = $authInfo->getElementsByLocalName('pw');
        $hash->{authInfo} = $pw->shift->textContent if ( $pw->size == 1 );
    }

    my $verified = $infData->getElementsByLocalName('verified');
    if ( $verified->size > 0 ) {
        $hash->{verified} = 1;
    }

    my $unverified = $infData->getElementsByLocalName('unverified');
    if ( $unverified->size > 0 ) {
        $hash->{verified} = 0;
    }

    return $hash;
}


sub _parse_contact_info {
    my ($self, $data) = @_;

    my $ref = {};
    for my $type ( qw/ int loc / ) {

        my $info = $data->getElementsByLocalName(
            $type . 'PostalInfo'
        )->shift or next;

        my $postalInfo = {};
        foreach my $name ( qw/ name org / ) {
            my $els = $info->getElementsByLocalName($name);
            $postalInfo->{$name} = $els->shift->textContent
                if $els->size == 1;
        }

        my $addrs = $info->getElementsByLocalName('address');
        if ( $addrs->size > 0 ) {
            while ( my $addr = $addrs->shift ) {
                push @{ $postalInfo->{address} }, $addr->textContent;
            }
        }
        $ref->{ $type . 'PostalInfo' } = $postalInfo;
    }

    for my $name ( qw/ passport voice fax email / ) {
        my $els = $data->getElementsByLocalName($name);
        if ( $els && $els->size > 0 ) {
            while ( my $el = $els->shift ) {
                push @{ $ref->{$name} }, $el->textContent;
            }
        }
    }

    for my $name ( qw/ birthday taxpayerNumbers / ) {
        my $els = $data->getElementsByLocalName($name);
        $ref->{$name} = $els->shift->textContent if $els->size > 0;
    }

    my $legalInfo = $data->getElementsByLocalName('legalInfo')->shift;
    if ( $legalInfo ) {
        for my $addr ( $legalInfo->getElementsByLocalName('address') ) {
            push @{ $ref->{legalInfo}->{address} }, $addr->textContent;
        }
    }

    # remove this as it gets in the way:
    #my $els = $infData->getElementsByLocalName('disclose');
    #if ( $els->size > 0 ) {
    #    while ( my $el = $els->shift ) {
    #        $el->parentNode->removeChild($el);
    #    }
    #}
    return $ref;
}


sub _registrar_infData_to_hash {
    my ($self, $infData) = @_;

    my $hash = {};

    # simple fields
    my @simple_params = qw/ id taxpayerNumbers www whois crDate upDate /;
    foreach my $name ( @simple_params ) {
        my $els = $infData->getElementsByLocalName($name);
        $hash->{$name} = $els->shift->textContent if $els->size > 0;
    }

    # status codes
    my $codes = $infData->getElementsByLocalName('status');
    while ( my $code = $codes->shift ) {
        push( @{ $hash->{status} }, $code->getAttribute('s') );
    }

    # postal info
    for my $type ( qw/ int loc / ) {

        my $info = $infData->getElementsByLocalName(
            $type . 'PostalInfo'
        )->shift or next;

        my $postalInfo = {};
        my $orgs = $info->getElementsByLocalName('org');
        $postalInfo->{'org'} = $orgs->shift->textContent if $orgs->size == 1;

        my $addrs = $info->getElementsByLocalName('address');
        if ( $addrs->size > 0 ) {
            while ( my $addr = $addrs->shift ) {
                push @{ $postalInfo->{address} }, $addr->textContent;
            }
        }
        $hash->{ $type . 'PostalInfo' } = $postalInfo;
    }

    my $legalInfo = $infData->getElementsByLocalName('legalInfo')->shift;
    if ( $legalInfo ) {
        for my $addr ( $legalInfo->getElementsByLocalName('address') ) {
            push @{ $hash->{legalInfo}->{address} }, $addr->textContent;
        }
    }

    for my $name ( qw/ voice fax / ) {
        my $els = $infData->getElementsByLocalName($name);
        while ( my $el = $els->shift ) {
            push @{ $hash->{$name} }, $el->textContent;
        }
    }

    for my $addr ( $infData->getElementsByLocalName('addr') ) {
        my $version = $addr->getAttribute('ip');# || 'v4';
        push @{ $hash->{addrs}->{$version} }, $addr->textContent;
    }

    for my $email ( $infData->getElementsByLocalName('email') ) {
        my $type = $email->getAttribute('type');
        push @{ $hash->{email}->{$type} }, $email->textContent;
    }

    return $hash;
}


=pod

=head1 Object Transfers

The EPP C<E<lt>transferE<gt>> command suppots five different operations:
query, request, cancel, approve, and reject. C<Net::EPP::RIPN::Simple> makes
these available using the following methods:

    # For domain objects:

    $epp->domain_transfer_query($domain);
    $epp->domain_transfer_cancel($domain);
    $epp->domain_transfer_request($domain, $new_registrar_id);
    $epp->domain_transfer_approve($domain);
    $epp->domain_transfer_reject($domain);

Most of these methods will just set the value of C<$Net::EPP::RIPN::Simple::Code>
and return either true or false. However, the C<domain_transfer_request()>,
C<domain_transfer_query()> methods will return a hash ref that looks like this:

    my $trnData = {
      'name'     => 'example.tld',
      'reID'     => 'losing-registrar',
      'acDate'   => '2007-12-04T12:24:53.0Z',
      'acID'     => 'gaining-registrar',
      'reDate'   => '2007-11-29T12:24:53.0Z',
      'trStatus' => 'pending'
    };

=cut

sub _transfer_request {
    my ($self, $op, $domain, $new_registrar_id) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Transfer::Domain->new;

    $frame->setOp($op);
    $frame->setDomain($domain);

    if ( $op eq 'request' || $op eq 'query' ) {
        $frame->addAcID($new_registrar_id) if $new_registrar_id;
    }


    # Make request and check response
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }
    elsif ( $op eq 'query' || $op eq 'request' ) {
        my $trnData = $response->getElementsByLocalName('trnData')->shift
            or return;
        my $hash    = {};
        foreach my $child ( $trnData->nonBlankChildNodes ) {
            $hash->{ $child->localName } = $child->textContent;
        }

        return $hash;
    }

    return 1;
}

sub domain_transfer_query {
    return $_[0]->_transfer_request( 'query', $_[1] );
}

sub domain_transfer_cancel {
    return $_[0]->_transfer_request( 'cancel', $_[1] );
}

sub domain_transfer_request {
    return $_[0]->_transfer_request( 'request', $_[1], $_[2] );
}

sub domain_transfer_approve {
    return $_[0]->_transfer_request( 'approve', $_[1] );
}

sub domain_transfer_reject {
    return $_[0]->_transfer_request( 'reject', $_[1] );
}

=pod

=head1 Creating Objects

The following methods can be used to create a new object at the server:

    $epp->create_domain($domain);
    $epp->create_host($host);
    $epp->create_contact($contact);

The argument for these methods is a hash ref of the same format as that
returned by the info methods above. As a result, cloning an existing
object is as simple as the following:

    my $info = $epp->contact_info($contact);

    # set a new contact ID to avoid clashing with the existing object
    $info->{id} = $new_contact;

    # randomize authInfo:
    $info->{authInfo} = $random_string;

    $epp->create_contact($info);

C<Net::EPP::RIPN::Simple> will ignore object properties that it does not recognise,
and those properties (such as server-managed status codes) that clients are
not permitted to set.

=head2 Creating New Domains

When creating a new domain object, you may also specify a C<period> key, like so:

    my $domain = {
        'name'       => 'example.tld',
        'period'     => 2,
        'registrant' => 'contact-id',
        'ns'         => [
             'ns0.example.com',
             'ns1.example.com',
        ],
        'description' => [
            'description line #1',
            'description line #2',
        ],
    };

    $epp->create_domain($domain);

The C<period> key is assumed to be in years rather than months. C<Net::EPP::RIPN::Simple>
assumes the registry uses the host object model rather than the host attribute model.

=cut

sub create_domain {
    my ( $self, $domain ) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Create::Domain->new;

    $frame->setDomain( $domain->{name}   );
    $frame->addPeriod( $domain->{period} ) if $domain->{period};

    my $ns = $domain->{ns};
    if ( $ns && ref $ns eq 'ARRAY' && @$ns) {
        $frame->addNS( @$ns );
    }

    $frame->addRegistrant( $domain->{registrant} ) if $domain->{registrant};

    my $description = $domain->{description};
    if ( $description && ref $description eq 'ARRAY' && @$description ) {

        $frame->addDescription( @$description );
    }

    $frame->addAuthInfo( $domain->{authInfo} ) if $domain->{authInfo};

    # Make request and check response
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }

    return 1;
}

#
# $host_info = {
#   name => 'ns1.example.com',
#   addrs => {
#       'v4' => [ '192.168.0.22', '10.11.134.43' ],
#       'v6' => [ '2001:0DB8:0000:0003:0000:01FF:0000:002E',
#                 '3ffe:1810:0:6:290:27ff:fe79:7677' ],
#   }
# }
#
sub create_host {
    my ( $self, $host ) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Create::Host->new;

    $frame->setHost( $host->{name} );

    for my $type ( keys %{ $host->{addrs} } ) {
        for my $ip ( @{ $host->{addrs}->{$type} } ) {
            $frame->addIP( $ip, $type );
        }
    }

    my $response = $self->request( $frame ) or return;
    
    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return 0;
    }

    return 1;
}

=pod

my $contact_info = {
    id => 'your-contact-id',
    person => {
        intPostalInfo => {
            name    => 'Your Name',
            address => [
                'postal code, Country, City',
                'Street, house',
            ],
        },
        locPostalInfo => {
            name    => 'Ваше Имя',
            address => [
                '0123456, Россия, Москва',
                'ул. Такая-то, д. такой-то'
            ],
        },
        taxpayerNumbers => '11112222233333',
        birthday        => '2010-02-09',
        passport        => [
            '12-45 567-890',
            'blablabla blabla bla' 
        ],
        voice => [ '+7.4951111111', '+7.4952222222' ],
        fax   => [ '+7.4951111111', '+7.4952222222' ], 
        email => [
            'yourmail@example.com',
            'anothermail@example.com'
        ],
    },
    verified => 1, # 0 if unverified
    authInfo => 'contact-password',
};

$epp->create_contact($contact_info);

Creates contact with id 'your-contact-id'.

=cut

sub create_contact {
    my ( $self, $contact ) = @_;

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
        ? $self->_add_person_fields($entity_el, $entity_ref)
        : $self->_add_org_fields($entity_el, $entity_ref);

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

    # Make request and check response
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }

    return 1;
}

sub _add_person_fields {
    my ($self, $entity, $info) = @_;

    $entity->addTaxpayerNumbers( $info->{taxpayerNumbers} )
        if defined $info->{taxpayerNumbers};
    $entity->addBirthday( $info->{birthday} ) if defined $info->{birthday};

    if ( exists $info->{passport} && ref $info->{passport} eq 'ARRAY' ) {
        $entity->addPassport($_) for @{ $info->{passport} };
    }
}

sub _add_org_fields {
    my ($self, $entity, $info) = @_;

    if ( exists $info->{legalInfo} && ref $info->{legalInfo} eq 'HASH' ) {
        my $legal = $info->{legalInfo};
        if ( exists $legal->{address} && ref $legal->{address} eq 'ARRAY' ) {
            $entity->addLegalInfo( @{ $legal->{address} } );
        }
    }

    $entity->addTaxpayerNumbers( $info->{taxpayerNumbers} )
        if defined $info->{taxpayerNumbers};
}


=pod

$epp->update_domain({
    name => 'xn--e1ab8ae4c.xn--p1ai', # жесть.рф
    add => {
        status => [ qw/ clientRenewProhibited / ],
        ns => [ qw/ ns1.hosting.reg.ru / ],
    },
    rem => {
        #status => [ qw/ clientTransferProhibited / ],
        ns => [ qw/ ns1.reg.ru / ],
    },
    chg => {
        registrant  => 'new-registrant-id',
        description => [ 'C00l description line 1',
                         'C00l description line 2',
                         # ...
                       ],
        authinfo    => 'new_password',
    }
});

Update domain's details.

=cut

sub update_domain {
    my ( $self, $domain ) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Update::Domain->new;

    $frame->setDomain( $domain->{name} );

    my $add = exists $domain->{add} ? $domain->{add} : undef;
    if ( defined $add && ref $add eq 'HASH' ) {

        $frame->addNS( @{ $add->{ns} } )
            if exists $add->{ns} && ref $add->{ns} eq 'ARRAY';
        
        $frame->addStatus( @{ $add->{status} } )
            if exists $add->{status} && ref $add->{status} eq 'ARRAY';
    }

    my $rem = exists $domain->{rem} ? $domain->{rem} : undef;
    if ( defined $rem && ref $rem eq 'HASH' ) {

        $frame->remNS( @{ $rem->{ns} } )
            if exists $rem->{ns} && ref $rem->{ns} eq 'ARRAY';

        $frame->remStatus( @{ $rem->{status} } )
            if exists $rem->{status} && ref $rem->{status} eq 'ARRAY';
    }

    my $chg = exists $domain->{chg} ? $domain->{chg} : undef;
    if ( defined $chg && ref $chg eq 'HASH' ) {

        $frame->chgRegistrant( $chg->{registrant} )
            if defined $chg->{registrant};

        $frame->chgDescription( @{ $chg->{description} } )
            if defined $chg->{description}
               && ref $chg->{description} eq 'ARRAY';

        $frame->chgAuthInfo( $chg->{authinfo} )
            if defined $chg->{authinfo};
    }


    # Make request and check response
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }

    return 1;
}

sub update_host {
    my ( $self, $host ) = @_;
    
    my $frame = Net::EPP::RIPN::Frame::Command::Update::Host->new;
    
    $frame->setHost( $host->{name} );

    # Fill 'add' section
    my $add = exists $host->{add} ? $host->{add} : undef;
    if ( defined $add && ref $add eq 'HASH' ) {
        
        if ( defined $add->{addrs} && ref $add->{addrs} eq 'HASH' ) {
            my $addrs = $add->{addrs};
            for my $version ( qw/ v4 v6 / ) {
                if ( $addrs->{$version} && ref $addrs->{$version} eq 'ARRAY' ) {
                    $frame->addIP($_, $version) for @{ $addrs->{$version} };
                }
            }
        }

        if ( defined $add->{status} && ref $add->{status} eq 'ARRAY' ) {
            $frame->addStatus( @{ $add->{status} } );
        }
    }

    # Fill 'rem' section
    my $rem = exists $host->{rem} ? $host->{rem} : undef;
    if ( defined $rem && ref $rem eq 'HASH' ) {
        
        if ( defined $rem->{addrs} && ref $rem->{addrs} eq 'HASH' ) {
            my $addrs = $rem->{addrs};
            for my $version ( qw/ v4 v6 / ) {
                if ( $addrs->{$version} && ref $addrs->{$version} eq 'ARRAY' ) {
                    $frame->remIP($_, $version) for @{ $addrs->{$version} };
                }
            }
        }

        if ( defined $rem->{status} && ref $rem->{status} eq 'ARRAY' ) {
            $frame->addStatus( @{ $rem->{status} } );
        }
    }

    # Fill 'chg' section
    my $chg = exists $host->{chg} ? $host->{rem} : undef;
    if ( defined $chg && ref $chg eq 'HASH' ) {
        
        $frame->chgName( $chg->{name} ) if defined $chg->{name};
    }

    # Make request and check response
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }

    return 1;
}

=pod

    $epp->update_contact({
        id  => 'registrant-contact-id',
        add => {
            status => [ qw/ status1 status2 / ],
        },
        rem => {
            status => [ qw/ status3 / ],
        },
        chg => {
            person => {
                intPostalInfo => {
                    name => 'Your New Name'
                },
                voice => [ '+7.4952223331', '+7.4951112223' ],
            },
            verified => 1,
        },
    });

Updates information of contact 'registrant-contact-id'.

=cut
sub update_contact {
    my ( $self, $contact ) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Update::Contact->new;
    $frame->setContact( $contact->{id} );

    # Add/remove statuses
    if ( defined $contact->{add} ) {
        my $add = $contact->{add};
        if ( defined $add->{status} && ref $add->{status} eq 'ARRAY' ) {
            $frame->addStatus($_) for @{ $add->{status} };
        }
    }

    if ( defined $contact->{rem} ) {
        my $rem = $contact->{rem};
        if ( defined $rem->{status} && ref $rem->{status} eq 'ARRAY' ) {
            $frame->remStatus($_) for @{ $rem->{status} };
        }
    }
 
    if ( exists $contact->{chg} && ref $contact->{chg} eq 'HASH' ) {

        my $chg = $contact->{chg};

        my ($entity_el, $entity_ref, $entity_type);
        if ( exists $chg->{person} && ref $chg->{person} eq 'HASH' ) {
    
            $entity_ref = $chg->{person};
            $entity_el = $frame->chgPerson;
            $entity_type = 'person';
        }
    
        if ( exists $chg->{organization}
            && ref $chg->{organization} eq 'HASH' ) {
    
            $entity_ref = $chg->{organization};
            $entity_el = $frame->chgOrganization;
            $entity_type = 'organization';
        }
    
        if ( defined $entity_type ) {

            # Postal info
            for my $type ( qw/ int loc / ) {
                $entity_el->addTypePostalInfo(
                    $type => $entity_ref->{ $type . 'PostalInfo' }
                ) if $entity_ref->{ $type . 'PostalInfo' };
            }

            $entity_type eq 'person'
                ? $self->_add_person_fields($entity_el, $entity_ref)
                : $self->_add_org_fields($entity_el, $entity_ref);
    
            # Voice, fax, email fields
            for my $field ( qw/ voice fax email / ) {
                $entity_el->addEl($field, $_) for @{ $entity_ref->{$field} };
            }
    
            # Disclose or undisclose elements
            if ( $entity_ref->{disclose} && ref $entity_ref->{disclose} eq 'ARRAY' ) {
                $entity_el->addDisclose( 1, @{ $entity_ref->{disclose} } );
            }
    
            if ( $entity_ref->{undisclose} && ref $entity_ref->{undisclose} eq 'ARRAY' ) {
                $entity_el->addDisclose( 0, @{ $entity_ref->{undisclose} } );
            }
        }
    
        if ( exists $chg->{verified} ) {
            $chg->{verified} ? $frame->setVerified : $frame->setUnverified;
        }
    }
    
    # Make request and check response
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }

    return 1;
}


sub update_registrar {
    my ($self, $registrar) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Update::Registrar->new;
    $frame->setRegistrar( $registrar->{id} );

    if ( exists $registrar->{add} && ref $registrar->{add} eq 'HASH' ) {
        my $add = $registrar->{add};
        
        if ( exists $add->{email} && ref $add->{email} eq 'HASH' ) {
            for my $type ( keys %{ $add->{email} } ) {
                if ( ref $add->{email}->{$type} eq 'ARRAY' ) {

                    $frame->addEmail($_, $type) 
                        for @{ $add->{email}->{$type} };
                }
            }
        }

        if ( exists $add->{addr} && ref $add->{addr} eq 'HASH' ) {
            for my $type ( keys %{ $add->{addr} } ) {
                if ( ref $add->{addr}->{$type} eq 'ARRAY' ) {
                    
                    $frame->addIP($_, $type) for @{ $add->{addr}->{$type} };
                }
            }
        }
    }

    if ( exists $registrar->{rem} && ref $registrar->{rem} eq 'HASH' ) {
        my $rem = $registrar->{rem};

        if ( exists $rem->{email} && ref $rem->{email} eq 'HASH' ) {
            for my $type ( keys %{ $rem->{email} } ) {
                if ( ref $rem->{email}->{$type} eq 'ARRAY' ) {

                    $frame->remEmail($_, $type) 
                        for @{ $rem->{email}->{$type} };
                }
            }
        }

        if ( exists $rem->{addr} && ref $rem->{addr} eq 'HASH' ) {
            for my $type ( keys %{ $rem->{addr} } ) {
                if ( ref $rem->{addr}->{$type} eq 'ARRAY' ) {
                    
                    $frame->remIP($_, $type) for @{ $rem->{addr}->{$type} };
                }
            }
        }
    }

    if ( exists $registrar->{chg} && ref $registrar->{chg} eq 'HASH' ) {
        my $chg = $registrar->{chg};

        if ( exists $chg->{voice} && ref $chg->{voice} eq 'ARRAY' ) {
            $frame->chgVoice( @{ $chg->{voice} } );
        }

        if ( exists $chg->{fax} && ref $chg->{fax} eq 'ARRAY' ) {
            $frame->chgFax( @{ $chg->{fax} } );
        }

        $frame->chgWWW( $chg->{www} ) if $chg->{www};
        $frame->chgWhois( $chg->{whois} ) if $chg->{whois};
    }

    # Make request and check response
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = $self->_get_error($response);
        return;
    }

    return 1;
}

=pod

=head1 Deleting Objects

The following methods can be used to delete an object at the server:

    $epp->delete_domain($domain);
    $epp->delete_host($host);
    $epp->delete_contact($contact);

Each of these methods has the same profile. They will return one of the following:

=over

=item * undef in the case of an error (check C<$Net::EPP::RIPN::Simple::Error> and C<$Net::EPP::RIPN::Simple::Code>).

=item * 1 if the deletion request was accepted.

=back

You may wish to check the value of $Net::EPP::RIPN::Simple::Code to determine whether the response code was 1000 (OK) or 1001 (action pending).

=cut

sub delete_domain {
    my ( $self, $domain ) = @_;
    return $self->_delete( 'domain', $domain );
}

sub delete_host {
    my ( $self, $host ) = @_;
    return $self->_delete( 'host', $host );
}

sub delete_contact {
    my ( $self, $contact ) = @_;
    return $self->_delete( 'contact', $contact );
}

sub _delete {
    my ( $self, $type, $identifier ) = @_;

    my $frame;
    if ( $type eq 'domain' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Delete::Domain->new;
        $frame->setDomain($identifier);
    }
    elsif ( $type eq 'contact' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Delete::Contact->new;
        $frame->setContact($identifier);
    }
    elsif ( $type eq 'host' ) {
        $frame = Net::EPP::RIPN::Frame::Command::Delete::Host->new;
        $frame->setHost($identifier);
    }
    else {
        $Error = "Unknown object type '$type'";
        return;
    }

    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = "Server returned a $Code code";
        return;
    }

    return 1;
}


=pod

=head1 Working with message queue

The following methods can be used to request and acknowledge message in the EPP-RIPN message queue:

    my $message = $epp->poll_req();
    $epp->poll_ack( $message->{id} );

Possible return values are:

=over

=item * undef in the case of an error (check C<$Net::EPP::RIPN::Simple::Error> and C<$Net::EPP::RIPN::Simple::Code>).

=item * $message - text (xml) of the message

=item * 1 - if poll_ack() finished successfully

=back

You may wish to check the value of $Net::EPP::RIPN::Simple::Code to determine whether the response code was 1000 (OK) or 1001 (action pending).

=cut

sub poll_req {
    my ($self) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Poll::Req->new;
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = "Server returned a $Code code after 'poll req' command";
        return;
    }

    my $msg = {};

    my $msgQ = $response->getNode('msgQ')
        or return 0; # no messages

    $msg->{fulltext} = $response->toString(1);    # indented msg text
    $msg->{id}    = $msgQ->getAttribute('id');    #
    $msg->{count} = $msgQ->getAttribute('count'); # count of messages left

    my $trnData = $response->getElementsByLocalName('trnData')->shift
        or return $msg;

    foreach my $child ( $trnData->nonBlankChildNodes ) {
        $msg->{trnData}->{$child->localName} = $child->textContent;
    }
    return $msg;
}

sub poll_ack {
    my ($self, $msg_id) = @_;

    my $frame = Net::EPP::RIPN::Frame::Command::Poll::Ack->new;
    $frame->setMsgID($msg_id);
    my $response = $self->request($frame) or return;

    $Code    = $self->_get_response_code($response);
    $Message = $self->_get_message($response);

    if ( $Code > 1999 ) {
        $Error = "Server returned a $Code code after 'poll ack' command";
        return;
    }

    return 1;
}

=pod

=head1 Miscellaneous Methods

=cut

sub error   { $Error   }
sub code    { $Code    }
sub message { $Message }

=pod

    my $greeting = $epp->greeting;

Returns the a C<Net::EPP::RIPN::Frame::Greeting> object representing the greeting returned by the server.

=cut

sub greeting {
    my $self = shift;
    
    $self->hello if ! $self->{greeting};
    return $self->{greeting};
}

sub ping {
    my $self = shift;

    my $response = $self->hello;

    return $response->isa('XML::LibXML::Document') ? 1 : undef;
}

=pod

=head1 Overridden Methods From C<Net::EPP::RIPN::Client>

C<Net::EPP::RIPN::Simple> overrides some methods inherited from
C<Net::EPP::RIPN::Client>. These are described below:

=head2 The C<request()> Method

C<Net::EPP::RIPN::Simple> overrides this method so it can automatically populate
the C<E<lt>clTRIDE<gt>> element with a unique string. It then passes the
frame back up to C<Net::EPP::RIPN::Client>.

=cut

sub request {
    my ( $self, $frame ) = @_;

    # Make sure we start with blank variables
    $Code    = undef;
    $Error   = '';
    $Message = '';

    # Append clTRID
    $frame->clTRID->appendText( sha1_hex( ref($self) . time() . $$ ) )
        if $frame->isa('Net::EPP::RIPN::Frame::Command');

    # Send request and save last response
    my $response = $self->SUPER::request($frame); 
    $self->{response} = $response;

    # Make request a suitable object
    return defined $response
        ? bless( $response, 'Net::EPP::RIPN::Frame::Response' )
        : $response;
}

sub _get_response_code {
    my ( $self, $doc ) = @_;

    my $els = $doc->getElementsByTagNameNS( EPP_XMLNS, 'result' );
    if ( defined($els) ) {
        my $el = $els->shift;
        if ( defined($el) ) {
            return $el->getAttribute('code');
        }
    }
    return COMMAND_FAILED;
}

sub _get_message {
    my ( $self, $doc ) = @_;

    my $msgs = $doc->getElementsByTagNameNS( EPP_XMLNS, 'msg' );
    if ( defined($msgs) ) {
        my $msg = $msgs->shift;
        if ( defined($msg) ) {
            return $msg->textContent;
        }
    }
    return '';
}

sub _get_error {
    my ( $self, $response ) = @_;

    my $message = $response->msg;
    my $reason  = $response->reason;

    return $reason ? $message
                   : "$message: $reason";
}

sub logout {
    my $self = shift;

    if ( $self->{authenticated} ) {

        $self->debug('setting session cookie params');
        $self->browser->cookie_jar->set_cookie(
            @{ $self->{session_cookie_params} }
        );
        $self->debug('logging out');
        my $response = $self->request(
            Net::EPP::RIPN::Frame::Command::Logout->new
        );
       if ( !$response) {
           $self->debug("EMPTY RESPONSE FOR LOGOUT!");
           return;
       }
    }
    $self->debug("logged out");
    $self->{connected} = 0;
    return 1;
}

sub DESTROY {
    my $self = shift;

    $self->debug('DESTROY() method called');
    $self->logout if $self->{connected};
}

sub debug {
    my ( $self, $msg ) = @_;

    $msg = sprintf( "%s (%d): %s\n", scalar( localtime() ), $$, $msg );

    print STDERR $msg if $self->{debug};
}

=pod

=head1 Package Variables

=head2 $Net::EPP::RIPN::Simple::Error

This variable contains an english text message explaining the last error
to occur. This is may be due to invalid parameters being passed to a
method, a network error, or an error response being returned by the
server.

=head2 $Net::EPP::RIPN::Simple::Message

This variable contains the contains the text content of the
C<E<lt>msgE<gt>> element in the response frame for the last transaction.

=head2 $Net::EPP::RIPN::Simple::Code

This variable contains the integer result code returned by the server
for the last transaction. A successful transaction will always return an
error code of 1999 or lower, for an unsuccessful transaction it will be
2000 or more. If there is an internal client error (due to invalid
parameters being passed to a method, or a network error) then this will
be set to 2400 (C<COMMAND_FAILED>). See L<Net::EPP::RIPN::ResponseCodes> for
more information about these codes.

=head1 AUTHOR

Ilya Chesnokov <L<chesnokov.ilya@gmail.com>)

=head1 COPYRIGHT

Copyright (c) 2009-2010, Ilya Chesnokov.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Net::EPP::RIPN::Client>

=item * L<Net::EPP::RIPN::Frame>

=item * RFCs 5730 and RFC 5734, available from L<http://www.ietf.org/>.

=item * EPP-RIPN protocol specification (in Russian) at L<http://www.tcinet.ru/content/documents>.

=back

=cut

1;
