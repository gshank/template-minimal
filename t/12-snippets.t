use strict;
use warnings;
use Test::More;

use lib ('t/lib');

{
    package Test::Page;
    use Moose;
    with 'Template::Test';
    with 'Template::Snippets::TraitFor::Collection';

    sub render {
        my $self = shift;
        return $self->tmpl('main', { page_title => 'Testing Snippets',
            name => 'Gerda'} );
    }
}

my $tester = Test::Page->new;
ok( $tester, 'obj created' );
my $expected = '
    <html>
      <header>
      </header>
      <body>
      <h1>Testing Snippets</h1>
      
    <div class="page">
    <h2>This is a test of template snippets</h2>
      <div class="section">
        
    <p>Four score and seven years ago our fathers brought forth upon this
       continent a new nation conceived in liberty and dedicated to the
       proposition that all men are created equal. We are now engaged in
       a great civil war, testing whether that nation or any nation so
       conceived and so dedicated can long endure.
    </p>
        
    <h3>Hello, Gerda!</h3>
      </div>
    </div>
      </body>
    </html>';
is( $tester->render, $expected, 'renders ok' );

done_testing;
