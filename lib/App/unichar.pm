#!perl

package App::unichar;

use 5.026;
use utf8;
use warnings;

our $VERSION = '0.012';

=encoding utf8

=pod

=head1 NAME

App::unichar - get info about a character

=head1 SYNOPSIS


=head1 DESCRIPTION

I use this as a little command-line program to quickly convert between
values of characters.

=head1 AUTHOR

brian d foy, C<bdfoy@cpan.org>.

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/unichar

=head1 COPYRIGHT & LICENSE

Copyright 2011-2018 brian d foy

This module is licensed under the Artistic License 2.0.

=cut

use Encode qw(decode);
use I18N::Langinfo qw(langinfo CODESET); 

use charnames ();
use List::Util;

binmode STDOUT, ':utf8';

my %r = (
	u => qr/(?:U\+?(?<hex>[0-9A-F]+))/i,
	h => qr/(?:0x(?<hex>[0-9A-F]+))/i,
	d => qr/(?:(?<int>[0-9]+))/,
	);

my %transformation = (
	'hex' => sub { hex $_[0] },
	'int' => sub { $_[0] },
	);

my $codeset = langinfo(CODESET);
@ARGV = map { decode $codeset, $_ } @ARGV;

foreach ( @ARGV ) {
	say "Processing $_";
	my( $code, $match );

	when( / \A (?: $r{u} | $r{h} | $r{d} ) \z /x ) {
		$match = 'code point';
		my( $key ) = keys %+;
		$code = $transformation{$key}( $+{$key} );		
		continue;
		}
	when( / \A ([A-Z\s]+) \z /ix ) {
		$match = 'name';
		$code = charnames::vianame( uc($1) );
		continue;
		}
	when( / \A (\X) \z /x ) {
		$match = 'grapheme';
		$code = ord( $1 );
		continue;
		}
	default {
		unless( $code ) {
			say "\tInvalid character or codepoint --> $_\n";
			next;
			}

		my $hex  = sprintf 'U+%04X', $code;
		my $char = chr( $code );
		$char = '<unprintable>' if $char !~ /\p{Print}/;
		$char = '<whitespace>'  if $char =~ /\p{Space}/;
		$char = '<control>'     if $char =~ /\p{Control}/;

		my $name = charnames::viacode( $code ) // '<no name found>';

		print <<~"HERE";
			match type  $match
			code point  $hex
			decimal     $code
			name        $name
			character   $char

		HERE

		}
	}

