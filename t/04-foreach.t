use strict;
use warnings;
use Test::More;
use Test::Differences;

use Template::Snippets;
use aliased 'Template::Snippets::Stash';

my $tm = Template::Snippets->new;
my $template = "Testing....
[% FOREACH tag IN tags %]
[% tag %]
[% END %]
";
my $ast = $tm->parse($template);
ok( $ast, 'parsed template' );
my $compiled = $tm->compile($ast);
my $expected = <<'END';
sub {
  my ($ctx, $stash) = @_;
  my $out;
  $out .= 'Testing....';
  $out .= "\n";
  foreach my $tag ( @{$stash->get('tags')} ) {
    $stash->set_var('tag', $tag);
  $out .= "\n";
  $out .= $stash->get('tag');
  $out .= "\n";
  }
  $out .= "\n";
  return $out;
}
END

eq_or_diff( $compiled, $expected,  'compiled template');
my $stash = Stash->new({ tags => ['Perl', 'programming', 'MVC'] } );
my $coderef = eval( $compiled );
ok( $coderef, 'got coderef' );
my $out = $coderef->($tm, $stash);
ok( $out, 'got output from coderef');

is( $out, testx($stash), 'same output');

sub testx {
    my ($stash) = @_;
    my $out;
    $out .= 'Testing....
';
    foreach my $tag ( @{$stash->get('tags')} ) {
        $stash->set_var('tag', $tag);
        $out .= '
';
        $out .= $stash->get('tag');
        $out .= '
';
    }
    $out .= '
';
}

$stash = Stash->new({
    name => 'Gilligan', interest => 'TV',
    items => ['Ginger', 'The Skipper'],
    possible_geek => 1,
});
$tm = Template::Snippets->new({
    include_path => ['t/tmpl'],
});
$out = $tm->process_file('nested.tpl', $stash );
$expected = <<'END';
<html>
  <head><title>Howdy Gilligan</title></head>
  <body>
    <p>My favourite things, TV!</p>
    <ul>
      
        <li>Ginger</li>
      
        <li>The Skipper</li>
      
    </ul>

    
        <span>I likes DnD...</span>
    
  </body>
</html>

END

eq_or_diff( $out, $expected, 'More complex example' );

$template = 'Args: [% FOREACH arg IN args_a %][% arg %] [% END %]';
$ast = $tm->parse($template);
my $optimized = $tm->_optimize($ast);
my $code_str = $tm->compile($optimized);
$stash = Stash->new({ args_a => ['one', 'two', 'three'] } );
$coderef = eval( $code_str );
ok( $coderef, 'got coderef' );
$out = $coderef->($tm, $stash);
is( $out, 'Args: one two three ', 'got output from coderef');

done_testing;

