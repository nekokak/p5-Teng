package Mock::Trigger::Schema;
use DBIx::Skin::Schema::Declare;

schema {
    table {
        name 'mock_trigger_pre';
        pk 'id';
        columns qw/
            id
            name
        /;

        trigger pre_insert => sub {
            my ($class, $args) = @_;
            $args->{name} = 'pre_insert';
        };
        trigger pre_insert => sub {
            my ($class, $args) = @_;
            $args->{name} = $args->{name}.'_s';
        };

        trigger post_insert => sub {
            my ($class, $obj) = @_;
            $class->insert('mock_trigger_post',{
                id   => 1,
                name => 'post_insert',
            });
        };

        trigger pre_update => sub {
            my ($class, $args) = @_;
            $args->{name} = 'pre_update';
        };

        trigger post_update => sub {
            my ($class, $obj) = @_;
            $class->update('mock_trigger_post',{
                name => 'post_update',
            },{id => 1});
        };

        trigger pre_delete => sub {
            my ($class, $args) = @_;
            $class->delete('mock_trigger_post',{id => 1});
        };

        trigger post_delete => sub {
            my $class = shift;
            $class->insert('mock_trigger_post_delete',{
                id   => 1,
                name => 'post_delete',
            });
        };
    };

    table {
        name 'mock_trigger_post';
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    table {
        name 'mock_trigger_post_delete';
        pk 'id';
        columns qw/
            id
            name
        /;
    };
};

1;

