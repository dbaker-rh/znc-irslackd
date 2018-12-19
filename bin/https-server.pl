#!/usr/bin/env perl

# *REALLY* simple httpd server to feed error messages
# based on https://metacpan.org/pod/HTTP::Daemon::SSL
#
# It turns out that this can't actually be used because 
# the readiness probe will never pass if it's running, and
# we don't want the readiness to pass in an error condition.
#

use HTTP::Daemon::SSL;
use HTTP::Status;

my $d = HTTP::Daemon::SSL->new(
          LocalAddr => '0.0.0.0',
          LocalPort => 7776,
          SSL_cert_file => '/tmp/cert.pem',
          SSL_key_file =>  '/tmp/pkey.pem',
        ) || die;


# Arg 1 is a path to a single HTML file to feed
$html = shift || die "Usage: $0 filename.html";
$html =~ /.*\.html$/ || die "Usage: $0 filename.html - filename must end .html";
-e $html || die "Usage: $0 filename.html - filename must exist";


print "Simple https-server.pl running for $html at: ", $d->url, "\n";


while (my $c = $d->accept) {
    while (my $r = $c->get_request) {
        # TODO: support sending other static content like images/css for prettier error messages
        if ($r->method eq 'GET' and $r->url->path eq "/") {
            $c->send_file_response( $html );

        } else {
            $c->send_error(RC_FORBIDDEN)
        }
    }
    $c->close;
    undef($c);
}


