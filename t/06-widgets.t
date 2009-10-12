use strict;
use warnings;
use Test::More;

{
    package Widget::Field::Text;

    use Moose::Role;
    use Template::Minimal;

    my $widget = <<'END';
    <input type="text" name="[% f.html_name %]" id="[% f.id %]" 
        [% IF f.size %]size="[% f.size %]"[% END %] 
        [% IF f.maxlength %]maxlength="[% f.maxlength %]"[% END %]
        value="[% r.fif %]">
END
    has 'template' => ( is => 'ro', isa => 'Template::Minimal', builder => 'build_template');
    sub build_template {
        my $self = shift;
        my $tt = Template::Minimal->new;
        $tt->add_template('text_widget', $widget );
        return $tt;
    }

    sub render {
        my ( $self, $result ) = @_;

        $result ||= $self->result;
        my $output = $self->template->process('text_widget', {
                f => $self, r => $result });
#        return $self->wrap_field( $result, $output );
    }


}

use HTML::FormHandler::Field::Text;
my $field = HTML::FormHandler::Field::Text->new_with_traits( 
    traits => ['Widget::Field::Text'], name => 'test_text',
    id => 'abc', size => 30, maxlength => 40 );
ok( $field, 'created field' );

my $expected = 
'    <input type="text" name="test_text" id="abc" 
        size="30" 
        maxlength="40"
        value="">
';

is( $field->render, $expected, 'renders ok');

done_testing;
