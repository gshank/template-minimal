use strict;
use warnings;

use Test::More;
use Test::Deep;

use Template::Minimal;
use aliased 'Template::Minimal::Stash';

my $tm = Template::Minimal->new;


# concat variables
my $template = "[% foo %][% bar %]";
my $ast = $tm->parse($template);
my $optimized = $tm->_optimize($ast);
my $code_str = $tm->compile($optimized);

$template = "[% ref.foo %]";
my $vars = { ref => { foo => 'bar' } };
my $output = $tm->process_string($template, $vars);
is( $output, "bar", 'output ok');

$template = "This is not a very 'fair' outcome";
$ast = $tm->parse($template);
$optimized = $tm->_optimize($ast);
$code_str = $tm->compile($optimized);
ok( $code_str, 'compiled' );
my $code_ref = eval($code_str);
ok( $code_ref, 'got coderef' );
$output = $code_ref->();
ok( $output, 'got output' );


$template = 'The quick brown fox [% name | escape_html %]
[% FOREACH foo IN foos %][% foo.hehe %][% END %]';

my $expected = [
    [TEXT => 'The quick brown fox '],
    [VARS => ['name', 'escape_html']],
    [NEWLINE => 1],
    [FOREACH => ['foo', 'foos']],
    [VARS => ['foo.hehe']],
    ['END'],
];

$ast = $tm->parse($template);
cmp_deeply($ast, $expected, 'parsed template');
$optimized = $tm->_optimize($ast);



done_testing;
