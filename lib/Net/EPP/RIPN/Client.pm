package Net::EPP::RIPN::Client;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use XML::LibXML;
use Data::Dumper;

=head1 NAME

Net::EPP::RIPN::Client - HTTP(S) client for EPP-RIPN protocol

=cut

our $UA_STRING = "EPP-RIPN Perl client";

=head1 SYNOPSIS

    use Net::EPP::RIPN::Client;
    use Net::EPP::RIPN::Frame;

    # Create client object
    my $client = Net::EPP::RIPN::Client->new(
        host => $host,
        port => $port,
        user => $user,
        pass => $password,
        timeout     => 20,
        # Save cookies to file instead of object's memory
        cookie_file => '/home/your_name/ripn_cookies.txt',
    );

    # Create command frame
    my $cmd_info = Net::EPP::RIPN::Frame::Command::Domain::Info->new("example.su");
    # Make request
    my $info = $client->request($cmd_info);
    # Print answer
    print $info->toString(1);

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

Net::EPP::RIPN::Client->new(
    host    => 'uaptest.ripn.net',
    port    => 7029,
    timeout => 15,
);

IN:
    required params: host, port
    optinal params: 
        browser     - HTTP(S) browser object. Should be an LWP::UserAgent object or it's descendant.
        cookie_file - Where to save cookies. By default cookies are stored in memory.
        timeout     - request timeout
        pkcs12_file - full path to client certificate in the PKCS12 format
        pkcs12_pass - password of PKCS12 certificate file
=cut

sub new {
    my ($class, %params) = @_;
    
    my $self = {};

    # Check and set required params
    my @required_params = qw( host port );

    $class->_check_required_params( \@required_params, \%params );

    bless($self, $class);

    # Move parameters to client instance
    @{$self}{@required_params} = @params{@required_params};

    # Set url. Default scheme is 'https', but maybe it'll be optinal later
    $self->{url} = "https://$self->{host}:$self->{port}";

    ## Optional params

    # Request timeout, default 10s
    $self->{timeout} = $params{timeout} || 10;
    if ( $params{browser} ) {
        $self->browser( $params{browser} );
    }

    # File to save cookies
    if ( $params{cookie_file} ) {
        $self->browser->cookie_jar(
            HTTP::Cookies->new(
                file           => $params{cookie_file},
                ignore_discard => 1,
            )
        );
    }

    # Local address to send requests from
    if ( $params{local_address} ) {
        $self->{local_address} = $params{local_address};
        $self->browser->local_address( $params{local_address} );
    }

    # SSL client certificate (PKCS12 format)
    if ( defined $params{pkcs12_file} ) {
        if ( -f $params{pkcs12_file} ) {
            $self->{pkcs12_file} = $params{pkcs12_file};
        }
        else {
            croak "File '$params{pkcs12_file}' does not exist!";
        }
    }
    if ( defined $params{pkcs12_pass} ) {
        $self->{pkcs12_pass} = $params{pkcs12_pass};
    }
    
    $self->{verbose} = $params{verbose} ? 1 : 0;

    # Set up XML parser
    $self->{parser} = XML::LibXML->new;

    $self->{class}  = $params{dom}
        ? 'XML::LibXML::Document'
        : 'Net::EPP::RIPN::Frame';

    return $self;
}

#
sub _check_required_params {
    my ($self, $required_params_list, $params_hash) = @_;

    for my $param ( @$required_params_list ) {
        croak "Required parameter '$param' missing or undefined"
            unless exists $params_hash->{$param}
                && defined $params_hash->{$param};
    }
}

=head2 browser

Get/set HTTP(S) browser object, associated with client instance.

=cut

sub browser {
    my ($self, $new_browser) = @_;

    if ( defined $new_browser && ref $new_browser ) {
        croak "Tried to use browser, which doesn't support request() method"
            unless $new_browser->can('request');
        
        $self->{browser} = $new_browser;
    }

    if ( !$self->{browser} ) {
        $self->debug('using default browser as current');
        $self->{browser} = $self->_default_browser;
    }

    return $self->{browser};
}

# Old good LWP::UserAgent
sub _default_browser {
    my ($self) = @_;

    my $browser = LWP::UserAgent->new(
        agent      => $UA_STRING,
        parse_head => 0,
        timeout    => $self->{timeout},
        cookie_jar => $self->{cookie_jar} || $self->_default_cookie_jar,
    );

    return $browser;
}


