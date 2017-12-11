package Tupa::Web::App::Controller::AppReport;

use utf8;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Tupa::Web::App::Controller'; }

sub base : Chained(/logged_in) PathPart('app-report') CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->user->obj->app_reports_rs;
}

sub report : Chained(base) : PathPart('') Args(0) POST {
  my ( $self, $c ) = @_;
  $c->stash->{collection}->execute($c, for => create => with => $c->req->data);
  $self->status_no_content($c);
}

__PACKAGE__->meta->make_immutable;

1;
