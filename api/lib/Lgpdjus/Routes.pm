package Lgpdjus::Routes;
use Mojo::Base -strict;

sub register {
    my $r = shift;

    # PUBLIC ENDPOINTS
    # POST /signup
    $r->post('signup')->to(controller => 'SignUp', action => 'post');

    # POST /login
    $r->post('login')->to(controller => 'Login', action => 'post');

    # POST /login-govbr
    $r->post('login-govbr')->to(controller => 'Login', action => 'govbr_post');
    $r->get('status-govbr')->to(controller => 'Login', action => 'govbr_status_get');
    $r->get('gov-br-get-token')->to(controller => 'Login', action => 'govbr_get_token');
    $r->get('entrar')->to(controller => 'Govbr', action => 'web_entrar');
    $r->get('retorno-logout')->to(controller => 'Govbr', action => 'web_retorno_logout');
    $r->get('textos')->to(controller => 'Govbr', action => 'web_textos');

    # POST /reset-password
    $r->post('reset-password/request-new')->to(controller => 'ResetPassword', action => 'request_new');
    $r->post('reset-password/write-new')->to(controller => 'ResetPassword', action => 'write_new');

    # GET /news-redirect
    $r->get('news-redirect')->to(controller => 'News', action => 'redirect');

    # GET /get-proxy
    $r->get('get-proxy')->to(controller => 'MediaDownload', action => 'public_get_proxy');

    # GET /web/
    my $web = $r->under('web')->to(controller => 'WebTextos', action => 'apply_rps');

    # GET /web/sobre
    $web->get('sobre')->to(action => 'web_sobre');

    # GET /web/termos-de-uso
    $web->get('termos-de-uso')->to(action => 'web_termos_de_uso');
    $web->get('acessibilidade-android')->to(action => 'web_acessibilidade_android');
    $web->get('acessibilidade-ios')->to(action => 'web_acessibilidade_ios');
    $web->get('permisoes-e-contas')->to(action => 'web_permisoes_e_contas');


    # GET /web/politica-privacidade
    $web->get('politica-privacidade')->to(action => 'web_politica_privacidade');

    # /available-tickets-timeline/
    $r->under('available-tickets-timeline')->get()
      ->to(controller => 'Tickets', action => 'public_available_tickets_timeline_get');


    # GET /sobrelgpd
    $r->get('sobrelgpd')->to(controller => 'SobreLGPD', action => 'sobrelgpd_index_get');
    $r->get('sobrelgpd/:sobrelgpd_id')->to(controller => 'SobreLGPD', action => 'sobrelgpd_detail_get');

    # "public" - used for pdf generator from html
    my $internal_media_download
      = $r->get('internal-media-download')->to(controller => 'MediaDownload', action => 'internal_get_media');

    # Admin endpoints

    # GET /admin/logout
    $r->get('admin/logout')->to(controller => 'Admin::Session', action => 'admin_logout');

    # /admin/login
    $r->post('admin/login')->to(controller => 'Admin::Session', action => 'admin_login');
    $r->get('admin/login')->to(controller => 'Admin::Session', action => 'admin_login_get');


    # /admin
    my $admin = $r->under('admin')->to(controller => 'Admin::Session', action => 'admin_check_authorization');
    $admin->get()->to(action => 'admin_dashboard');
    $admin->get('users')->to(controller => 'Admin::Users', action => 'au_search');
    $admin->post('schedule-delete')->to(controller => 'Admin::Users', action => 'au_schedule_delete');
    $admin->get('unschedule-delete')->to(controller => 'Admin::Users', action => 'au_unschedule_delete');

    $admin->post('add-notification')->to(controller => 'Admin::Notifications', action => 'unft_crud');
    $admin->get('add-notification')->to(controller => 'Admin::Notifications', action => 'unft_new_template');
    $admin->get('notifications-message-detail')->to(controller => 'Admin::Notifications', action => 'unft_explore');
    $admin->get('notifications')->to(controller => 'Admin::Notifications', action => 'unft_list');
    $admin->get('bignum')->to(controller => 'Admin::BigNum', action => 'abignum_get');

    $admin->get('tickets')->to(controller => 'Admin::Tickets', action => 'a_tickets_list_get');
    $admin->get('tickets-details')->to(controller => 'Admin::Tickets', action => 'a_tickets_detail_get_post');
    $admin->post('tickets-details')->to(controller => 'Admin::Tickets', action => 'a_tickets_detail_get_post');

    $admin->get('blockchains')->to(controller => 'Admin::Blockchain', action => 'a_blockchain_list_get');

    $admin->get('myacc')->to(controller => 'Admin::MyAccount', action => 'a_myacc_get');
    $admin->post('myacc-save')->to(controller => 'Admin::MyAccount', action => 'a_myacc_save_post');

    # /admin/media-download
    $admin->get('media-download')->to(controller => 'MediaDownload', action => 'admin_logged_in_get_media');


    # INTERNAL ENDPOINTS
    my $maintenance = $r->under('maintenance')->to(controller => 'Maintenance', action => 'check_authorization');

    # GET /maintenance/housekeeping
    $maintenance->get('housekeeping')->to(controller => 'Maintenance', action => 'housekeeping');

    # GET /maintenance/ping-db
    $maintenance->get('ping-db')->to(controller => 'Maintenance', action => 'housekeepingdb');

    # PRIVATE ENDPOINTS
    my $authenticated = $r->under()->to(controller => 'JWT', action => 'check_user_jwt');

    # POST /logout
    $authenticated->post('logout')->to(controller => 'Logout', action => 'logout_post');

    # POST /reactivate
    $authenticated->post('reactivate')->to(controller => 'Me', action => 'me_reactivate');

    # GET /me
    my $user_loaded = $authenticated->under('')->to(controller => 'Me', action => 'check_and_load');
    my $me          = $user_loaded->any('me');
    $me->get()->to(action => 'me_find');
    $me->put()->to(action => 'me_update');
    $me->delete()->to(action => 'me_delete');

    # GET /me/account-disable-text
    $me->get('account-disable-text')->to(controller => 'Me', action => 'me_disable_text');

    # GET /me/unread-notif-count // notifications
    $me->get('unread-notif-count')->to(controller => 'Me', action => 'me_unread_notif_count');

    # GET /me/notifications
    $me->get('notifications')->to(controller => 'Me', action => 'me_notifications');

    # /me/preferences
    my $me_pref = $me->under('preferences')->to(controller => 'Me_Preferences', action => 'assert_user_perms');
    $me_pref->get()->to(action => 'list_preferences');
    $me_pref->post()->to(action => 'post_preferences');


    # /me/quiz
    my $me_quiz = $me->under('quiz')->to(controller => 'Me_Quiz', action => 'assert_user_perms');
    $me_quiz->post()->to(action => 'quiz_process_post');
    $me_quiz->post('start')->to(action => 'start_quiz_post');
    $me_quiz->post('cancel')->to(action => 'cancel_quiz_post');

    # /me/media
    my $me_media = $me->under('media')->to(controller => 'Me_Media', action => 'assert_user_perms');
    $me_media->post()->to(action => 'mm_upload_post');

    # /tickets-timeline/
    my $timeline2
      = $authenticated->under('tickets-timeline')->to(controller => 'Tickets', action => 'assert_user_perms');
    $timeline2->get()->to(action => 'tickets_timeline_get');

    # /me/tickets/
    # GET /me/tickets/:ticket_id
    my $me_tickets_object
      = $me->under('/tickets/:ticket_id')->to(controller => 'Tickets', action => 'ticket_load_object');
    $me_tickets_object->get()->to(action => 'ticket_detail_get');
    $me_tickets_object->post('reply')->to(action => 'ticket_reply_post');


    # /media-download
    my $media_download
      = $authenticated->under('media-download')->to(controller => 'MediaDownload', action => 'assert_user_perms');
    $media_download->get()->to(action => 'logged_in_get_media');


}

1;
