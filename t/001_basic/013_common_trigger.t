use t::Utils;
use Test::More;

{
    package Mock::CommonTrigger;
    use DBIx::Skinny connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };

    sub setup_test_db {
        my $db = shift;
        $db->do(q{
            CREATE TABLE mock_common_trigger (
                id         INT,
                created_at TEXT,
                updated_at TEXT
            )
        });
        $db->do(q{
            CREATE TABLE mock_both_triggers (
                id         INT,
                created_at TEXT,
                updated_at TEXT
            )
        });
        $db->do(q{
            CREATE TABLE mock_lack_column (
                id         INT,
                updated_at TEXT
            )
        });
    }

    package Mock::CommonTrigger::Schema;
    use DBIx::Skinny::Schema;

    install_table mock_common_trigger => schema {
        pk 'id';
        columns qw/id created_at updated_at/;
    };

    install_table mock_both_triggers => schema {
        pk 'id';
        columns qw/id created_at updated_at/;
        trigger pre_insert => callback {
            my ($self, $args, $table) = @_;
            my $columns = $self->schema->schema_info->{$table}->{columns};
            $args->{ created_at } .= '(custom)'
                if grep {/^created_at$/} @$columns;
        };
    };

    install_table mock_lack_column => schema {
        pk 'id';
        columns qw/id updated_at/;
    };

    install_common_trigger pre_insert => sub {
        my ($self, $args, $table) = @_;
        my $columns = $self->schema->schema_info->{$table}->{columns};
        $args->{created_at} ||= 'now'
            if grep {/^created_at$/} @$columns;
    };

    install_common_trigger pre_insert => sub {
        my ($self, $args, $table) = @_;
        my $columns = $self->schema->schema_info->{$table}->{columns};
        $args->{created_at} .= '_s'
            if grep {/^created_at$/} @$columns;
    };
}

Mock::CommonTrigger->setup_test_db;

subtest 'common trigger' => sub {
    my $row = Mock::CommonTrigger->insert('mock_common_trigger',{
        id   => 1,
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->created_at, 'now_s';
};

subtest 'common and table own trigger' => sub {
    my $row = Mock::CommonTrigger->insert('mock_both_triggers',{
        id   => 1,
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->created_at, 'now_s(custom)';
};

subtest 'trigger operates not exists column' => sub {
    my $row = Mock::CommonTrigger->insert('mock_lack_column',{
        id   => 1,
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is_deeply [qw/id/], [sort keys %{$row->{row_data}}];
};

done_testing;

