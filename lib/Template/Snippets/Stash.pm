package Template::Snippets::Stash;

use Moose;
use Try::Tiny;

=head1 NAME

Template::Snippets::Stash

=head1 SYNOPSIS

For use in Template::Snippets templates. Retrieves the value of variables
in C< var.key >> and C< var.method > style.

=cut

has vars => (
   is => 'ro', 
   traits => ['Hash'],
   isa => 'HashRef', 
   default => sub { {} },
   handles => {
      set_var => 'set',
   }
);

sub BUILDARGS { 
    return { vars => ($_[1]||{}) }; 
}

sub get { 
    my ($self, $ident, $args) = @_;
    my $root = $self;
    my $result;

    if( ref $ident eq 'ARRAY' ||
        ($ident =~ /\./ ) &&
        ($ident = [ map { s/\(.*$//; ($_, 0) } split(/\./, $ident) ])) {
           my $size = $#$ident;
           foreach ( my $i = 0; $i <= $size; $i += 2 ) {
               $result = $self->_dotop($root, @$ident[$i, $i + 1 ] );
               last unless defined $result;
               $root = $result;
           }
    }
    else {
        $result = $self->_dotop($root, $ident, $args);
    }
    return $result; 
}

sub _dotop {
    my ($self, $root, $item, $args ) = @_;

    my $rootref = ref $root;
    my $atroot;
    if( $atroot = blessed $root && $root->isa(ref $self) ) {
        $root = $self->vars;
    }
    my $value;
    my @result;
    $args ||= [];
    return undef unless defined( $root ) and defined ($item);
    if( $atroot || $rootref eq 'HASH' ) {
        if( exists $root->{ $item } ) {
            my $value = $root->{$item};
            if( ref $value eq 'CODE' ) {
                @result = &$value(@$args);
            }
            else {
                return $value;
            }
        }
        elsif ( ref $item eq 'ARRAY' ) {
            # hash slice
            return [@$root{@$item}];
        }
    }
    elsif ( $rootref eq 'ARRAY' ) {
        if( $item =~ /^-?\d+$/) {
            $value = $root->[$item];
            return $value;
        }
        elsif ( ref $item eq 'ARRAY' ) {
            return [@$root[@$item]];
        }
    }
    elsif (  blessed($root) ) {
        try { 
            @result = $root->$item(@$args); 
        }
        catch {
            my $class = ref($root) || $root;
            die "Could not do $class \-\> $item";
        };
    }
    if( defined $result[0]) {
        return scalar @result > 1 ? { @result } : $result[0];
    }
    return undef;
}

=head1 AUTHOR

Gerda Shank, E<lt>gshank@cpan.orgE<gt>

Largely borrowed from L<Template::Stash> by Andy Wardley

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable();
1;
