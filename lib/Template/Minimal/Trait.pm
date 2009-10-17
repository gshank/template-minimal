package Template::Minimal::Trait;

use Moose::Role;

use Template::Minimal;
use PadWalker ('peek_my');
use Carp ('confess');
use List::Util ('min');

has 'templates' => (
    is => 'ro',
    isa => 'Template::Minimal',
    builder => '_build_templates',
    handles => {
       has_template => 'has_template',
       add_template => 'add_template',
       tmpl         => 'process',
    }
);
has '_snippets' => (
    is => 'ro',
    isa => 'HashRef',
    traits => ['Hash'],
    lazy => 1,
    builder => '_build_snippets',
    handles => {
       _add_snippet => 'set',
       _get_snippet => 'get',
    }
);

sub _build_templates {
    my $self = shift;
    my $tm = Template::Minimal->new( $self->tm_args );
    foreach my $name ( keys %{$self->_snippets} ) {
        my $snippet = $self->_get_snippet($name);
        $tm->add_template( $name, $snippet->{template}) if exists $snippet->{template};
    }
    return $tm;
}

has 'tm_args' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub {{}},
);

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
    sub _build_tm_engine {
        return $engine ||= Template::Minimal->new;
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
    my $t = _build_tm_engine;
    return $t->process_string($template, \%transformed_vars );
}

sub vars {
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
    return \%transformed_vars;
}

sub _build_snippets {
    my $self = shift;
    my @field_list;

    my $snippets = {};
    foreach my $sc ( reverse $self->meta->linearized_isa ) {
        my $meta = $sc->meta;
        if ( $meta->can('calculate_all_roles') ) {
            foreach my $role ( reverse $meta->calculate_all_roles ) {
                if ( $role->can('snippets') && $role->has_snippets ) {
                    $snippets = $role->snippets;
                }
            }
        }
        if ( $meta->can('snippets') && $meta->has_snippets ) {
            $snippets = {%{$snippets}, %{$meta->snippets}};
        }
    }
    return $snippets;
}

sub strip($){
    my $lines = shift;

    my $trailing_newline = ($lines =~ /\n$/s);# perl silently throws away data
    my @lines = split "\n", $lines;
    shift @lines if $lines[0] eq ''; # strip empty leading line

    # determine indentation level
    my @spaces = map { /^(\040+)/ and length $1 or 0 } grep { !/^\s*$/ } @lines;
    
    my $indentation_level = min(@spaces);
    
    # strip off $indentation_level spaces
    my $stripped = join "\n", map { 
        my $copy = $_;
        substr($copy,0,$indentation_level) = "";
        $copy;
    } @lines;
    
    $stripped .= "\n" if $trailing_newline;
    return $stripped;
}

1;
__END__

=head1 NAME

Template::Minimal::Trait - use TM to interpolate lexical variables

=head1 SYNOPSIS

  with 'Template::Minimal::Trait';

  sub BUILD {
     my $self = shift;
     $self->add_template('args', 'Args: [% FOREACH arg IN ARGS %][% arg %] [% END %]');
  }

  sub foo {
     my $self = shift;
     return tm( 'my name is [% self.name %]!' );
  }

  sub bar {
     my $self = shift;
     my @args = @_;
     return $self->tmpl('args', vars()); 
  }

=head1 DESCRIPTION

Template::Minimal::Trait contains a C<tm> function, which takes a 
(L<Template::Minimal>) template as its argument.  It uses the
current lexical scope to resolve variable references.  So if you say:

  my $foo = 42;
  my $bar = 24;

  tm( '[% foo %] <-> [% bar %]' );

the result will be C<< 42 <-> 24 >>.

Because perl variables with the same name but different types may collide,
we have to do some mapping.  Arrays are always translated from
C<@array> to C<array_a> and hashes are always translated from C<%hash>
to C<hash_h>.  Scalars are special and retain their original name, but
they also get a C<scalar_s> alias.  Here's an example:

  my $scalar = 'scalar';
  my @array  = ('array', 'goes', 'here');
  my %hash   = ( hashes => 'are fun' );

  tm( '[% scalar %] [% scalar_s %] [% array_a %] [% hash_h %]' );

There is one special case, and that's when you have a scalar that is
named like an existing array or hash's alias:

  my $foo_a = 'foo_a';
  my @foo   = ('foo', 'array');

  tm( '[% foo_a %] [% foo_a_s %]' ); # foo_a is the array, foo_a_s is the scalar

In this case, the C<foo_a> accessor for the C<foo_a> scalar will not
be generated.  You will have to access it via C<foo_a_s>.  If you
delete the array, though, then C<foo_a> will refer to the scalar.

This is a very cornery case that you should never encounter unless you
are weird.  99% of the time you will just use the variable name.

=head1 EXPORT

None by default, but C<strip> and C<tm> are available.

=head1 FUNCTIONS

=head2 tm( $template )

Treats C<$template> as a Template::Minimal template, populated with variables
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

  my $data = strip( tm( ' 
      This is a [% template %].
      It is easy to read.
  '));  

Instead of the ugly heredoc equivalent:

  my $data = tm <<'EOTT';
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

