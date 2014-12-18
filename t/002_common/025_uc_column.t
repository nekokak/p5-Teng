use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh();
my $db = Mock::Basic->new({dbh => $dbh, fields_case => 'NAME'});
$db->setup_test_db;


SKIP: {
    # In Pg, all column names are treated as lc and case sensitive, REGARDLESS 'field_case' option.
    # So skip it.
    skip 'uc_column not supported in Pg.', 2 if $dbh->{Driver}->{Name} eq 'Pg';

    $db->insert('mock_basic_camelcase',{
        Id   => 1,
        Name => 'perl',
    });

    subtest 'single' => sub {
        my $row = $db->single('mock_basic_camelcase',{Id => 1});
        isa_ok $row, 'Teng::Row';
        is $row->Id, 1;
        is $row->Name, 'perl';
        is_deeply $row->get_columns, +{
            Id        => 1,
            Name      => 'perl',
            DeleteFg  => 0,
        };
    };

    subtest 'single' => sub {
        my $rows = [map {$_->get_columns} $db->search('mock_basic_camelcase')->all];
        is_deeply $rows, [+{
            Id        => 1,
            Name      => 'perl',
            DeleteFg  => 0,
        }];
    };
}

done_testing;
