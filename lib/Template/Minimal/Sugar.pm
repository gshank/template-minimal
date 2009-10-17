package  Template::Minimal::Sugar;

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;
use namespace::autoclean;
#use HTML::FormHandler::Meta::Role;

=head1 NAME

Template::Minimal::Sugar - to add template sugar

=head1 SYNOPSIS

Enables the use of template specification sugar (snippet).
Use this module instead of C< use Moose; >

   package MyApp::Form::Foo;
   use Template::Minimal::Sugar;
   use namespace::autoclean;

   snippet 'user' => ( template => '[% form.name %] is a user form' );

   snippet 'header' => ( template => '<h1>Hello, World!</h1>' );

   
   1;

=cut

Moose::Exporter->setup_import_methods(
    with_meta => [ 'snippet' ],
    also        => 'Moose',
);

sub init_meta {
    my $class = shift;

    my %options = @_;
    Moose->init_meta(%options);
    my $meta = Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => $options{for_class},
        metaclass_roles => ['Template::Minimal::Meta::Role'],
    );
    return $meta;
}

sub snippet {
    my ( $meta, $name, %options ) = @_;

    $meta->add_snippet( $name, \%options  );
}

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
