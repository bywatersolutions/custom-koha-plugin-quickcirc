package Koha::Plugin::Com::ByWaterSolutions::Quickcirc;

use Modern::Perl;

use C4::Installer qw(TableExists);
use C4::Context qw(userenv);
use Koha::Patrons;

use JSON qw(decode_json);
use List::MoreUtils qw( any );

use base qw(Koha::Plugins::Base);

## Here we set our plugin version
our $VERSION         = "{VERSION}";
our $MINIMUM_VERSION = "24.05.00";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Quickcirc Plugin',
    author          => 'Nick Clemens',
    date_authored   => '2023-02-17',
    date_updated    => "2024-08-26",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description =>
      'This plugin adds a quick circulation box - when an item barcode is scanned the item will either checkout to a patron if there is a hold, or be returned otherwise',
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub install {
    my ( $self, $args ) = @_;
    my $dbh = C4::Context->dbh;
    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

sub uninstall() {
    my ( $self, $args ) = @_;

    return 1;
}

sub intranet_head {
    my ( $self ) =@_;

    return q|
        <style>
            .qc_checkout {
                color: #006100;
            }
            .qc_return {
                color: #CC0000;
            }
        </style>
        <div id="quickcirc_modal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="quickcirc-modal-label" aria-hidden="true">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="closebtn" data-dismiss="modal" aria-label="Close">x</button>
                        <h3 class="modal-title">Quick Circulation</h3>
                    </div>
                    <div class="modal-body">
                        <form id="quickcirc_form">
                            <fieldset>
                                <legend>Quick circ</legend>
                                <input id="qc_barcode" type="text" />
                                <button type="submit"><i class="fa fa-arrow-right"></i></button>
                                <p id="qc_error" class="error" style="display:none;"></p>
                            </fieldset>
                        </form>
                        <div id="#qc_results">
                           <ul id="qc_results_list">
                           </ul>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    |;
}

sub intranet_js {
    my ( $self ) = @_;

    return q|
    <script src="/api/v1/contrib/quickcirc/static/js/quickcirc.js"></script>
    |;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = { %{decode_json($spec_str)} };

    return $spec;
}

sub static_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('staticapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'quickcirc';
}

1;
