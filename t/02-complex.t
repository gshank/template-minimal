use strict;
use warnings;

use Test::More;
use Test::Deep;

use Template::Minimal;
use aliased 'Template::Minimal::Stash';

my $tm = Template::Minimal->new;


# concat variables
my $template = "[% foo %][% bar %]";
my $got = $tm->parse($template);
my $optimized = $tm->_optimize($got);
my $code_str = $tm->compile($optimized);

$template = "[% ref.foo %]";
my $vars = { ref => { foo => 'bar' } };
my $output = $tm->process_string($template, $vars);
is( $output, "bar", 'output ok');


$template = 'The quick brown fox [% name | escape_html %]
[% FOREACH foo IN foos %][% foo.hehe %][% END %]';

my $ast = [
    [TEXT => 'The quick brown fox '],
    [VARS => ['name', 'escape_html']],
    [NEWLINE => 1],
    [FOREACH => ['foo', 'foos']],
    [VARS => ['foo.hehe']],
    ['END'],
];

$got = $tm->parse($template);
cmp_deeply($got, $ast, 'parsed template');
$optimized = $tm->_optimize($got);



done_testing;
