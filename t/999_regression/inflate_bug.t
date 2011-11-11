use t::Utils;
use Test::More;
use Mock::Inflate;
use Mock::Inflate::Name;

my $dbh = t::Utils->setup_dbh();
my $db  = Mock::Inflate->new({ dbh => $dbh });
   $db->setup_test_db;
   $db->insert('mock_inflate', {
       id   => 1,
       name => Mock::Inflate::Name->new(name => 'perl'),
   });

subtest "update() doesn't break inflation after called. set object" => sub {
    my $row = $db->single(mock_inflate => { id => 1 });
    isa_ok $row->name, 'Mock::Inflate::Name';
    is     $row->name->name, 'perl';

    my $new_name = Mock::Inflate::Name->new(name => 'python');
    $row->update({ name => $new_name });
    isa_ok $row->name, 'Mock::Inflate::Name';
    is     $row->name->name, 'python';
};

subtest "update() doesn't break inflation after called. set raw data" => sub {
    my $row = $db->single(mock_inflate => { id => 1 });
    isa_ok $row->name, 'Mock::Inflate::Name';
    is     $row->name->name, 'python';

    $row->update({ name => 'perl' });
    isa_ok $row->name, 'Mock::Inflate::Name';
    is     $row->name->name, 'perl_deflate';
};

subtest "deflation called twice" => sub {
    my $row1 = $db->single(mock_inflate => { id => 1 });
    my $new_name = Mock::Inflate::Name->new(name => 'python');
       $row1->update({ name => $new_name });
    my $row2 = $row1->refetch;
    isa_ok $row2->name, 'Mock::Inflate::Name';
    is     $row2->name->name, 'python';
};

done_testing;
