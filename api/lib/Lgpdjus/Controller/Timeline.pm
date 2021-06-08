package Lgpdjus::Controller::Timeline;
use Mojo::Base 'Lgpdjus::Controller';
use Lgpdjus::Controller::Me;
use DateTime;
use Lgpdjus::Types qw/IntList/;

sub assert_user_perms {
    my $c = shift;

    Lgpdjus::Controller::Me::check_and_load($c);
    die 'missing user' unless $c->stash('user');
    return 1;
}

sub news_timeline_get {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        rows      => {required => 0, type => 'Int'},
        tags      => {required => 0, type => IntList},
        next_page => {required => 0, type => 'Str', max_length => 10000},
    );

    if (defined $params->{next_page}) {
        $params->{next_page} = eval { $c->decode_jwt($params->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($params->{next_page}{iss} || '') ne 'next_page';
    }
    else {
        delete $params->{next_page};
    }

    my $tweets = $c->list_news(
        %$params,
        user     => $c->stash('user'),
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $tweets,
        status => 200,
    );
}

sub tickets_timeline_get {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        rows      => {required => 0, type => 'Int'},
        next_page => {required => 0, type => 'Str', max_length => 10000},
    );

    if (defined $params->{next_page}) {
        $params->{next_page} = eval { $c->decode_jwt($params->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($params->{next_page}{iss} || '') ne 'next_page';
    }
    else {
        delete $params->{next_page};
    }

    my $tweets = $c->list_tickets(
        %$params,
        user_obj => $c->stash('user_obj'),
    );

    return $c->render(
        json   => $tweets,
        status => 200,
    );
}

sub public_available_tickets_timeline_get {
    my $c = shift;

    return $c->render(
        json   => $c->list_available_tickets(),
        status => 200,
    );
}



sub ticket_load_object {
    my $c = shift;

    my $params = $c->req->params->merge(ticket_id => $c->stash('ticket_id'));

    my $ticket = $c->load_ticket_object(user_obj => $c->stash('user_obj'));

    $c->stash(ticket => $ticket);
    return 1;
}

sub ticket_detail_get {
    my $c = shift;

    my $res = $c->get_ticket_detail(ticket => $c->stash('ticket'));

    return $c->render(
        json   => $res,
        status => 200,
    );
}

sub ticket_reply_post {
    my $c = shift;

    my $ticket = $c->create_ticket_response_reply(ticket => $c->stash('ticket'), user_obj => $c->stash('user_obj'));

    my $res = $c->get_ticket_detail(ticket => $ticket);

    return $c->render(
        json   => $res,
        status => 200,
    );
}


1;
