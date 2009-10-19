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

$template = "This is not a very 'fair' outcome.
[% testing %]";
$ast = $tm->parse($template);
$optimized = $tm->_optimize($ast);
$code_str = $tm->compile($optimized);
ok( $code_str, 'compiled' );
my $coderef = eval($code_str);
ok( $coderef, 'got coderef' );
my $stash = Stash->new( {testing => 'Yes'});
$output = $coderef->($tm, $stash);
ok( $output, 'got output' );

$template = 'This is not a very \'fair\' outcome.
[% testing %] [% INCLUDE something %]';
$ast = $tm->parse($template);
$optimized = $tm->_optimize($ast);
$code_str = $tm->compile($optimized);
ok( $code_str, 'compiled' );
$coderef = eval($code_str);
ok( $coderef, 'got coderef' );
$output = $coderef->($tm, $stash);
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

$template = "[% IF max EQ foo %]";
$ast = $tm->parse($template);
$expected = [[ IF_EQ => [[ VARS => ['max']], [ VARS => ['foo']]]]];
cmp_deeply($ast, $expected, 'parsed if eq' );
$template = "[% IF max EQ 'foo' %]";
$ast = $tm->parse($template);
$expected = [[ IF_EQ => [[ VARS => ['max']], [ TEXT => 'foo']]]];
cmp_deeply($ast, $expected, 'parsed if eq with text');

$code_str = $tm->compile(
    [[ IF_EQ => [[ VARS => ['max']], [ TEXT => 'foobar']]], [ TEXT => 'Greetings'],[ 'END' ]],
);
$expected = 
'sub {
  my ($ctx, $stash) = @_;
  my $out;
  if ( $stash->get(\'max\') eq \'foobar\' ) {
  $out .= \'Greetings\';
  }
  return $out;
}
';
is( $code_str, $expected, 'text compiles' );
$coderef = eval($code_str);
ok( $coderef, 'text evals ok');
$stash = Stash->new({max => 'foobar'});
$output = $coderef->($tm, $stash);
is( $output, "Greetings", 'text executes ok');


done_testing;
