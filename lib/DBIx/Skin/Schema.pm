package DBIx::Skin::Schema;
use strict;
use warnings;
use Scalar::Util ();
use DBIx::Skin::Util ();
use Class::Accessor::Lite
    rw => [ qw(
        tables
        triggers
    ) ]
;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        triggers => {},
        tables => {},
        %args,
    }, $class;
    return $self;
}

sub set_default_instance {
    my ($class, $instance) = @_;
    no strict 'refs';
    no warnings 'once';
    ${"$class\::DEFAULT_INSTANCE"} = $instance;
}

sub instance {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    ${"$class\::DEFAULT_INSTANCE"};
}

sub add_table {
    my ($self, $table) = @_;
    $self->tables->{$table->name} = $table;
}

sub get_table {
    my ($self, $name) = @_;
    $self->tables->{$name};
}

sub get_row_class {
    my ($self, $db, $tablename) = @_;

    my $table = $self->get_table($tablename);
    my $row_class = $table->row_class;

    if ( $row_class !~ s/^\+// ) {
        $row_class = join '::',
            Scalar::Util::blessed($db),
            'Row',
            $row_class
        ;
    }

    DBIx::Skin::Util::load_class($row_class) or do {
        no strict 'refs'; @{"$row_class\::ISA"} = ('DBIx::Skin::Row');
        foreach my $col (@{$table->columns}) {
            no strict 'refs';
            *{"$row_class\::$col"} = $row_class->_lazy_get_data($col);
        }
    };

    return $row_class;
}

sub add_trigger {
    my ($self, $trigger_name, $callback) = @_;
    my $triggers = $self->triggers->{ $trigger_name } || [];
    push @$triggers, $callback;
}

sub call_trigger {
    my ($self, $trigger_name, $db, $tablename, $args) = @_;

    my $triggers = $self->triggers->{ $trigger_name } || [];
    for my $code (@$triggers) {
        $code->($db, $args, $tablename);
    }

    my $table = $self->get_table($tablename);
    if (! $table) {
        Carp::croak( "No table object associated with $tablename" );
    }
    $table->call_trigger( $db, $trigger_name, $args );
}

# old Schema.pm

sub install_table ($$) {
    my ($table, $install_code) = @_;

    my $class = caller;
    $class->schema_info->{_installing_table} = $table;
        $install_code->();
    $class->schema_info->{$table}->{row_class} ||= DBIx::Skin::Util::mk_row_class($class, $table);

    delete $class->schema_info->{_installing_table};
}

sub schema (&) { shift }

sub pk {
    my @columns = @_;

    my $class = caller;
    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{pk} = (@columns == 1 ? $columns[0] : \@columns);
}

sub row_class ($) {
    my $row_class = shift;

    DBIx::Skin::Util::load_class($row_class) or die "$row_class not found or compile error.";
    my $class = caller;
    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{row_class} = $row_class;
}

sub columns (@) {
    my @columns = @_;

    my (@_columns, %_column_types);
    for my $item (@columns) {
        if (not ref $item) {
            push @_columns, $item;
        } elsif (ref $item eq 'HASH') {
            push @_columns, $item->{name};
            $_column_types{$item->{name}} = $item->{type};
        } else {
            die "columns must be 'SCALAR' or 'HASHREF'";    
        }
    }

    my $class = caller;
    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{columns} = \@_columns;

    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{column_types} = \%_column_types;
}

sub column_type {
    my ($class, $table, $column) = @_;
    exists $class->schema_info->{$table}->{column_types}->{$column} ? $class->schema_info->{$table}->{column_types}->{$column}
                                                                    : undef;
}

sub trigger ($$) {
    my ($trigger_name, $code) = @_;

    my $class = caller;
    push @{$class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{trigger}->{$trigger_name}}, $code;
}

sub install_inflate_rule ($$) {
    my ($rule, $install_inflate_code) = @_;

    my $class = caller;
    $class->inflate_rules->{_installing_rule} = $rule;
        $install_inflate_code->();
    delete $class->inflate_rules->{_installing_rule};
}

sub inflate (&) {
    my $code = shift;    

    my $class = caller;
    $class->inflate_rules->{
        $class->inflate_rules->{_installing_rule}
    }->{inflate} = $code;
}

sub deflate (&) {
    my $code = shift;

    my $class = caller;
    $class->inflate_rules->{
        $class->inflate_rules->{_installing_rule}
    }->{deflate} = $code;
}

sub call_inflate {
    my $class = shift;

    return $class->_do_inflate('inflate', @_);
}

sub call_deflate {
    my $class = shift;

    return $_[1] if ref $_[1] eq 'SCALAR'; # to ignore \"foo + 1"
    return $class->_do_inflate('deflate', @_);
}

sub _do_inflate {
    my ($class, $key, $col, $data) = @_;

    my $inflate_rules = $class->inflate_rules;
    for my $rule (keys %{$inflate_rules}) {
        if ($col =~ /$rule/ and my $code = $inflate_rules->{$rule}->{$key}) {
            $data = $code->($data);
        }
    }
    return $data;
}

sub callback (&) { shift }

sub install_common_trigger ($$) {
    my ($trigger_name, $code) = @_;

    my $class = caller;
    push @{$class->common_triggers->{$trigger_name}}, $code;
}

1;

__END__

=head1 NAME

DBIx::Skin::Schema - Schema DSL for DBIx::Skin

=head1 SYNOPSIS

    package Your::Model;
    use DBIx::Skin connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };
    1;
    
    package Your::Model::Schema:
    use DBIx::Skin::Schema;
    
    # set user table schema settings
    install_table user => schema {
        pk 'id';
        columns qw/id name created_at/;

        trigger pre_insert => callback {
            # hook
        };

        trigger pre_update => callback {
            # hook
        };

        row_class 'Your::Model::Row::User';
    };

    install_inflate_rule '^name$' => callback {
        inflate {
            my $value = shift;
            # inflate hook
        };
        deflate {
            my $value = shift;
            # deflate hook
        };
    };
    
    1;


