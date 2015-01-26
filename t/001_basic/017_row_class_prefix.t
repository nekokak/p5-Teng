use t::Utils;
use Test::More;
use Teng::Schema::Declare;

subtest 'with prefix' => sub {
    my $schema = schema {
        default_row_class_prefix 'My::Entity';
        table {
            name 'body';
            columns qw(id);
        };
    };
    is($schema->get_row_class('body'), 'My::Entity::Body');
};

subtest 'without prefix' => sub {
    {
        package t::My::DB::Schema;
        use Teng::Schema::Declare;
        table {
            name 'user';
            columns qw(name);
        };
    };
    my $schema = t::My::DB::Schema->instance;
    is($schema->get_row_class('user'), 't::My::DB::Row::User');
};

done_testing;
