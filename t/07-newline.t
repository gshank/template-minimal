
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Differences;

use_ok('Template::Minimal');
use aliased 'Template::Minimal::Stash';

my $tm = Template::Minimal->new();

my $compiled = $tm->compile(
    [[ TEXT => 'Newline' ], [ NEWLINE => 1 ]],
);
my $expected =
'sub {
  my ($stash) = @_;
  my $out;
  $out .= \'Newline\';
  $out .= "\n";
}
';
is( $compiled, $expected, 'newline compiles' );
my $coderef = eval($compiled);
ok( $coderef, 'newline evals ok');
my $out = $coderef->();
is($out, "Newline\n", 'newline executes ok');

my $template = "First line [% name %]
another line
[% email %]
last line [% done %]
";

my $ast = $tm->parse($template);

ok( $ast, 'parsed ok');
my $optimized = $tm->_optimize($ast);

done_testing;
