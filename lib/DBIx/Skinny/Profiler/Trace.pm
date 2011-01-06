package DBIx::Skinny::Profiler::Trace;
use strict;
use warnings;
use base 'DBIx::Skinny::Profiler';
use IO::Handle;
 
sub new {
    my $class = shift;
 
    my $self = bless {}, $class;
    my $env = $ENV{SKINNY_TRACE};
 
    my $fh;
    if ( $env && $env =~ /=(.+)$/ ) {
        my $fname = $1;
        open( $fh, '>>', $fname ) or die("cannot open '$fname': $!");
    }
    else {
        $fh = *STDERR;
    }
 
    autoflush $fh;

    $self->{fh} = $fh;

    $self;
}
 
sub record_query {
    my ( $self, $sql, $bind ) = @_;
    my $log = $self->_normalize($sql);
 
    if ( ref $bind eq 'ARRAY' ) {
        my @binds;
        push @binds, defined $_ ? $_ : 'undef' for @$bind;
        $log .= ' :binds ' . join ', ', @binds;
    }
 
    my $fh = $self->{fh};
    print $fh $log, "\n";
}
 
sub reset {}
sub query_log {}
 
1;

__END__
=head1 NAME

DBIx::Skinny::Profiler::Trace - support query profile.

=head1 SYNOPSIS

in your script:

    use Your::Model;
    
    my $row = Your::Model->insert('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'});
    
    $row = Your::Model->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
    $row->delete('user')
    
execute script:
It is output to STDERR in default.

    $ SKINNY_TRACE=1 perl ./sample.pl
    INSERT INTO user (id) VALUES (?) :binds 1
    UPDATE user set name = ? WHERE = id = ? :binds nekokak 1
    SELECT id, name FROM user WHERE id = ? :binds 1
    DELETE user WHERE id = ? :binds 1

or

The file can be specified. 

    $ SKINNY_TRACE=1=./query.log perl ./sample.pl
    $ cat ./query.log
    INSERT INTO user (id) VALUES (?) :binds 1
    UPDATE user set name = ? WHERE = id = ? :binds nekokak 1
    SELECT id, name FROM user WHERE id = ? :binds 1
    DELETE user WHERE id = ? :binds 1

=head1 METHODS

=over

=item $profiler->query_log()

get all execute SQLs.

=cut