# Temporary cookie store, lives during object is alive
sub _default_cookie_jar {
    my ($self) = @_;
    
    return HTTP::Cookies->new();
}

=head2 connect

Uses HEAD request to get session cookies.

=cut

sub connect {
    my ($self) = @_;

    # Pass certificate to Crypt::SSLeay
    local $ENV{HTTPS_PKCS12_FILE}     = $self->{pkcs12_file}
        if $self->{pkcs12_file};
    local $ENV{HTTPS_PKCS12_PASSWORD} = $self->{pkcs12_pass}
        if $self->{pkcs12_pass};

    $self->debug("sending HEAD request to $self->{url}");
    my $request = HTTP::Request->new( HEAD => $self->{url} );
    my $response = $self->browser->request($request);

    $self->debug("got headers: [\n" . $response->headers->as_string . "]" );
    $self->debug("got cookies: '" . $self->browser->cookie_jar->as_string . "'" );

    $self->_check_response_headers($response);
    return 1;
}

sub _check_response_headers {
    my ($self, $response) = @_;

    croak 'Invalid HTTP::Response: ' . Dumper( $response )
        unless $response && $response->isa('HTTP::Response');

    my $code = $response->code;
    croak "Invalid response code: $code\n"
        unless $code == 200;

    my $headers = $response->headers;

    my $length = $headers->content_length;
    croak "Content-Length must be > 0\n"
        unless $length && $length > 0;

    my $type = $headers->content_type;
    croak "Content-Type must be 'text/xml'\n"
        unless $type && $type eq 'text/xml';

    my $charset = $headers->content_type_charset;
    croak "Charset must be UTF-8\n"
        unless $charset && uc($charset) eq 'UTF-8';

    return 1;
}

=head2 request

Send request to EPP-RIPN host

my $login = Net::EPP::RIPN::Frame::Command::Login->new(
    clID => 'TEST1-REG-RF',
    pw   => 'test-password',
    version => $version,
    lang    => $lang,
    objURIs => \@obj_uris,
);
$client->request($login);

=cut

sub request {
    my ($self, $frame) = @_;

    
    croak "Frame is required and must be an XML::LibXML::Document\n"
        unless $frame && $frame->isa('XML::LibXML::Document');

    $self->debug( "sending frame\n" . $frame->toString(1) );
    # Construct request
    my $request = HTTP::Request->new( 'POST' => $self->{url} );
    $request->content_type('text/xml');
    $request->content_type_charset('UTF-8');
    $request->content( $frame->toString(1) );

    # Pass certificate to Crypt::SSLeay
    local $ENV{HTTPS_PKCS12_FILE}     = $self->{pkcs12_file}
        if $self->{pkcs12_file};
    local $ENV{HTTPS_PKCS12_PASSWORD} = $self->{pkcs12_pass}
        if $self->{pkcs12_pass};

    # Send request
    my $response = $self->browser->request($request);

    my $cookies = $self->browser->cookie_jar->as_string;
    $self->debug("response cookies: '$cookies'");

    if ( !$response ) {
        $self->debug("response is undefined");
        return;
    }
    elsif ( !$response->is_success ) {
        $self->debug("response is bad, status_line: " . $response->status_line );
        return;
    }
    else {
        #$self->debug("got response: " . $response->content);

        my $document = $self->get_return_value($response->content);

        if ( $document && $document->isa('XML::LibXML::Document') ) {
            $self->debug( "got response:\n" . $document->toString(1) );
        }
        else {
            $self->debug( "got response: " . Dumper( $document ) );
        }

        return $document;
    };
}

# Parse response content and return EPP-RIPN Response object here
sub get_return_value {
    my ($self, $xml) = @_;

    if ( ! defined $self->{class} ) {
        return $xml;
    }

    my $document = eval {
        $self->{parser}->parse_string($xml) 
    };

    if ( !defined $document ) {
        $self->debug("Could not parse server response: $@");
        croak "Could not parse server response: $@";
    }
    
    my $class = $self->{class};

    return bless( $document, $class );
}

sub debug {
    my ($self, $msg) = @_;

    print ref($self) . "::$msg\n" if $self->{verbose};
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

1; # End of Net::EPP::RIPN::Client
