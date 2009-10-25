package Template::Snippets::TraitFor::Collection;

use Moose::Role;

use Template::Snippets;
use PadWalker ('peek_my');
use Carp ('confess');
with 'Template::Snippets::TraitFor::Strip';

has 'templates' => (
    is => 'ro',
    isa => 'Template::Snippets',
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
    my $tm = Template::Snippets->new( $self->tm_args );
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


1;
__END__

=head1 NAME

Template::Snippets::TraitFor::Collection - Snippet collection role

=head1 SYNOPSIS

  with 'Template::Snippets::TraitFor::Collection';

  sub BUILD {
     my $self = shift;
     $self->add_template('args', 'Args: [% FOREACH arg IN ARGS %][% arg %] [% END %]');
  }

  sub bar {
     my $self = shift;
     my @args = @_;
     return $self->tmpl('args', vars()); 
  }

=head1 DESCRIPTION

Template::Snippets::TraitFor::Collection contains a C<vars> function
which uses current lexical scope to resolve variable references.  So if you say:

  my $foo = 42;
  my $bar = 24;

  $self->tmpl( '[% foo %] <-> [% bar %]', vars() );

the result will be C<< 42 <-> 24 >>.
See L<Template::Snippets::TraitFor::Inline> for further information.

=head1 FUNCTIONS


=head1 AUTHOR

Gerda Shank  E<lt>gshank@cpan.orgE<gt>

This uses Jonathan Rockway's L<String::TT> code 

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

