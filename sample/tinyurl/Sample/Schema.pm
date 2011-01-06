package # hide from PAUSE
  Sample::Schema;
use DBIx::Skinny::Schema;
use WWW::Shorten::TinyURL;

install_table tinyurl => schema {
    pk 'id';
    columns qw/
        id
        url
        tinyurl
    /;

    trigger pre_insert => sub {
        my ( $class, $args ) = @_;
        $args->{tinyurl} = makeashorterlink($args->{url});
    };
};

1;

