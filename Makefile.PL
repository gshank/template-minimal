use strict;
use warnings;

use inc::Module::Install;

name 'Template-Minimal';
author 'Gerda Shank';
all_from 'lib/Template/Minimal.pm';
license 'perl';

#repository 'http://github.com/gshank/template-minimal/tree/master';

# prereqs
requires 'Moose'              => '0.90';
requires 'aliased';
requires 'namespace::autoclean' => '0.09';

# things the tests need
test_requires 'Test::More'      => '0.88';

tests();
author_tests('t/xt');

auto_install();

WriteAll();

