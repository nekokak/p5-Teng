package Teng::Row;
use strict;
use warnings;
use Carp ();
our $AUTOLOAD;

sub new {
    my ($class, $args) = @_;

    my $self = bless {
        # inflated values
        _get_column_cached     => {},
        # values will be updated
        _dirty_columns         => {},
        _autoload_column_cache => {},
        %$args,
    }, $class;

    $self->{select_columns} ||= [keys %{$args->{row_data}}];
    $self->{table} ||= $args->{teng}->schema->get_table($args->{table_name});

    $self;
}

sub generate_column_accessor {
    my ($x, $col) = @_;

    return sub {
        my $self = shift;

        # setter is alias of set_column (not deflate column) for historical reason
        return $self->set_column( $col => @_ ) if @_;

        # getter is alias of get (inflate column)
        $self->get($col);
    };
}

sub handle { $_[0]->{teng} }

sub get {
    my ($self, $col) = @_;

    # "Untrusted" means the row is set_column by scalarref.
    # e.g.
    #   $row->set_column("date" => \"DATE()");
    if ($self->{_untrusted_row_data}->{$col}) {
        Carp::carp("${col}'s row data is untrusted. by your update query.");
    }
    my $cache = $self->{_get_column_cached};
    my $data = $cache->{$col};
    if (! $data) {
        $data = $cache->{$col} = $self->{table} ? $self->{table}->call_inflate($col, $self->get_column($col)) : $self->get_column($col);
    }
    return $data;
}

sub set {
    my ($self, $col, $val) = @_;
    $self->set_column( $col => $self->{table}->call_deflate($col, $val) ); 
    delete $self->{_get_column_cached}->{$col};
    return $self;
}

sub get_column {
    my ($self, $col) = @_;

    unless ( $col ) {
        Carp::croak('please specify $col for first argument');
    }

    if ( exists $self->{row_data}->{$col} ) {
        if (exists $self->{_dirty_columns}->{$col}) {
            return $self->{_dirty_columns}->{$col};
        } else {
            return $self->{row_data}->{$col};
        }
    } else {
        Carp::croak("Specified column '$col' not found in row (query: " . ( $self->{sql} || 'unknown' ) . ")" );
    }
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

    if ( defined $self->{row_data}->{$col} 
      && defined $val 
      && $self->{row_data}->{$col} eq $val ) {
        return $val;
    }

    if (ref($val) eq 'SCALAR') {
        $self->{_untrusted_row_data}->{$col} = 1;
    }

    delete $self->{_get_column_cached}->{$col};
    $self->{_dirty_columns}->{$col} = $val;

    $val;
}

sub set_columns {
    my ($self, $args) = @_;

    for my $col (keys %$args) {
        $self->set_column($col, $args->{$col});
    }
}

sub get_dirty_columns {
    my $self = shift;
    +{ %{ $self->{_dirty_columns} } };
}

sub is_changed {
    my $self = shift;
    keys %{$self->{_dirty_columns}} > 0
}

