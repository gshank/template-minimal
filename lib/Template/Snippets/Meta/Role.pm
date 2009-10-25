package Template::Snippets::Meta::Role;
use Moose::Role;
use namespace::autoclean;

has 'snippets' => (
    is => 'ro',
    isa => 'HashRef',
    traits => ['Hash'],
    default => sub {{}},
    handles => {
       add_snippet => 'set',
       has_snippets => 'count',
       get_snippet => 'get',
    },
);

1;
