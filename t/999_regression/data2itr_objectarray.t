use t::Utils;
use Mock::Inflate;
use Mock::Inflate::Name;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Inflate->set_dbh($dbh);
Mock::Inflate->setup_test_db;
Mock::Inflate->insert('mock_inflate',
    {
        id   => 1,
        name => Mock::Inflate::Name->new(name => 'perl'),
    }
);

subtest 'data2itr method' => sub {
    my $itr = Mock::Inflate->data2itr('mock_inflate',[
        {
            id   => 1,
            name => 'perl',
        },
        {
            id   => 2,
            name => 'ruby',
        },
        {
            id   => 3,
            name => 'python',
        },
    ]);
    $itr = Mock::Inflate->data2itr('mock_inflate', [$itr->all]);

    isa_ok $itr, 'DBIx::Skinny::Iterator';
    is $itr->count, 3;

    my $rows = [map { $_->get_columns } $itr->all];
    is_deeply $rows,  [
        {
            name => 'perl',
            id   => 1,
        },
        {
            name => 'ruby',
            id   => 2,
        },
        {
            name => 'python',
            id   => 3,
        }
    ];

    my $row = $itr->reset->first;
    isa_ok $row->name, 'Mock::Inflate::Name';

    my $new_name = Mock::Inflate::Name->new(name => 'c++');
    ok $row->update({name => $new_name});
    done_testing;
};

done_testing;