sub update {
    my ($self, $upd) = @_;

    if (ref($self) eq 'Teng::Row') {
        Carp::croak q{can't update from basic Teng::Row class.};
    }

    my $table      = $self->{table};
    my $table_name = $self->{table_name};
    if (! $table) {
        Carp::croak( "Table definition for $table_name does not exist (Did you declare it in our schema?)" );
    }

    if ($upd) {
        for my $col (keys %$upd) {
            $self->set($col => $upd->{$col});
        }
    }

    my $where = $self->_where_cond;

    $upd = $self->get_dirty_columns;
    return 0 unless %$upd;

    my $bind_args = $self->{teng}->_bind_sql_type_to_args($table, $upd);
    my $result = $self->{teng}->do_update($table_name, $bind_args, $where, 1);
    $self->{row_data} = {
        %{ $self->{row_data} },
        %$upd,
    };
    $self->{_dirty_columns} = {};

    $result;
}

sub delete {
    my $self = shift;

    if (ref($self) eq 'Teng::Row') {
        Carp::croak q{can't delete from basic Teng::Row class.};
    }

    $self->{teng}->delete($self->{table_name}, $self->_where_cond);
}

sub refetch {
    my $self = shift;
    $self->{teng}->single($self->{table_name}, $self->_where_cond);
}

# Generate a where clause to fetch this row itself.
sub _where_cond {
    my $self = shift;

    my $table      = $self->{table};
    my $table_name = $self->{table_name};
    unless ($table) {
        Carp::croak("Unknown table: $table_name");
    }

    # get target table pk
    my $pk = $table->primary_keys;
    unless ($pk) {
        Carp::croak("$table_name has no primary key.");
    }

    # multi primary keys
    if ( ref $pk eq 'ARRAY' ) {
        unless (@$pk) {
            Carp::croak("$table_name has no primary key.");
        }

        my %pks = map { $_ => 1 } @$pk;

        unless ( ( grep { exists $pks{ $_ } } @{$self->{select_columns}} ) == @$pk ) {
            Carp::croak "can't get primary columns in your query.";
        }

        return +{ map { $_ => $self->{row_data}->{$_} } @$pk };
    } else {
        unless (grep { $pk eq $_ } @{$self->{select_columns}}) {
            Carp::croak "can't get primary column in your query.";
        }

        return +{ $pk => $self->{row_data}->{$pk} };
    }
}

# for +columns option by some search methods
sub AUTOLOAD {
    my $self = shift;
    my($method) = ($AUTOLOAD =~ /([^:']+$)/);
    ($self->{_autoload_column_cache}{$method} ||= $self->generate_column_accessor($method))->($self);
}

### don't autoload this
sub DESTROY { 1 };

1;

__END__
=head1 NAME

Teng::Row - Teng's Row class

=head1 METHODS

=over

=item $row = Teng::Row->new

create new Teng::Row's instance

=item $row->get($col)

    my $val = $row->get($column_name);

    # alias
    my $val = $row->$column_name;

get a column value from a row object.

Note: This method inflates values.

=item $row->set($col, $val)

    $row->set($col => $val);

set column data.

Note: This method deflates values.

=item $row->get_column($column_name)

    my $val = $row->get_column($column_name);

get a column value from a row object.

Note: This method does not inflate values.

=item $row->get_columns

    my $data = $row->get_columns;

Does C<get_column>, for all column values.

Note: This method does not inflate values.

=item $row->set_columns(\%new_row_data)

    $row->set_columns({$col => $val});

set columns data.

Note: This method does not deflate values.

=item $row->set_column($col => $val)

    $row->set_column($col => $val);

    # alias
    $row->$col($val);

set column data.

Note: This method does not deflate values.

=item $row->get_dirty_columns

returns those that have been changed.

=item $row->is_changed

returns true, If the row object have a updated column.

=item $row->update([$arg])

update is executed for instance record.

It works by schema in which primary key exists.

    $row->update({name => 'tokuhirom'});
    # or 
    $row->set({name => 'tokuhirom'});
    $row->update;

If C<$arg> HashRef is supplied, each pairs are passed to C<set()> method before update.

=item $row->delete

delete is executed for instance record.

It works by schema in which primary key exists.

=item my $refetched_row = $row->refetch;

refetch record from database. get new row object.

=item $row->handle

get Teng object.

    $row->handle->single('table', {id => 1});

=back

=head1 NOTE FOR COLUMN NAME METHOD

Teng::Row has methods that have name from column name. For example, if a table has column named 'foo', Teng::Row instance of it has method 'foo'.

This method has different behave for setter or getter as following:

    # (getter) is alias of $row->get('foo')
    # so this method returns inflated value.
    my $inflated_value = $row->foo;

    # (setter) is alias of $row->set_column('foo', $raw_value)
    # so this method does not deflate the value. This only accepts raw value but inflated object.
    $row->foo($raw_value);

This behave is from historical reason. You should use column name methods with great caution, if you want to use this.

=cut

