use strict;
use warnings;
use Test::More;

use_ok('Template::Snippets');
use_ok('Template::Snippets::Stash');
{
    package Test::Collection::Trait;
    use Moose;
    with 'Template::Snippets::TraitFor::Collection';
}
ok( Test::Collection::Trait->new, 'Template::Snippets::TraitFor::Collection compiles ok' );
{ 
    package Test::Inline::Trait;
    use Moose;
    with 'Template::Snippets::TraitFor::Inline';
}
ok( Test::Inline::Trait->new, 'Template::Snippets::TraitFor::Inline compiles ok' );

done_testing;
