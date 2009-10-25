package Template::Snippets::TraitFor::Strip;

use Moose::Role;
use List::Util ('min');
use namespace::autoclean;

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
