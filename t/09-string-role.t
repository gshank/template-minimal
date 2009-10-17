use strict;
use warnings;
use Test::More;

{
    package Test::TM::String;

    use Moose;
    with 'Template::Minimal::Trait';

    sub BUILD {
        my $self = shift;
        $self->add_template('a_tmpl', '[% foo %][% bar %]');        
        $self->add_template('b_tmpl', '[% foo %]' );
        $self->add_template('d_tmpl', '[% foo %] [% foo_s %] [% bar_a.0 %] [% baz_h.baz %]');
        $self->add_template('e_tmpl', '[% foo_a.0 %] [% foo_a_s %]' );
        $self->add_template('f_tmpl', strip(  q{
            Foo maps to [% ref.foo %]!
        }));
        $self->add_template('args', 'Args: [% FOREACH arg IN args_a %][% arg %] [% END %]');
    }

    
    sub a {
        my $foo = 'foo';
        my $bar = 'bar';
        return tm( '[% foo %][% bar %]' );
    }
    sub a_tmpl {
        my $self = shift;
        my $foo = 'foo';
        my $bar = 'bar';
        return $self->tmpl('a_tmpl', vars());
    }

    sub b {
        my $foo = \'reference';
        return tm( '[% foo %]' );
    }
    sub b_tmpl {
        my $self = shift;
        my $foo = \'reference';
        return $self->tmpl( 'b_tmpl', vars()); 
    }

    {
        sub A::foo { return 'A::foo' }
        
        sub c {
            my $a = bless { foo => 'bar' } => 'A';
            return tm( '[% a.foo %]' );
        }
    }


    sub d {
        my $foo = 'foo';
        my @bar = qw/bar/;
        my %baz = ( baz => 1 );
        return tm( '[% foo %] [% foo_s %] [% bar_a.0 %] [% baz_h.baz %]' );
    }
    sub d_tmpl {
        my $self = shift;
        my $foo = 'foo';
        my @bar = qw/bar/;
        my %baz = ( baz => 1 );
        return $self->tmpl( 'd_tmpl', vars()); 
    }

    sub e {
        my $foo_a = 'foo_a';
        my @foo = qw/array/;
        return tm( '[% foo_a.0 %] [% foo_a_s %]' );
    }
    sub e_tmpl {
        my $self = shift;
        my $foo_a = 'foo_a';
        my @foo = qw/array/;
        return $self->tmpl('e_tmpl', vars());
    }

    sub f {
        my $ref = { foo => 'bar' };
        return strip( tm( q{
            Foo maps to [% ref.foo %]!
        }));
    }
    sub f_tmpl {
        my $self = shift;
        my $ref = { foo => 'bar' };
        return $self->tmpl('f_tmpl', vars());
    }

    sub utf_eight {
        my $hoge = "ほげ";
        return tm( "[% hoge %]ぼげ" );
    }

    sub check_utf_eight {
        my $self = shift;
        my $string = utf_eight();
        my $length = length $string;
        return $length; 
    }

    sub print_args {
        my ( $self, @args ) = @_;
        return $self->tmpl('args', vars());
    }


}

my $tester = Test::TM::String->new;
ok( $tester, 'created object with string role' );
is( Test::TM::String::a, 'foobar', 'foobar works' );
is( $tester->a_tmpl, 'foobar', 'tmpl works' );
like( Test::TM::String::b(), qr/SCALAR/, "references aren't dereferenced");
like( $tester->b_tmpl, qr/SCALAR/, "tmpl refs" );
is( Test::TM::String::c(), 'A::foo', 'methods work' );
is( Test::TM::String::d(), 'foo foo bar 1', 'arrays and hashes work' );
is( $tester->d_tmpl, 'foo foo bar 1', 'tmpl arrays and hashes' );
is( Test::TM::String::e(), 'array foo_a', 'nothing overwritten' );
is( $tester->e_tmpl, 'array foo_a', 'tmpl nothing overwritten' );
is( Test::TM::String::f(), "Foo maps to bar!\n", 'references and strip work' );
is( $tester->f_tmpl, "Foo maps to bar!\n", 'tmpl references and strip work' );
is( Test::TM::String::utf_eight(), "ほげぼげ", 'utf8 works' );
TODO: {
    local $TODO = 'why did length of utf8 string change?';
    is( length Test::TM::String::utf_eight(), 4, 'utf8 works not by coincidence' );
};
is( $tester->print_args('one', 'two', 'three'), 'Args: one two three ', 'template with args');


done_testing;
