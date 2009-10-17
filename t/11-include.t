use strict;
use warnings;
use Test::More;

use Template::Minimal;
use aliased 'Template::Minimal::Stash';

my $tm = Template::Minimal->new;
$tm->add_template('hello', 'Hello, [% name %]!' );

my $template = 'Test: [% INCLUDE hello %] strikes again. [% foo %]'; 
my $ast = $tm->parse($template);
my $optimized = $tm->_optimize($ast);
my $code_str = $tm->compile($optimized);
my $stash = Stash->new({ foo => 'Yay!', name => 'Snowflake' }); 
my $coderef = eval( $code_str );
ok( $coderef, 'got coderef' );
my $out = $coderef->($tm, $stash);
is( $out, 'Test: Hello, Snowflake! strikes again. Yay!', 'got output from coderef');

done_testing;
