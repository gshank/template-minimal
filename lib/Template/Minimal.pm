package Template::Minimal;

use Moose;
use aliased 'Template::Minimal::Stash';

our $TMPL_CODE_START = <<'END';
sub {
    my ($stash) = @_;
    my $out;
END

our $TMPL_CODE_END = <<'END';
}
END

has tmpl_include_path => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 1,
    lazy     => 1,
    default  => sub { [qw(.)] },
);

has '_templates' => (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef',
    default => sub {{}},
    handles => {
       _set_template => 'set',
       _get_template => 'get',
       _has_template => 'exists',
    }
);


my ( $START, $END ) = map { qr{\Q$_\E} } qw([% %]);
my $tmpl_declaration = qr{$START (?:.+?) $END}x;
my $tmpl_text        = qr{
    (?:\A|(?<=$END))    # Start matching from the start of the file or end of a declaration
        .*?                 # everything in between
    (?:\Z|(?=$START))   # Finish at the end of the file or start of another declaration
}msx;
my $tmpl_chunks = qr{ ($tmpl_text)?  ($tmpl_declaration)?  }msx;
my $tmpl_ident = qr{
    [a-z][a-z0-9_\.]+ # any alphanumeric characters and underscores, but must start
                    # with a letter; everything must be lower case
}x;
my $tmpl_foreach = qr{ FOREACH \s+ ($tmpl_ident) \s+ IN \s+ ($tmpl_ident) }x;
my $tmpl_if = qr{ IF \s+ ($tmpl_ident) }x;
my $tmpl_include = qr{ INCLUDE \s+ ["']? ([^"']+) ["']?  }x;
my $tmpl_vars = qr{ (?: \s* \| \s* )?  ( $tmpl_ident ) }x;
my $tmpl_directive = qr{
    $START
        \s*?
        (END
            | $tmpl_foreach
            | $tmpl_if
            | $tmpl_include
            | [a-z0-9_\.\s\|]+
        )
        \s*?
    $END
}x;

