package DBIx::Skinny::Row;
use strict;
use warnings;
use Carp ();

sub new {
    my ($class, $args) = @_;

    my $self = bless {%$args}, $class;
    $self->{select_columns} = [keys %{$self->{row_data}}];
    return $self;
}

sub setup {
    my $self = shift;
    my $class = ref $self;

    for my $alias ( @{$self->{select_columns}} ) {
        (my $col = lc $alias) =~ s/.+\.(.+)/$1/o;
        next if $class->can($col);
        no strict 'refs';
        *{"$class\::$col"} = $self->_lazy_get_data($col);
    }

    $self->{_get_column_cached} = {};
    $self->{_dirty_columns} = {};
}

sub _lazy_get_data {
    my ($self, $col) = @_;

    return sub {
        my $self = shift;

        if ($self->{_untrusted_row_data}->{$col}) {
            Carp::carp("${col}'s row data is untrusted. by your update query.");
        }
        unless ( $self->{_get_column_cached}->{$col} ) {
          my $data = $self->get_column($col);
          $self->{_get_column_cached}->{$col} = $self->{skinny}->schema->call_inflate($col, $data);
        }
        $self->{_get_column_cached}->{$col};
    };
}

sub handle { $_[0]->{skinny} }

sub get_column {
    my ($self, $col) = @_;

    unless ( $col ) {
        Carp::croak('please specify $col for first argument');
    }

    my $data = exists $self->{row_data}->{$col} ? $self->{row_data}->{$col} : Carp::croak("$col no selected column. SQL: " . ($self->{sql}||'unknown'));

    return $self->{skinny}->schema->utf8_on($col, $data);
}

sub get_columns {
    my $self = shift;

    my %data;
    for my $col ( @{$self->{select_columns}} ) {
        $data{$col} = $self->get_column($col);
    }
    return \%data;
}

sub set_column {
    my ($self, $col, $val) = @_;

    if (ref($val) eq 'SCALAR') {
        $self->{_untrusted_row_data}->{$col} = 1;
    } else {
        $self->{row_data}->{$col} = $self->{skinny}->schema->call_deflate($col, $val);
        $self->{_get_column_cached}->{$col} = $val;
        $self->{_dirty_columns}->{$col} = 1;
    }
}

sub set_columns {
    my ($self, $args) = @_;

    for my $col (keys %$args) {
        $self->set_column($col, $args->{$col});
    }
}

sub set {
    my $self = shift;
    Carp::carp( "set method has been deprecated. Please use set_columns or set_column method instead" );
    $self->set_columns(@_);
}

sub get_dirty_columns {
    my $self = shift;

    my %rows = map {$_ => $self->get_column($_)}
               keys %{$self->{_dirty_columns}};

    return \%rows;
}

sub insert {
    my $self = shift;

    $self->{skinny}->find_or_create($self->{opt_table_info}, $self->get_columns);
}

sub update {
    my ($self, $args, $table) = @_;

    $table ||= $self->{opt_table_info};
    $args ||= $self->get_dirty_columns;

    my $result = $self->{skinny}->update($table, $args, $self->_where_cond($table));
    $self->set_columns($args);

    return $result;
}

sub delete {
    my ($self, $table) = @_;

    $table ||= $self->{opt_table_info};
    $self->{skinny}->delete($table, $self->_where_cond($table));
}

sub refetch {
    my ($self, $table) = @_;
    $table ||= $self->{opt_table_info};
    $self->{skinny}->single($table, $self->_where_cond($table));
}

sub _where_cond {
    my ($self, $table) = @_;

    unless ($table) {
        Carp::croak "no table info";
    }

    my $schema_info = $self->{skinny}->schema->schema_info;
    unless ( $schema_info->{$table} ) {
        Carp::croak "unknown table: $table";
    }

    # get target table pk
    my $pk = $schema_info->{$table}->{pk};
    unless ($pk) {
        Carp::croak "$table have no pk.";
    }

    # multi primary keys
    if ( ref $pk eq 'ARRAY' ) {
        my %pks = map { $_ => 1 } @$pk;

        unless ( ( grep { exists $pks{ $_ } } @{$self->{select_columns}} ) == @$pk ) {
            Carp::croak "can't get primary columns in your query.";
        }

        return +{ map { $_ => $self->$_() } @$pk };
    } else {
        unless (grep { $pk eq $_ } @{$self->{select_columns}}) {
            Carp::croak "can't get primary column in your query.";
        }

        return +{ $pk => $self->$pk };
    }
}

1;

__END__
=head1 NAME

DBIx::Skinny::Row - DBIx::Skinny's Row class

=head1 METHODS

=over

=item $row->get_column($column_name)

    my $val = $row->get_column($column_name);

get a column value from a row object.

=item $row->get_columns

    my %data = $row->get_columns;

Does C<get_column>, for all column values.

=item $row->set(\%new_row_data)  # has been deprecated

    $row->set({$col => $val});

set columns data.

=item $row->set_columns(\%new_row_data)

    $row->set_columns({$col => $val});

set columns data.

=item $row->set_column($col => $val)

    $row->set_column($col => $val);

set column data.

=item $row->get_dirty_columns

returns those that have been changed.

=item $row->insert

insert row data. call find_or_create method.

=item $row->update([$arg, [$table_name]])

update is executed for instance record.

It works by schema in which primary key exists.

    $row->update({name => 'tokuhirom'});
    # or 
    $row->set({name => 'tokuhirom'});
    $row->update;

=item $row->delete([$table_name])

delete is executed for instance record.

It works by schema in which primary key exists.

=item my $refetched_row = $row->refetch($table_name);

$table_name is optional.

refetch record from database. get new row object.


=item $row->handle

get skinny object.

    $row->handle->single('table', {id => 1});

=cut

