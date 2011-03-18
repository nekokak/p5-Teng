use strict;
use warnings;
use Test::More;

{
    package Mock;
    use parent 'Teng';

    package Mock::Schema;
    use Teng::Schema::Declare;
    table {
        name 'mock';
        pk 'id';
        columns qw/ id name /;
    };

    package Mock::Name;
    use overload
        '""' => sub { $_[0]->as_inflate },
        fallback => 1
    ;
    sub new {
        my ($class, $name)  = @_;
        bless {
            name => $name,
        }, $class;
    }
    sub as_inflate {
        my $self = shift;
        $self->{name}.'_inflated';
    }
    sub as_deflate {
        my $self = shift;
        $self->{name};
    }
}

my $teng = Mock->new(connect_info => ['dbi:SQLite:']);
$teng->do(q{
    CREATE TABLE mock (
        id   INT,
        name TEXT
    )
});

my $table = $teng->schema->get_table('mock');
$table->add_inflator('name', sub {
    my $val = shift;
    Mock::Name->new($val);
});
$table->add_deflator('name', sub {
    my $val = shift;
    $val->as_deflate;
});

my $name = Mock::Name->new('nekokak');
$teng->insert('mock',{id => 1, name => $name});
my $row = $teng->single('mock', {id => 1});

ok +$row;
is +$row->id, 1;
isa_ok $row->name, 'Mock::Name';
is +$row->name, 'nekokak_inflated';
is +$row->get_column('name'), 'nekokak';

done_testing;


