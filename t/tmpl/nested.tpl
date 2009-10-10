<html>
  <head><title>Howdy [% name %]</title></head>
  <body>
    <p>My favourite things, [% interest %]!</p>
    <ul>
      [% FOREACH item IN items %]
        <li>[% item %]</li>
      [% END %]
    </ul>

    [% IF possible_geek %]
        <span>I likes DnD...</span>
    [% END %]
  </body>
</html>

