package Template::Minimal;

use Moose;
use Try::Tiny;
use aliased 'Template::Minimal::Stash';

use 5.008;

our $VERSION = '0.01';

=head1 NAME

Template::Minimal - minimal, lightweight templates

=head1 SYNOPSIS

    my $widget = 
    '<input type="text" name="[% f.html_name %]" id="[% f.id %]" 
        [% IF f.size %]size="[% f.size %]"[% END %] 
        [% IF f.maxlength %]maxlength="[% f.maxlength %]"[% END %]
        value="[% r.fif %]">';
    has 'template' => ( is => 'ro', isa => 'Template::Minimal', builder => 'build_template');
    sub build_template {
        my $self = shift;
        my $tt = Template::Minimal->new;
        $tt->add_template('text_widget', $widget );
        return $tt;
    }
   <...>
   my $output = $self->template->process('text_widget', {
                f => $self, r => $result });
  
=head1 DESCRIPTION

For very lightweight templates, particularly those embedded in code instead
of as separate files. Intended to be roughly upward compatible with Template Toolkit,
but only implementing a very small subset of TT's syntax.

=head1 SYNTAX

   [% somevar %]
   [% somehash.somekey %]
   [% someobj.somemethod %]
   [% IF somevar %]....[% END %]
   [% IF somevar EQ somevalue %]...[% END %]
   [% FOREACH element IN somelist %] ... [% END %]
   [% INCLUDE some_other_template %]

=cut

has 'include_path' => (
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
       has_template => 'exists',
    }
);


