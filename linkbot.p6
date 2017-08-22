#!/usr/bin/env perl6

use Net::IRC::Bot;
use Net::IRC::Modules::Autoident;
use Net::HTTP::GET;
use HTML::Entity;

constant Autoident = Net::IRC::Modules::Autoident;
constant GET = Net::HTTP::GET;

# The nickname to use.
my Str $NICK = "linkbot";
# Add each channel to join, in quotes, separated by commas.
my @CHANNELS = (
    "#somechannel",
    "#someotherchannel",
);
my Str $SERVER = "chat.freenode.net";
my Str $NS_PASS = "changeme";

my @blacklist = (
    # Block .onion sites
    / "http" s? "://" \S+ ".onion" / ,
);

my @whitelist = (
    # Always allow Youtube sites
    / "http" s? "://" "www."? "youtube.com" / ,
    / "http" s? "://" "www."? "youtu.be" / ,
);

##############################################################################
#                 Proceed with caution if you don't plan on updating the bot #
##############################################################################

my Regex $url-regex = / \w+ \:\/\/ \S+ /;

sub msg-matches(Str $msg) returns Bool {
    ($msg ~~ $url-regex && !($msg ~~ @blacklist.any)) || $msg ~~ @whitelist.any;
}

sub get-url-title(Str $url) returns Str {
    my $response = GET($url);
    if $response.header<Content-Type>[0] ~~ / "text/html" / and $response.content ~~ / "<title>" .+ "</title>" / {
        "$/".substr(7, *-8).trim;
    }
    else { ""; }
}

class LinkRecording {
    # Called whenever someone says something
    multi method said ($e where { msg-matches .what }) {
        my $url = ($e.what ~~ $url-regex) && $/;
        try {
            my $title = get-url-title "$url";
            $e.msg(decode-entities $title) if $title;
        }
    }
}

Net::IRC::Bot.new(
    nick        => $NICK,
    server      => $SERVER,
    channels    => @CHANNELS,
    modules     => (
        LinkRecording.new(),
        Autoident.new(password => $NS_PASS) if $NS_PASS
    ),
).run;
