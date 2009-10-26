use strict;
use warnings;
use Test::More;

{
    package Test::Inline;
    use Moose;
    with 'Template::Snippets::TraitFor::Inline';

    sub render {
        my $self = shift;
        my $var = 'Test';
        my $name = 'Bob';
        return tm( 'This is a [% var %], [% name %].' );
    }
}

my $tester = Test::Inline->new;
ok( $tester, 'compiled ok' );
is( $tester->render, 'This is a Test, Bob.', 'renders ok' );

done_testing;
