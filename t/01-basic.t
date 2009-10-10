use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Differences;

use_ok('Template::Minimal');
use aliased 'Template::Minimal::Stash';

my $tt = Template::Minimal->new();

my $str = $tt->compile_tmpl(
    [[ TEXT => 'Hello, world!' ]],
);
my $expected = 
'sub {
    my ($stash) = @_;
    my $out;
  $out .= \'Hello, world!\';
}
';
is( $str, $expected, 'text compiles' );

$str = $tt->compile_tmpl(
    [[ VARS => ['George'] ]],
);
$expected =
'sub {
    my ($stash) = @_;
    my $out;
  $out .= $stash->get(\'George\');
}
';
is( $str, $expected, 'variable compiles');

$str = $tt->compile_tmpl(
    [[ FOREACH => ['blog', "blogs" ]], [ 'END' ]],
);

$expected = 
'sub {
    my ($stash) = @_;
    my $out;
  foreach my $blog ( @{$stash->get(\'blogs\')} ) {
    $stash->set_var(\'blog\', $blog);
  }
}
';

is( $str, $expected, 'foreach compiles');

$tt = Template::Minimal->new();

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
    my $got = $tt->parse_tmpl($tpl);
    cmp_deeply($got, $ast, $cmt);
}


basic: {
    my $stash = Stash->new({ name => 'Perl Hacker', title => 'paper', });
    my $tt = Template::Minimal->new({ include_path => ['t/tmpl'], });
    my $out = $tt->process_file('foo.tpl', $stash);
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
    my $tt = Template::Minimal->new({
        include_path => ['t/tmpl'],
    });
    my $out = $tt->process_file('horror.tpl', $stash);
    my $expected = <<'END';

~`@#$%^&*()-_=+{[]}\|;:"'<,.>?/

Perl Hacker
END
    is $out, $expected, 'garbage ok';
}

done_testing;
