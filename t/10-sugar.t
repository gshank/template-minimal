use strict;
use warnings;
use Test::More;

{
    package Test::Sugar;
    use Template::Snippets::Sugar;

    has 'name' => ( is => 'ro', default => 'Test' );
    snippet 'foo' => ( template => 'Hello, World!' );
    snippet 'bar' => ( template => '[% foo %][% bar %]' );
}

my $tester = Test::Sugar->new;
ok( $tester, 'compiled ok' );
ok( $tester->meta->has_snippets, 'has templates' );
is( $tester->meta->get_snippet('foo')->{template}, 'Hello, World!', 'got template');

{
    package Test::With::Sugar;
    use Template::Snippets::Sugar;
    with 'Template::Snippets::TraitFor::Collection';

    has 'name' => ( is => 'ro', default => 'TestWith' );
    snippet 'foo' => ( template => 'Hello, World!' );
    snippet 'bar' => ( template => '[% foo %], [% bar %]!' );

    sub render_bar {
        my $self = shift;
        my $foo = 'Hello';
        my $bar = 'World';
        return $self->tmpl('bar', vars()); 
    }
}
$tester = Test::With::Sugar->new;
ok( $tester, 'compiled ok' );
ok( $tester->meta->has_snippets, 'has snippets' );
is( $tester->meta->get_snippet('foo')->{template}, 'Hello, World!', 'got template');
ok( $tester->has_template('foo'), 'template has been added' );
is( $tester->render_bar, 'Hello, World!', 'renders bar' );


done_testing;
