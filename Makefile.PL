use inc::Module::Install;
name 'DBIx-Skin';
all_from 'lib/DBIx/Skin.pm';

requires 'UNIVERSAL::require';
requires 'Carp';
requires 'DBI';
requires 'Scalar::Util';
requires 'IO::Handle';
requires 'Class::Accessor::Lite' => 0.05;
requires 'Try::Tiny';
requires 'DBIx::TransactionManager' => '1.02';
requires 'Class::Load';
requires 'SQL::Maker';

author_tests('xt');

test_requires 'Test::More' => '0.96';
test_requires 'Test::SharedFork' => 0.15;
test_requires 'Test::mysqld'     if $Module::Install::AUTHOR;
test_requires 'Test::postgresql' if $Module::Install::AUTHOR;

tests 't/*.t t/*/*.t';

auto_set_repository;
WriteAll;
