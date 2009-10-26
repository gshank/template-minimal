use strict;
use warnings;
use Test::More;

{
    package Test::Snippets;
    
    use Template::Snippets::Sugar;
    with 'Template::Snippets::TraitFor::Collection';

    snippet 'foo' => ( string => '<h1>This is Foo</h1>' );

    snippet 'bar' => ( template => 'What a [% bar %]!' );

    snippet 'baz' => ( file => 'baz.tmpl' );

    snippet 'quux' => ( coderef => sub { 
            my ($ctx, $stash) = @_;
            return 'a coderef';
        });

    snippet 'fox' => ( tt_template => 'This is a TT template. [% foo _ bar %]]' );

    snippet 'bax' => ( tt_file => 'bax.tt' );

}


my $tester = Test::Snippets->new;
ok( $tester, 'compiles ok' );


done_testing;