# regexes for parsing
my ( $START, $END ) = map { qr{\Q$_\E} } qw([% %]);
my $tmrx_declaration = qr{$START (?:.+?) $END}x;
my $tmrx_text        = qr{
    (?:\A|(?<=$END))    # Start matching from the start of the file or end of a declaration
        .*?                 # everything in between
    (?:\Z|(?=$START))   # Finish at the end of the file or start of another declaration
}msx;
my $tmrx_chunks = qr{ ($tmrx_text)?  ($tmrx_declaration)?  }msx;
my $tmrx_ident = qr{
    [a-z][a-z0-9_\.]+ # any alphanumeric characters and underscores, but must start
                    # with a letter; everything must be lower case
}x;
my $tmrx_foreach = qr{ FOREACH \s+ ($tmrx_ident) \s+ IN \s+ ($tmrx_ident) }x;
my $tmrx_quoted = qr{ \'($tmrx_ident)\' }x;
my $tmrx_if = qr{ IF \s+ ($tmrx_ident) }x;
my $tmrx_if_eq = qr{ IF \s+ ('? $tmrx_ident '?) \s+ EQ \s+ ('? $tmrx_ident '?) }x;
my $tmrx_include = qr{ INCLUDE \s+ ["']? ([^"']+) ["']?  }x;
my $tmrx_newline = qr{ NEWLINE }x;
my $tmrx_vars = qr{ (?: \s* \| \s* )?  ( $tmrx_ident ) }x;
my $tmrx_directive = qr{
    $START
        \s*?
        (END
            | $tmrx_foreach
            | $tmrx_if
            | $tmrx_if_eq
            | $tmrx_include
            | $tmrx_newline
            | [a-z0-9_\.\s\|]+
        )
        \s*?
    $END
}x;

# for compiling
our $TMPL_CODE_START = <<'END';
sub {
  my ($ctx, $stash) = @_;
  my $out;
END
our $TMPL_CODE_END = <<'END';
  return $out;
}
END

sub parse {
    my ( $self, $tmpl ) = @_;

    my (@chunks) = $self->get_chunks($tmpl); 
    my @AST;
    while ( my $chunk = shift @chunks ) {
        if ( my ($tdir) = $chunk =~ $tmrx_directive ) {
            if ( my ($for_name) = $tdir =~ $tmrx_foreach ) {
                $for_name =~ s/['"]//g;
                push @AST, [ FOREACH => [$1, $2] ];
            }
            elsif ( my (@parts) = $tdir =~ $tmrx_if_eq ) {
               my @if_eq;
               for my $part (@parts) {
                   if( $part =~ m{'} ) {
                       $part =~ s/['"]//g;
                       push @if_eq, [ TEXT => $part ];
                   }
                   else {
                       push @if_eq, [ VARS => [ $part ] ]; 
                    }   
                }
                push @AST, [ IF_EQ => \@if_eq ]; 
            }
            elsif ( my ($if_name) = $tdir =~ $tmrx_if ) {
                $if_name =~ s/['"]//g;
                push @AST, [ IF => $if_name ];
            }
            elsif ( my ($inc_name) = $tdir =~ $tmrx_include ) {
                $inc_name =~ s/['"]//g;
                $inc_name =~ s/\s+$//g;
                push @AST, [ INCLUDE => $inc_name ];
            }
            elsif ( $tdir =~ m{END} ) {
                push @AST, ['END'];
            }
            elsif ( $tdir =~ m{NEWLINE} ) {
                push @AST, [ NEWLINE => 1 ];
            }
            elsif ( my (@items) = $tdir =~ m{$tmrx_vars}g ) {
                push @AST, [ VARS => [@items] ];
            }
        }
        else {
            push @AST, [ TEXT => $chunk ];
        }
    }
    return [@AST];
}

sub get_chunks {
    my ( $self, $tmpl ) = @_;

    $tmpl =~ s/\n/[% NEWLINE %]/g;
    my (@chunks) = grep { defined $_ && $_ } ( $tmpl =~ m{$tmrx_chunks}g );
    return @chunks;
}

sub _optimize {
    my ( undef, $AST ) = @_;

    my @OPT;
    while ( my $item = shift @$AST ) {
        my ( $type, $val ) = @$item;
        if( $type eq 'TEXT' ) {
            if ( $AST->[0] && $AST->[0]->[0] eq 'NEWLINE' ) {
                $item->[1] = $item->[1] . "\n";
                shift @$AST;
            }
        }
        elsif ( $type eq 'NEWLINE' ) {
            if ( $AST->[0] && $AST->[0]->[0] eq 'TEXT' ) {
                $AST->[0]->[1] = "\n" . $AST->[0]->[1];
                next;
            }
        }
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

sub compile {
    my ( $self, $AST ) = @_;

    my $depth = 0;
    my $code = '';
    if ( !$depth ) {
        $code .= $TMPL_CODE_START;
    }
    my @names = ( 'a' .. 'z' );
    while ( my $item = shift @$AST ) {
        my ( $type, $val ) = @$item;
        if ( $type eq 'TEXT' ) {
            $val =~ s{'}{\\'}g;
            $code .= q{  $out .= '} . $val . qq{';\n};
        }
        elsif ( $type eq 'NEWLINE' ) {
            $code .= q{  $out .= "\n"} . qq{;\n};
        }
        elsif ( $type eq 'VARS' ) {
            $code .=
                q{  $out .= $stash->get(} .
                quote_lists(@$val) . qq{);\n};
        }
        elsif ( $type eq 'END' ) {
            $code .= "  }\n";
            $depth--;
        }
        elsif ( $type eq 'FOREACH' ) {
            $depth++;
            my $each = $val->[0];
            my $array = $val->[1];
            $code .= "  foreach my \$$each ( \@{\$stash\->get('$array')} ) {\n";
            $code .= "    \$stash->set_var('$each', \$$each);\n";
        }
        elsif ( $type eq 'IF_EQ' ) {
            $depth++;
            $code .= "  if ( ";
            $code .= text_or_vars($val->[0]);
            $code .= "eq ";
            $code .= text_or_vars($val->[1]);
            $code .= ") {\n";
        }
        elsif ( $type eq 'IF' ) {
           $depth++;
           $code .= " if ( \$stash->get('$val') ) {\n";
        }
        elsif ( $type eq 'CONCAT' ) {
           my ( $t, $v ) = @{ shift @$val };
           if ( $t eq 'TEXT' ) {
               $v =~ s{'}{\\'}g;
               $code .= q{  $out .=  '} . $v . qq{'\n};
           }
           elsif ( $t eq 'VARS' ) {
               $code .=
                   q{  $out .= $stash->get(qw(} .
                    join( ' ', @$v ) . qq{))};
           }
            for my $concat (@$val) {
                my ( $ct, $cv ) = @$concat;

                if ( $ct eq 'TEXT' ) {
                    $cv =~ s{'}{\\'}g;
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
        elsif ( $type eq 'INCLUDE' ) {
            $code .= q{  $out .= $ctx->do_include('} . $val . q{', $stash);} . qq{\n};
        }
        else {
            die "Could not understand type '$type'";
        }
    }
    if ( !$depth ) {
        $code .= $TMPL_CODE_END;
    }
    return $code;
}

sub text_or_vars {
    my ($ast) = @_;

    my $code;
    my ( $type, $val ) = @$ast;
    if( $type eq 'TEXT' ) { 
        $code .= "\'$val\' ";
    }
    elsif ( $type eq 'VARS' ) {
        my $part = $val->[0];
        $code .= "\$stash->get(\'$part\') ";
    }
    return $code;
}

sub add_template {
    my ( $self, $tmpl_name, $tmpl_str ) = @_;
    my $AST = $self->parse($tmpl_str);
    $AST = $self->_optimize($AST);
    my $code_str = $self->compile($AST);
    my $coderef = eval($code_str) or die "Could not compile template $tmpl_name: $@";
    $self->_set_template( $tmpl_name, $coderef );
}

sub process_str {
    my ( $self, $tmpl_name, $tmpl_str, $stash ) = @_;

    my $compiled_tmpl;
    unless ( $compiled_tmpl = $self->_get_template($tmpl_name) ) {
        try {
            $compiled_tmpl = $self->add_template($tmpl_name, $tmpl_str );
        }
        catch {
            warn "Could not add template $tmpl_name";
        };
    }
    return $self->process( $tmpl_name, $stash );
}

sub process_string {
    my ( $self, $tmpl_str, $stash ) = @_;
    my $AST = $self->parse($tmpl_str);
    $AST = $self->_optimize($AST);
    my $code_str = $self->compile($AST);
    my $coderef = eval($code_str) or die "Could not compile template: $@";
    if( ref $stash eq 'HASH' ) {
       $stash = Stash->new($stash);
    } 
    my $out = $coderef->($self, $stash);
    return $out;
}

sub process {
    my ( $self, $tmpl_name, $stash ) = @_;
    die "Template does not exist" unless $self->has_template( $tmpl_name );
    my $compiled_tmpl = $self->_get_template($tmpl_name );
    if( ref $stash eq 'HASH' ) {
       $stash = Stash->new($stash);
    } 
    my $out = $compiled_tmpl->($self, $stash);
    return $out;
}


sub process_file {
   my ( $self, $tmpl_file, $stash ) = @_;
   if( $self->has_template( $tmpl_file ) ) {
       return $self->process( $tmpl_file, $stash );
   }
   else {
       my $tmpl_str = $self->_get_tmpl_str( $tmpl_file );
       return $self->process_str( $tmpl_file, $tmpl_str, $stash );
   }
}

sub do_include {
    my ( $self, $tmpl_name, $stash ) = @_;
    return $self->process($tmpl_name, $stash) if $self->has_template($tmpl_name);
    return '';
}

sub _get_tmpl_str {
    my ( $self, $tmpl ) = @_;

    my $tmpl_str     = '';
    my @dirs_to_try = @{ $self->include_path };
    my $file;
    while ( my $dir = shift @dirs_to_try ) {
        my $tmp = $dir . '/' . $tmpl;
        if ( -e $tmp ) {
            $file = $tmp;
            last;
        }
    }
    die "Could not find $tmpl" if ( !$file );
    open my $fh, $file or die "Could not open '$file': $!";
    $tmpl_str .= do { local $/; <$fh>; };
    close $fh or die "Could not close '$file': $!";
    return $tmpl_str;
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

=head1 AUTHOR

Gerda Shank E<lt>gshank@cpan.orgE<gt>

Some portions borrowed from L<Template::Teeny> by Scott McWhirter

=head1 LICENSE 

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

