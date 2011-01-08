use strict;
use Test::More;
use t::Utils;

use_ok "Mock::Trigger";

my $dbh = t::Utils::setup_dbh();
t::Utils::prepare_db( "Mock::Trigger", $dbh );
my $db = Mock::Trigger->new(dbh => $dbh);

subtest 'schema info' => sub {
    my $schema = $db->schema;
    isa_ok $schema, 'Mock::Trigger::Schema';

    my $triggers = $schema->triggers();
    is_deeply $triggers, {}, "schema trigger list is empty";

    my %data = (
        # table_name => { trigger_name => count }
        mock_trigger_pre => {
            pre_insert => 2,
            post_insert => 1,
            pre_update => 1,
            post_update => 1,
            pre_delete => 1,
            post_delete => 1,
        },
        mock_trigger_post => {
            pre_insert => 0,
            post_insert => 0,
            pre_update => 0,
            post_update => 0,
            pre_delete => 0,
            post_delete => 0,
        },
        mock_trigger_post_delete => {
            pre_insert => 0,
            post_insert => 0,
            pre_update => 0,
            post_update => 0,
            pre_delete => 0,
            post_delete => 0,
        },
            
    );

    while ( my ($table_name, $trigcounts) = each %data ) {
        my $table = $schema->get_table( $table_name );
        my $table_triggers = $table->triggers;
        while( my ($trigger_name, $count) = each %$trigcounts) {
            is scalar @{ $table_triggers->{$trigger_name} || [] }, $count,
                "$table_name.$trigger_name count should be $count";
        }
    }
};

subtest 'pre_insert/post_insert' => sub {
    my $row = $db->insert('mock_trigger_pre',{
        id   => 1,
    });
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->name, 'pre_insert_s';

    my $p_row = $db->single('mock_trigger_post',{id => 1});
    isa_ok $p_row, 'DBIx::Skin::Row';
    is $p_row->name, 'post_insert';
};

subtest 'pre_update/post_update' => sub {
    ok +$db->update('mock_trigger_pre',{});

    my $p_row = $db->single('mock_trigger_post',{id => 1});
    isa_ok $p_row, 'DBIx::Skin::Row';
    is $p_row->name, 'post_update';
};

subtest "pre_update affects row object's own column" => sub {
    my $row = $db->insert('mock_trigger_pre',{
            id   => 2,
            name => 'pre',
        });
    ok $row->update({ id => 2 });
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->name, 'pre_update';
};

subtest 'pre_delete/post_delete' => sub {
    $db->delete('mock_trigger_pre',{});

    TODO: {
        todo_skip "count() is not unimplemented", 1;
        is +$db->count('mock_trigger_post', 'id',{}), 0;
    };

    my $row = $db->single('mock_trigger_post_delete',{id => 1});
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->name, 'post_delete';
};

done_testing;



