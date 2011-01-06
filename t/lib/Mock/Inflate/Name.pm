package Mock::Inflate::Name;
sub new {
    my($class, %args) = @_;
    bless { %args }, $class;
}
sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    $self->{name};
};
1;
