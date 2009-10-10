use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Differences;

use_ok('Template::Minimal');
use aliased 'Template::Minimal::Stash';

my $tt = Template::Minimal->new();

my $str = $tt->compile_tmpl(
    [[ TEXT => 'Hello one and all' ]],
);
my $expected = 
'sub {
    my ($stash) = @_;
    my $out;
  $out .= \'Hello one and all\';
}
';
is( $str, $expected, 'Basic Text works' );

$str = $tt->compile_tmpl(
    [[ VARS => ['albert'] ]],
);
$expected =
'sub {
    my ($stash) = @_;
    my $out;
  $out .= $stash->get(\'albert\');
}
';
is( $str, $expected, 'Basic Variable works');

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

is( $str, $expected, 'Basic foreach works');

$str = $tt->compile_tmpl(
    [
        [TEXT => 'hehehe sucka '],
        [VARS => ['name', 'escape_html']],
        [TEXT => "\n        "],
        [FOREACH => ['foo', 'foos']],
        [TEXT => ' '],
        [VARS => ['foo.hehe']],
        [TEXT => ' '],
        ['END'],
    ],
);

$expected = <<'END';
sub {
    my ($stash) = @_;
    my $out;
  $out .= 'hehehe sucka ';
  $out .= $stash->get('name', 'escape_html');
  $out .= '
        ';
  foreach my $foo ( @{$stash->get('foos')} ) {
    $stash->set_var('foo', $foo);
  $out .= ' ';
  $out .= $stash->get('foo.hehe');
  $out .= ' ';
  }
}
END


is( $str, $expected, 'Complex example works' );

$tt = Template::Minimal->new();

my ($tl, $got);
basic_variable: {
    check('[% name %]', [[ VARS => ['name'] ]], 'Basic variable');
}

basic_plus_text: {
    check(
        'hhhmmm.... [% haha %]', 
        [[ TEXT => 'hhhmmm.... ' ], [ VARS => ['haha'] ]], 
        'Text plus basic var'
    );
}

basic_end_text: {
    check(
        '[% one_two %] bubba',
        [ [VARS => ['one_two'] ], [TEXT => ' bubba'] ],
        'Basic with text end'
    );
}

basic_with_filters: {
    check(
        '[% value | filter1 | filter2 %]', 
        [[ VARS => ['value', 'filter1', 'filter2'] ]], 
        'Filters'
    );
}

include: {
    check(
        "[% INCLUDE 'hehe.html' %]",
        [[ INCLUDE => 'hehe.html' ]],
        'Include'
    );
}

$DB::single=1;
complex: {
    check(
        'hehehe sucka [% name | escape_html %]
        [% FOREACH foo IN foos %] [% foo.hehe %] [% END %]',
        [
            [TEXT => 'hehehe sucka '],
            [VARS => ['name', 'escape_html']],
            [TEXT => "\n        "],
            [FOREACH => ['foo', 'foos']],
            [TEXT => ' '],
            [VARS => ['foo.hehe']],
            [TEXT => ' '],
            ['END'],
        ],
        'Complex'
    );
}

sub check {
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
    is( $out, $expected, 'Full process');
}

$DB::single=1;

foreach: {
    my $stash = Stash->new({
        name => 'Charlie', interest => 'movies',
        items => ['Happy Gilmore', 'Care Bears'],
        possible_geek => 1,
    });


    my $tt = Template::Minimal->new({
        include_path => ['t/tmpl'],
    });

    my $out = $tt->process_file('nested.tpl', $stash );
    my $expected = <<'END';
<html>
  <head><title>Howdy Charlie</title></head>
  <body>
    <p>My favourite things, movies!</p>
    <ul>
      
        <li>Happy Gilmore</li>
      
        <li>Care Bears</li>
      
    </ul>

    
        <span>I likes DnD...</span>
    
  </body>
</html>
END

    eq_or_diff( $out, $expected, 'More complex example' );
}

horror: {    
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
    is $out, $expected, 'Horror process';
}

# template strings

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

$DB::single=1;
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

