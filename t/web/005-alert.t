use utf8;
use strict;
use warnings;
use Test::More;
use lib "t/lib";
use Catalyst::Test 'Tupa::Web::App';
use HTTP::Request::Common qw(GET POST);
use JSON qw(encode_json);
use DateTime;
use Tupa::Test;
use DDP;

binmode STDIN,  ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

my $schema = Tupa::Web::App->model('DB')->schema;

db_transaction {
  {
    my $session = __new_session($schema);

    ok(
      my $district = $schema->resultset('District')->search(
        undef,
        {
          columns => [
            grep { !/geom/ }
              $schema->resultset('District')->result_source->columns
          ],
          '+columns' => { 'center' => \'ST_PointOnSurface(geom)' },
          rows       => 1
        }
        )->next,
      'district ok'
    );
    ok(
      my $sensor = $schema->resultset('Sensor')->create(
        {
          name        => 'incidunt molestias facilis porro',
          description => 'excepturi reprehenderit placeat voluptatem',
          type        => 'assumenda saepe minima',
          source      => $schema->resultset('SensorSource')
            ->find_or_create( { name => 'Reprehenderit' } ),
          location => $district->get_column('center')
        }
      ),
      'sensor ok'
    );
    ok(
      $session->user->follow($district),
      'user followed district ' . $district->name
    );

    ok(
      my $sample = $sensor->samples->create(
        { value => 1212, event_ts => DateTime->now->iso8601 }
      ),
      'sample ok'
    );

    {
      diag('create alert');
      my ( $res, $ctx ) =

        ctx_request(
        POST '/admin/alert',
        Content => encode_json(
          {
            sensor_sample_id => $sample->id,
            description      => 'foobar',
            level            => 'overflow'
          }
        ),
        Content_Type => 'application/json',
        'X-Api-Key'  => $session->api_key
        );
      ok( $res->is_success, 'Success' );
      is( $res->code, 201, '201 Created' );
    }

    {
      diag('create alert - missing required parameter');
      my ( $res, $ctx ) =

        ctx_request(
        POST '/admin/alert',
        Content => encode_json(
          {
            XXXXXsensor_sample_id => $sample->id,
            description           => 'foobar',
            level                 => 'overflow'
          }
        ),
        Content_Type => 'application/json',
        'X-Api-Key'  => $session->api_key
        );
      ok( !$res->is_success, 'Success' );
      is( $res->code, 400, '400 Bad Request' );
    }

    {
      diag('create alert - invalid level parameter');
      my ( $res, $ctx ) =

        ctx_request(
        POST '/admin/alert',
        Content => encode_json(
          {
            sensor_sample_id => $sample->id,
            description      => 'foobar',
            level            => 'XXXXXX'
          }
        ),
        Content_Type => 'application/json',
        'X-Api-Key'  => $session->api_key
        );
      ok( !$res->is_success, 'Success' );
      is( $res->code, 400, '400 Bad Request' );
    }

  }
};

done_testing;
