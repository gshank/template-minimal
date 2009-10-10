use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Differences;

use_ok('Template::Minimal');
use aliased 'Template::Minimal::Stash';

# template strings
my $tt = Template::Minimal->new;

my $template = <<END;
<div class="[% css_class %]">
<input type="text">[% fif %]</input>
END

my $out = $tt->process_str('input' => $template, Stash->new({css_class => 'cinput',
            fif => 'Testing'}));
ok( $out, 'processed string template' );
my $processed = '<div class="cinput">
<input type="text">Testing</input>';
is( $out, $processed, 'output ok');

$out = $tt->process_str('my_tmpl' => $template, {css_class => 'cinput',
             fif => 'Testing'});
is( $out, $processed, 'output ok');

$template = <<END;
TEST: [% some_var %] [% IF reason %]reason="[% reason %]"[% END %]
stop test
END

$tt->add_template('test_if', $template);
ok( $tt->_has_template('test_if'), 'template has been added' );
$out = $tt->process( 'test_if', { some_var => "Here it is" } );
ok( $out, 'got output' );

my $widget = <<'END';
<input type="text" name="[% html_name %]" id="[% id %]" 
    [% IF size %] size="[% size %]"[% END %] 
    [% IF maxlength %] maxlength="[% maxlength %]"[% END %]
    value="[% fif %]">
END

$tt->add_template('widget', $widget);
ok( $tt->_has_template('widget'), 'widget template added' );
$out = $tt->process('widget', {
        html_name => 'test_field',
        id => 'abc1',
        size => 40,
        maxlength => 50,
        fif => 'my_test',
    });
ok( $out, 'got output' );
my $output = 
'<input type="text" name="test_field" id="abc1" 
     size="40" 
     maxlength="50"
    value="my_test">';
is( $out, $output, 'output matches' );



done_testing;

