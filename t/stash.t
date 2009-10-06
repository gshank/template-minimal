use strict;
use warnings;
use Test::More;

use_ok('Template::Minimal::Stash');

use aliased 'Template::Minimal::Stash';

my $stash = Stash->new();
isa_ok($stash, 'Template::Minimal::Stash');

$stash = Stash->new({ a => 1,  });
is( $stash->get('a'), 1, 'Basic stash retrieval');

$stash = Stash->new( { options => { bar => 'first', baz => 'second' } } );
ok( $stash, 'stash with arrayref' );
is( $stash->get('options.bar' ), 'first', 'get value for options->{bar}');

{
    package Test::Obj;
    use Moose;
    has 'bar' => ( is => 'rw' );
    has 'foo' => ( is => 'rw' );
}
my $obj = Test::Obj->new(bar => 'abc', foo => 'xyz');
$stash = Stash->new({ obj => $obj});
is( $stash->get('obj.foo'), 'xyz', 'get value for obj->foo' );

$stash = Stash->new( { names => ['Bob', 'Bill'] } ); 
ok( $stash, 'stash with array' );
is_deeply( $stash->get('names'), ['Bob', 'Bill'], 'get array from stash'); 



done_testing;
