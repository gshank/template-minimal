package Template::Snippets::TraitFor::Inline;

use Moose::Role;

with 'Template::Snippets::TraitFor::Strip';

use Template::Snippets;
use PadWalker ('peek_my');
use Carp ('confess');

our $VERSION   = '0.01';

my %SIGIL_MAP = (
    '$' => 's',
    '@' => 'a',
    '%' => 'h',
    '&' => 'c', # probably do not need
    '*' => 'g', # probably do not need
);

{
    my $engine; 
    sub _build_tmpl_engine {
        return $engine ||= Template::Snippets->new;
    }
}

sub tm($) {
    my $template = shift;
    confess 'template required' if !defined $template;
    my %vars = %{peek_my(1)||{}};
    my %transformed_vars;
    for my $v (keys %vars){
        my ($sigil, $varname) = ($v =~ /^(.)(.+)$/);
        my $suffix = $SIGIL_MAP{$sigil};
        my $name = join '_', $varname, $suffix;
        $transformed_vars{$name} = $vars{$v};
        if($sigil eq '$'){
            $transformed_vars{$name} = ${$transformed_vars{$name}};
        }
    }

    # add the plain scalar variables (without overwriting anything)
    for my $v (grep { /_s$/ } keys %transformed_vars) {
        my ($varname) = ($v =~ /^(.+)_s$/);
        if(!exists $transformed_vars{$varname}){
            $transformed_vars{$varname} = $transformed_vars{$v};
        }
    }
    my $t = _build_tmpl_engine;
    return $t->process_string($template, \%transformed_vars );
}


1;
__END__

=head1 NAME

Template::Snippets::TraitFor::Inline - use TM to interpolate lexical variables

=head1 SYNOPSIS

  with 'Template::Snippets::TraitFor::Inline';

  sub foo {
     my $self = shift;
     return tmpl( 'my name is [% self.name %]!' );
  }

=head1 DESCRIPTION

Template::Snippets::TraitFor::Inline contains a C<tmpl> function, which takes a 
(L<Template::Snippets>) template as its argument.  It uses the
current lexical scope to resolve variable references.  So if you say:

  my $foo = 42;
  my $bar = 24;

  tmpl( '[% foo %] <-> [% bar %]' );

the result will be C<< 42 <-> 24 >>.

Because perl variables with the same name but different types may collide,
we have to do some mapping.  Arrays are always translated from
C<@array> to C<array_a> and hashes are always translated from C<%hash>
to C<hash_h>.  Scalars are special and retain their original name, but
they also get a C<scalar_s> alias.  Here's an example:

  my $scalar = 'scalar';
  my @array  = ('array', 'goes', 'here');
  my %hash   = ( hashes => 'are fun' );

  tmpl( '[% scalar %] [% scalar_s %] [% array_a %] [% hash_h %]' );

There is one special case, and that's when you have a scalar that is
named like an existing array or hash's alias:

  my $foo_a = 'foo_a';
  my @foo   = ('foo', 'array');

  tmpl( '[% foo_a %] [% foo_a_s %]' ); # foo_a is the array, foo_a_s is the scalar

In this case, the C<foo_a> accessor for the C<foo_a> scalar will not
be generated.  You will have to access it via C<foo_a_s>.  If you
delete the array, though, then C<foo_a> will refer to the scalar.

This is a very cornery case that you should never encounter unless you
are weird.  99% of the time you will just use the variable name.

=head1 FUNCTIONS

=head2 tmpl( $template )

Treats C<$template> as a Template::Snippets template, populated with variables
from the current lexical scope.

=head2 strip( $text )

Removes a leading empty line and common leading spaces on each line.
For example,

  strip q{
    This is a test.
     This is indented.
  };

Will yield the string C<"This is a test\n This is indented.\n">.

This feature is designed to be used like:

  my $data = strip( tmpl( ' 
      This is a [% template %].
      It is easy to read.
  '));  

Instead of the ugly heredoc equivalent:

  my $data = tmpl <<'EOTT';
This is a [% template %].
It looks like crap.
EOTT


=head1 AUTHOR

Gerda Shank  E<lt>gshank@cpan.orgE<gt>

This is Jonathan Rockway's L<String::TT> without the TT prereq

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

