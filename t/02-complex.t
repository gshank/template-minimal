use strict;
use warnings;

use Test::More;
use Test::Deep;

use Template::Minimal;

my $tt = Template::Minimal->new;

my $tpl = 'The quick brown fox [% name | escape_html %]
[% FOREACH foo IN foos %][% foo.hehe %][% END %]';

my $ast = [
    [TEXT => 'The quick brown fox '],
    [VARS => ['name', 'escape_html']],
    [NEWLINE => 1],
    [FOREACH => ['foo', 'foos']],
    [VARS => ['foo.hehe']],
    ['END'],
];

my $got = $tt->parse($tpl);
cmp_deeply($got, $ast, 'parsed template');
my $optimized = $tt->_optimize($got);



done_testing;
