use strict;
use warnings;
use Test::More;
use Test::Differences;

use Template::Minimal;
use aliased 'Template::Minimal::Stash';

my $tt = Template::Minimal->new;
my $template = "Testing....
[% FOREACH tag IN tags %]
[% tag %]
[% END %]
";
my $ast = $tt->parse_tmpl($template);
ok( $ast, 'parsed template' );
my $compiled = $tt->compile_tmpl($ast);
ok( $compiled, 'compiled template');
my $stash = Stash->new({ tags => ['Perl', 'programming', 'MVC'] } );
my $coderef = eval( $compiled );
ok( $coderef, 'got coderef' );
my $out = $coderef->($stash);
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
$tt = Template::Minimal->new({
    include_path => ['t/tmpl'],
});
$out = $tt->process_file('nested.tpl', $stash );
my $expected = <<'END';
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

done_testing;

