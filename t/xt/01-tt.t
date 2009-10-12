use strict;
use warnings;
use Test::More;
use Test::Differences;

use Template;
$Template::Config::STASH = 'Template::Stash';


my $tt = Template->new({
   COMPILE_EXT => '.ttc',
   INCLUDE_PATH => 't/tmpl',
});


my $out;
my $template;
my $vars;

$template = 'foo.tpl';
$vars = { name => 'Perl Hacker', title => 'paper', };
$tt->process($template, $vars, \$out);
my $expected = <<'END';

Hi Perl Hacker,

This is my paper


END
is( $out, $expected, 'output is the same');
$out = undef;

$template = 'nested.tpl';
$vars = {
    name => 'Gilligan', interest => 'TV',
    items => ['Ginger', 'The Skipper'],
    possible_geek => 1,
};
$tt->process($template, $vars, \$out);
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

done_testing;
