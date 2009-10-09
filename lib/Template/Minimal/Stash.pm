package Template::Minimal::Stash;

use Moose;
use Try::Tiny;

has vars => (
   is => 'rw', 
   traits => ['Hash'],
   isa => 'HashRef', 
   default => sub { {} },
   handles => {
      set_var => 'set',
   }
);
#has _sections => (is => 'rw', isa => 'HashRef[ArrayRef]', default => sub { {} });

sub BUILDARGS { 
    return { vars => ($_[1]||{}) }; 
}

#sub sections { @{ $_[0]->_sections->{$_[1]} || [] }; }
#sub add_section {
#    my ($self,$sec,@stashes) = @_;
#    $self->_sections->{$sec} ||= [];
#    push @{ $self->_sections->{$sec} }, (@stashes ? @stashes : undef); 
#}

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
        if( defined( $value = $root->{ $item } ) ) {
            return $value;
        }
        elsif ( ref $item eq 'ARRAY' ) {
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
    else {
        die "unable to find variable";
    }
    return undef;
}



__PACKAGE__->meta->make_immutable();
1;
