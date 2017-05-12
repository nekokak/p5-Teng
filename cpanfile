requires 'Class::Accessor::Lite', '0.05';
requires 'Class::Load', '0.06';
requires 'DBI', '1.33';
requires 'DBIx::Inspector', '0.06';
requires 'DBIx::TransactionManager', '1.06';
requires 'Data::Page';
requires 'Data::Page::NoTotalEntries', '0.02';
requires 'SQL::Maker', '0.14';
requires 'Scalar::Util';
requires 'parent';

on configure => sub {
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'DBD::SQLite';
    requires 'File::Temp';
    requires 'Test::Mock::Guard' => '0.10';
    requires 'Test::More', '0.96';
    requires 'Test::Requires';
    requires 'Test::SharedFork', '0.15';
    requires 'JSON::XS';
};

on develop => sub {
    requires 'DBIx::Tracer';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod', '1.14';
    requires 'Test::Pod::Coverage', '1.00';
    requires 'Test::Spellunker';
};
