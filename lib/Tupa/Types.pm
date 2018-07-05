package Tupa::Types;
use utf8;
use strict;
use warnings;

use MooseX::Types -declare => [qw(MobileNumber AlertLevel AppReportStatus Latitude Longitude)];

use MooseX::Types::Common::String qw(NonEmptySimpleStr NonEmptyStr);
use MooseX::Types::Moose qw(Str Int ArrayRef ScalarRef Num Maybe);
use Moose::Util::TypeConstraints;

my $is_international_mobile_number = sub {
  my $num = shift;
  return $num =~ /^\+\d{12,13}$/ ? 1 : 0 if $num =~ /\+55/;

  return $num =~ /^\+\d{10,16}$/ ? 1 : 0;
};

subtype MobileNumber, as Str, where {
  return 1 if $_ eq '+5599901010101';
  $is_international_mobile_number->($_);
};

enum AlertLevel,      [ 'attention', 'alert',   'emergency', 'overflow' ];
enum AppReportStatus, [ 'info',      'warning', 'error',     'debug' ];

subtype Latitude, as Num, where {
    $_ >= -90.0 and $_ <= 90.0;
}, message { 'Não é uma latitude válida [-90, 90]' };

subtype Longitude, as Num, where {
    $_ >= -180.0 and $_ <= 180.0;
}, message { 'Não é uma longitude válida [-180, 180]' };

coerce Latitude,  from Int, via { $_ + 0.0 };
coerce Longitude, from Int, via { $_ + 0.0 };

1;

