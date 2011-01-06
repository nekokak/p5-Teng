package Mock::Trigger::Schema;
use DBIx::Skinny::Schema;

install_table mock_trigger_pre => schema {
    pk 'id';
    columns qw/
        id
        name
    /;

    trigger pre_insert => callback {
        my ($class, $args) = @_;
        $args->{name} = 'pre_insert';
    };
    trigger pre_insert => callback {
        my ($class, $args) = @_;
        $args->{name} = $args->{name}.'_s';
    };

    trigger post_insert => callback {
        my ($class, $obj) = @_;
        $class->insert('mock_trigger_post',{
            id   => 1,
            name => 'post_insert',
        });
    };

    trigger pre_update => callback {
        my ($class, $args) = @_;
        $args->{name} = 'pre_update';
    };

    trigger post_update => callback {
        my ($class, $obj) = @_;
        $class->update('mock_trigger_post',{
            name => 'post_update',
        },{id => 1});
    };

    trigger pre_delete => callback {
        my ($class, $args) = @_;
        $class->delete('mock_trigger_post',{id => 1});
    };

    trigger post_delete => callback {
        my $class = shift;
        $class->insert('mock_trigger_post_delete',{
            id   => 1,
            name => 'post_delete',
        });
    };
};

install_table mock_trigger_post => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_table mock_trigger_post_delete => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

