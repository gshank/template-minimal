<html>
  <head><title>[% title %]</title></head>
  <body>
    <ul>
      [% FOREACH post IN posts %]
        <li>
            <h3>[% post.title %]</h3>
            <span>[% post.date %]</span>
        </li>
      [% END %]
    </ul>
  </body>
</html>
