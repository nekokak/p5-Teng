use inc::Module::Install;
name 'DBIx-Skinny';
all_from 'lib/DBIx/Skinny.pm';

requires 'UNIVERSAL::require';
requires 'Carp';
requires 'DBI';
requires 'Scalar::Util';
requires 'IO::Handle';
requires 'Class::Accessor::Lite';
requires 'Try::Tiny';
requires 'DBIx::TransactionManager' => '1.02';
requires 'Class::Load';

author_tests('xt');

test_requires 'Test::More' => '0.96';
test_requires 'Test::SharedFork' => 0.15;
test_requires 'Test::mysqld'     if $Module::Install::AUTHOR;
test_requires 'Test::postgresql' if $Module::Install::AUTHOR;

tests 't/*.t t/*/*.t';

auto_set_repository;
WriteAll;
