use strict;
use warnings;
use Test::More;

{
    package Test::Sugar;
    use Template::Minimal::Sugar;

    has 'name' => ( is => 'ro', default => 'Test' );
    template 'foo' => ( string => 'Hello, World!' );
    template 'bar' => ( string => '[% foo %][% bar %]' );
}

my $tester = Test::Sugar->new;
ok( $tester, 'compiled ok' );
ok( $tester->meta->has_templates, 'has templates' );
is( $tester->meta->get_template('foo')->{string}, 'Hello, World!', 'got template');

{
    package Test::With::Sugar;
    use Template::Minimal::Sugar;
    with 'Template::Minimal::Trait';

    has 'name' => ( is => 'ro', default => 'TestWith' );
    template 'foo' => ( string => 'Hello, World!' );
    template 'bar' => ( string => '[% foo %], [% bar %]!' );

    sub render_bar {
        my $self = shift;
        my $foo = 'Hello';
        my $bar = 'World';
        return $self->tmpl('bar', vars()); 
    }
}
$tester = Test::With::Sugar->new;
ok( $tester, 'compiled ok' );
ok( $tester->meta->has_templates, 'has templates' );
is( $tester->meta->get_template('foo')->{string}, 'Hello, World!', 'got template');
ok( $tester->has_template('foo'), 'template has been added' );
is( $tester->render_bar, 'Hello, World!', 'renders bar' );


done_testing;
