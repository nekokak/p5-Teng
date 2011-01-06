use t::Utils;
use Mock::Basic;
use Test::More;

Mock::Basic->connect_info(
    {
        connect_options => { RaiseError => 1, PrintError => 0, AutoCommit => 1 },
    }
);

subtest 'connect_options should not loose after new' => sub {
    ok(Mock::Basic->_attributes->{connect_options}, "connect_options should exist");
    is_deeply +Mock::Basic->_attributes->{connect_options}, +{
        RaiseError => 1, PrintError => 0, AutoCommit => 1
    };

    Mock::Basic->new;

    ok(Mock::Basic->_attributes->{connect_options}, "connect_options should not loose");
    is_deeply +Mock::Basic->_attributes->{connect_options}, +{
        RaiseError => 1, PrintError => 0, AutoCommit => 1
    };
};

done_testing;

