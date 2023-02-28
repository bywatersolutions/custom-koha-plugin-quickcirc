package Koha::Plugin::Com::ByWaterSolutions::Quickcirc::Controller;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);
use Encode qw(encode_utf8);

use C4::Circulation qw( AddIssue AddReturn CanBookBeIssued );
use CGI;

use Koha::DateUtils qw( output_pref );

use Try::Tiny;

=head1 Koha::Plugin::Com::ByWaterSolutions::Quickcirc::Controller
A class implementing the controller code for Quickcirc
=head2 Class methods

=head3 circulate
Controller function that handles a quick circulation, i.e. return a scanned item unless there is
a hold on the item. In the case of a hold, issue the item to the patron with the reserve
=cut

sub circulate {
    my $c = shift->openapi->valid_input or return;

    my $barcode = $c->validation->param('body')->{'barcode'};

    my $item = Koha::Items->find({ barcode => $barcode });

    unless( $item ){
        return $c->render(
            status => 404,
            openapi => { error => "item_id not found." }
        );
    }

    return try {
		my ($doreturn, $messages, $issue) = C4::Circulation::AddReturn( $barcode );
        if( defined $messages->{'ResFound'} ){
            my $reserve = $messages->{'ResFound'};
            my $patron = Koha::Patrons->find({ borrowernumber => $reserve->{borrowernumber} });
			my $issue = C4::Circulation::AddIssue( $patron->unblessed, $barcode );
			# We don't pass a branch, rely on C4::Context->userenv
			# We don't exempt fines
			# We don't pass a return date, just use 'now'
			return $c->render( status => 200, openapi => {
                issue => {
                    date_due =>  output_pref({ str => $issue->date_due, as_due_date => 1 })
                },
                patron => {
                    cardnumber => $patron->cardnumber,
                    surname => $patron->surname,
                    firstname => $patron->firstname
                }
            }) if( $issue );
            # If we didn't issue, let's tell why
            my ( $issuingimpossible, $needsconfirmation, $alerts ) = C4::Circulation::CanBookBeIssued( $patron, $barcode );
			return $c->render( status => 500, openapi => { errors => [
                { error => "Item could not be issued." },
                { circ_messages => $messages },
                { impossible => $issuingimpossible },
                { confirmation => $needsconfirmation },
                { alerts => $alerts }
            ]});
		} else {
            # No hold, just let caller know what happened
		    return $c->render( status => 200, openapi => $messages );
		}

    }
    catch {
        $c->unhandled_exception($_);
    };
}

1;
