use strict;
use warnings;
use utf8;
use Test::More;
use Teng::Schema::Table;
use Teng::Schema::Declare;

{
    package My::Row;
    use parent qw/Teng::Row/;
}

subtest 'Teng::Schema::Table#new' => sub {
    subtest 'it uses "base_row_class"' => sub {
        my $table = Teng::Schema::Table->new(
            row_class      => 'My::Not::Existent',
            base_row_class => 'My::Row',
            columns        => []
        );
        isa_ok('My::Not::Existent', 'My::Row');
    };
};

subtest 'Teng::Schema::Declare' => sub {
    my $schema = schema {
        base_row_class 'My::Row';
        table {
            name 'boo';
            columns qw/
                id
                name
            /;
        };
    };
    isa_ok($schema->get_row_class('boo'), 'My::Row');
};

done_testing;

