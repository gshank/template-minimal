use strict;
use warnings;
use Test::More;

use_ok('Template::Minimal');
use_ok('Template::Minimal::Stash');
{
    package Test::Trait;
    use Moose;
    with 'Template::Minimal::Trait';
}
ok( Test::Trait->new, 'Template::Minimal::Trait compiles ok' );

done_testing;