sub parse_tmpl {
    my ( $self, $tpl ) = @_;
    my (@chunks) = grep { defined $_ && $_ } ( $tpl =~ m{$tmpl_chunks}g );
    my @AST;
    while ( my $chunk = shift @chunks ) {
        if ( my ($tdir) = $chunk =~ $tmpl_directive ) {
            if ( my ($for_name) = $tdir =~ $tmpl_foreach ) {
                $for_name =~ s/['"]//g;
                push @AST, [ FOREACH => [$1, $2] ];
            }
            elsif ( my ($if_name) = $tdir =~ $tmpl_if ) {
                $if_name =~ s/['"]//g;
                push @AST, [ IF => $if_name ];
            }
            elsif ( my ($inc_name) = $tdir =~ $tmpl_include ) {
                $inc_name =~ s/['"]//g;
                push @AST, [ INCLUDE => $inc_name ];
            }
            elsif ( $tdir =~ m{END} ) {
                push @AST, ['END'];
            }
            elsif ( my (@items) = $tdir =~ m{$tmpl_vars}g ) {
                push @AST, [ VARS => [@items] ];
            }
        }
        else {
            push @AST, [ TEXT => $chunk ];
        }
    }
    return [@AST];
}

sub _optimize_tmpl {
    my ( undef, $AST ) = @_;

    my @OPT;
    while ( my $item = shift @$AST ) {
        my ( $type, $val ) = @$item;
        if ( $type eq 'TEXT' || $type eq 'VARS' ) {
            my @long = ($item);
            # lets see what the next statement is to see if we can concat
            while ( $AST->[0] && ( $AST->[0][0] eq 'TEXT' || $AST->[0][0] eq 'VARS' ) ) {
                # move this
                push @long, shift @$AST;
            }
            # if there's only one statement, not much point in concat-ing.
            if ( @long > 1 ) {
                @long = [ CONCAT => [@long] ];
            }
            push @OPT, @long;
        }
        else {
            push @OPT, $item;
        }
    }
    return [@OPT];
}

sub compile_tmpl {
    my ( $self, $AST ) = @_;

    my $current_level = 0;
    my $code = '';
    if ( !$current_level ) {
        $code .= $TMPL_CODE_START;
    }
    my @names = ( 'a' .. 'z' );
    while ( my $item = shift @$AST ) {
        my ( $type, $val ) = @$item;
        if ( $type eq 'TEXT' ) {
            $val =~ s{'}{\\'};
            $code .= q{  $out .= '} . $val . qq{';\n};
        }
        elsif ( $type eq 'VARS' ) {
            $code .=
                q{  $out .= $stash->get(} .
                quote_lists(@$val) . qq{);\n};
        }
        elsif ( $type eq 'END' ) {
            $code .= "  }\n";
            $current_level--;
        }
        elsif ( $type eq 'FOREACH' ) {
            $current_level++;
            my $each = $val->[0];
            my $array = $val->[1];
            $code .= "  foreach my \$$each ( \@{\$stash\->get('$array')} ) {\n";
            $code .= "    \$stash->set_var('$each', \$$each);\n";
        }
        elsif ( $type eq 'IF' ) {
           $current_level++;
           $code .= " if ( \$stash->get('$val') ) {\n";
        }
        elsif ( $type eq 'CONCAT' ) {
            my ( $t, $v ) = @{ shift @$val };
            if ( $t eq 'TEXT' ) {
                $v =~ s{'}{\\'};
                $code .= q{  $out .=  '} . $v . qq{'\n};
            }
            elsif ( $t eq 'VARS' ) {
                $code .=
                    q{  $out .= $stash->get(} .
                    quote_lists(@$val) . qq{)};
            }
            for my $concat (@$val) {
                my ( $ct, $cv ) = @$concat;

                if ( $ct eq 'TEXT' ) {
                    $cv =~ s{'}{\\'};
                    $code .= qq{\n    . '} . $cv . q{'};
                }
                elsif ( $ct eq 'VARS' ) {
                    $code .=
                        qq{\n    . \$stash->get(qw(} .
                        join( ' ', @$cv ) . qq{))};
                }
            }
            $code .= ";\n";
        }
        else {
            die "Could not understand type '$type'";
        }
    }
    if ( !$current_level ) {
        $code .= $TMPL_CODE_END;
    }
    return $code;
}

sub add_template {
    my ( $self, $tmpl_name, $tmpl_str ) = @_;
    my $AST = $self->parse_tmpl($tmpl_str);
    $AST = $self->_optimize_tmpl($AST);
    my $code_str = $self->compile_tmpl($AST);
    my $coderef = eval($code_str) or die "Could not compile template: $@";
    $self->_set_template( $tmpl_name, $coderef );
}

sub process_str {
    my ( $self, $tmpl_name, $tmpl_str, $stash ) = @_;

    my $compiled_tmpl;
    unless ( $compiled_tmpl = $self->_get_template($tmpl_name) ) {
        $compiled_tmpl = $self->add_template($tmpl_name, $tmpl_str );
    }
    return $self->process( $tmpl_name, $stash );
}

sub process {
    my ( $self, $tmpl_name, $stash ) = @_;
    die "Template does not exist" unless $self->_has_template( $tmpl_name );
    my $compiled_tmpl = $self->_get_template($tmpl_name );
    if( ref $stash eq 'HASH' ) {
       $stash = Stash->new($stash);
    } 
    my $out = $compiled_tmpl->($stash);
    return $out;
}


sub process_file {
   my ( $self, $tmpl_file, $stash ) = @_;
   if( $self->_has_template( $tmpl_file ) ) {
       return $self->process( $tmpl_file, $stash );
   }
   else {
       my $tmpl_str = $self->_get_tmpl_str( $tmpl_file );
       return $self->process_str( $tmpl_file, $tmpl_str, $stash );
   }
}

sub _get_tmpl_str {
    my ( $self, $tpl ) = @_;

    my $tpl_str     = '';
    my @dirs_to_try = @{ $self->tmpl_include_path };
    my $file;
    while ( my $dir = shift @dirs_to_try ) {
        my $tmp = $dir . '/' . $tpl;
        if ( -e $tmp ) {
            $file = $tmp;
            last;
        }
    }
    die "Could not find $tpl" if ( !$file );
    open my $fh, $file or die "Could not open '$file': $!";
    $tpl_str .= do { local $/; <$fh>; };
    close $fh or die "Could not close '$file': $!";
    return $tpl_str;
}

sub quote_lists {
    my @list = @_;
    my $string = '';
    my $sep = '';
    foreach my $val (@list) {
        $string .= $sep;
        $string .= "'$val'";
        $sep = ', ';
    }
    return $string;
}

1;

