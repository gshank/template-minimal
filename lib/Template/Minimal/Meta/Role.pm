package Template::Minimal::Meta::Role;
use Moose::Role;
use namespace::autoclean;

has 'templates' => (
    is => 'ro',
    isa => 'HashRef',
    traits => ['Hash'],
    default => sub {{}},
    handles => {
       add_template => 'set',
       has_templates => 'count',
       get_template => 'get',
    },
);

1;
