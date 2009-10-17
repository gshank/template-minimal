use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Differences;

use_ok('Template::Minimal');
use aliased 'Template::Minimal::Stash';

my $tm = Template::Minimal->new();

my $compiled = $tm->compile(
    [[ TEXT => 'Hello, world!' ]],
);
my $expected = 
'sub {
  my ($ctx, $stash) = @_;
  my $out;
  $out .= \'Hello, world!\';
  return $out;
}
';
is( $compiled, $expected, 'text compiles' );
my $coderef = eval($compiled);
ok( $coderef, 'text evals ok');
my $out = $coderef->();
is( $out, "Hello, world!", 'text executes ok');

$compiled = $tm->compile(
    [[ TEXT => 'Newline' ], [ NEWLINE => 1 ]],
);
$expected =
'sub {
  my ($ctx, $stash) = @_;
  my $out;
  $out .= \'Newline\';
  $out .= "\n";
  return $out;
}
';
is( $compiled, $expected, 'newline compiles' );
$coderef = eval($compiled);
ok( $coderef, 'newline evals ok');
$out = $coderef->();
is($out, "Newline\n", 'newline executes ok');

$compiled = $tm->compile(
    [[ VARS => ['George'] ]],
);
$expected =
'sub {
  my ($ctx, $stash) = @_;
  my $out;
  $out .= $stash->get(\'George\');
  return $out;
}
';
is( $compiled, $expected, 'variable compiles');

$compiled = $tm->compile(
    [[ FOREACH => ['blog', "blogs" ]], [ 'END' ]],
);

$expected = 
'sub {
  my ($ctx, $stash) = @_;
  my $out;
  foreach my $blog ( @{$stash->get(\'blogs\')} ) {
    $stash->set_var(\'blog\', $blog);
  }
  return $out;
}
';

is( $compiled, $expected, 'foreach compiles');

$tm = Template::Minimal->new();

my $concat = $tm->parse("[% foo %][% bar %]" );
parse_check('[% name %]', [[ VARS => ['name'] ]], 'variable parses');

parse_check(
    'hhhmmm.... [% haha %]', 
    [[ TEXT => 'hhhmmm.... ' ], [ VARS => ['haha'] ]], 
    'text plus var parses'
);

parse_check(
    '[% one_two %] bubba',
    [ [VARS => ['one_two'] ], [TEXT => ' bubba'] ],
    'var plus text parses'
);

parse_check(
    '[% value | filter1 | filter2 %]', 
    [[ VARS => ['value', 'filter1', 'filter2'] ]], 
    'filters'
);

parse_check(
    "[% INCLUDE 'hehe.html' %]",
    [[ INCLUDE => 'hehe.html' ]],
    'include'
);

sub parse_check {
    my ($tpl, $ast, $cmt) = @_;
    my $got = $tm->parse($tpl);
    cmp_deeply($got, $ast, $cmt);
}

basic: {
    my $stash = Stash->new({ name => 'Perl Hacker', title => 'paper', });
    my $tm = Template::Minimal->new({ include_path => ['t/tmpl'], });
    my $out = $tm->process_file('foo.tpl', $stash);
    my $expected = <<'END';

Hi Perl Hacker,

This is my paper


END
    is( $out, $expected, 'process file');
}


gigo: {    
    my $stash = Stash->new({
        name => 'Perl Hacker',
    });
    my $tm = Template::Minimal->new({
        include_path => ['t/tmpl'],
    });
    my $out = $tm->process_file('horror.tpl', $stash);
    my $expected = <<'END';

~`@#$%^&*()-_=+{[]}\|;:"'<,.>?/

Perl Hacker
END
    is $out, $expected, 'garbage ok';
}

done_testing;
