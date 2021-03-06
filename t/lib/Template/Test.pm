package Template::Test;

use Template::Snippets::Sugar::Role;
use namespace::autoclean;

snippet 'main' => ( template => '
    <html>
      <header>
      </header>
      <body>
      <h1>[% page_title %]</h1>
      [% INCLUDE content %]
      </body>
    </html>' );

snippet 'content' => ( template => '
    <div class="page">
    <h2>This is a test of template snippets</h2>
      <div class="section">
        [% INCLUDE sectionA %]
        [% INCLUDE sectionB %]
      </div>
    </div>' );

snippet 'sectionA' => ( template => '
    <p>Four score and seven years ago our fathers brought forth upon this
       continent a new nation conceived in liberty and dedicated to the
       proposition that all men are created equal. We are now engaged in
       a great civil war, testing whether that nation or any nation so
       conceived and so dedicated can long endure.
    </p>' );

snippet 'sectionB' => ( template => '
    <h3>Hello, [% name %]!</h3>' );

1;
