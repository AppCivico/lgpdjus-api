package Lgpdjus::Minion::Tasks::AddBlockchain;
use Mojo::Base 'Mojolicious::Plugin';
use utf8;
use Lgpdjus::SchemaConnected;
use Scope::OnExit;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(generate_pdf_and_blockchain => \&job_generate_pdf_and_blockchain);
}

sub job_generate_pdf_and_blockchain {
    my ($job, $type, $object_id, $helper, $helper_opts) = @_;

    my $schema = get_schema();

    my $file;
    my $name;
    my $cliente_id;
    my $ticket_id;
    my $file_info = {job_id => $job->id, type => $type};
    if ($type eq 'account') {
        my $user_obj = $schema->resultset('Cliente')->find($object_id) or die 'cannot find cliente_id';
        $cliente_id = $user_obj->id;
        $file       = $job->app->generate_account_pdf(
            user_obj => $user_obj,
        );
        $name = 'criacao-conta-' . $user_obj->nome_completo . '.pdf';
    }
    elsif ($type eq 'ticket') {
        my $ticket = $schema->resultset('Ticket')->find($object_id);
        $cliente_id = $ticket->cliente_id;
        $ticket_id  = $ticket->id;
        $file       = $job->app->generate_ticket_pdf(
            ticket => $ticket,
        );
        $name = 'solicitacao-' . $ticket->protocol . '.pdf';
    }
    on_scope_exit { unlink($file) };

    $job->app->add_to_blockchain(
        file        => $file,
        name        => $name,
        cliente_id  => $cliente_id,
        file_info   => $file_info,
        ticket_id   => $ticket_id,
        helper      => $helper,
        helper_opts => $helper_opts,
    );


  OK:
    return $job->finish(1);
}

1;
