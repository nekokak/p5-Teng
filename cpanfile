requires 'Carp';
requires 'Class::Accessor::Lite', '0.05';
requires 'Class::Load', '0.06';
requires 'DBI', '1.33';
requires 'DBIx::Inspector', '0.06';
requires 'DBIx::TransactionManager', '1.06';
requires 'Data::Page';
requires 'Data::Page::NoTotalEntries', '0.02';
requires 'SQL::Maker', '0.14';
requires 'parent';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::Mock::Guard';
    requires 'Test::More', '0.96';
    requires 'Test::Requires';
    requires 'Test::SharedFork', '0.15';
};

on develop => sub {
    requires 'DBIx::Tracer';
};
