use strict;
use warnings;
use Test::More;

use Template::Minimal;
use Template::Minimal::String ('tm', 'strip');
use utf8;

is( a(), 'foobar', 'foobar works');

like( b(), qr/SCALAR/, "references aren't dereferenced");

is( c(), 'A::foo', 'methods work' );

is( d(), 'foo foo bar 1', 'arrays and hashes work' );
is( e(), 'array foo_a', 'nothing overwritten' );

is( f(), "Foo maps to bar!\n", 'references and strip work' );

is( utf_eight(), "ほげぼげ", 'utf8 works' );
is( length utf_eight(), 4, 'utf8 works not by coincidence' );

sub a {
    my $foo = 'foo';
    my $bar = 'bar';
    return tm( '[% foo %][% bar %]' );
}

sub b {
    my $foo = \'reference';
    return tm( '[% foo %]' );
}

{
    sub A::foo { return 'A::foo' }
    
    sub c {
        my $a = bless { foo => 'bar' } => 'A';
        return tm( '[% a.foo %]' );
    }
}

sub d {
    my $foo = 'foo';
    my @bar = qw/bar/;
    my %baz = ( baz => 1 );
    return tm( '[% foo %] [% foo_s %] [% bar_a.0 %] [% baz_h.baz %]' );
}

sub e {
    my $foo_a = 'foo_a';
    my @foo = qw/array/;
    return tm( '[% foo_a.0 %] [% foo_a_s %]' );
}

sub f {
    my $ref = { foo => 'bar' };
    return strip( tm( q{
        Foo maps to [% ref.foo %]!
    }));
}


sub utf_eight {
    my $hoge = "ほげ";
    return tm( "[% hoge %]ぼげ" );
}

done_testing;
