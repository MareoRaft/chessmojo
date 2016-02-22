#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/";
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../Mojolicious-4.81/lib";
use chesspiece;
use Mojolicious::Lite;
use Mojo::IOLoop;
use SVG;

##################################### DEFAULT VARIABLES ##################################
our @pieces = ();
our %colortofill = (
	'white' => "#eee",
	'black' => "#451111"
);
my @letters = qw(a b c d e f g h);
my $svg;

##################################### HELPER FUNCTIONS ###################################
sub reverseBoard{
#	my $y = ($_[0] or '');
#	if( $y eq 'y' ){ foreach (@pieces){ $_->setCoord( [ $_->X, 9-$_->Y ] ) } }
#	else{
		foreach (@pieces){ $_->setCoord( [ 9-$_->X, 9-$_->Y ] ) }
#	}
}

sub definePieceAndEnemy{
	my ($x,$y,%options) = @_;
	push @pieces, chesspiece->new( %options, 'color'=>'white', 'coord'=>[$x,$y] );
	push @pieces, chesspiece->new( %options, 'color'=>'black', 'coord'=>[$x,9-$y] );
}

sub defineStartPieces{
	for my $x (1,8){ definePieceAndEnemy( $x, 1, 'type'=>'rook' ) }
	for my $x (2,7){ definePieceAndEnemy( $x, 1, 'type'=>'knight') }
	for my $x (3,6){ definePieceAndEnemy( $x, 1, 'type'=>'bishop') }
	for my $x (4){ definePieceAndEnemy( $x, 1, 'type'=>'queen') }
	for my $x (5){ definePieceAndEnemy( $x, 1, 'type'=>'king') }
	for my $x (1..8){ definePieceAndEnemy( $x, 2, 'type'=>'pawn') }
}

sub defineSVG{
	reverseBoard('y');
		$svg = SVG->new();

		my $rowandcollabels = $svg->group( 'opacity'=>0.1, 'style'=>"font-size:1px" );
  		for my $x (1..8){ for my $y (0,9){ $rowandcollabels->text( 'id'=>"letter$x$y", 'x'=>($x+0.25), 'y'=>($y+0.84), 'onclick'=>"sendid(evt,id)" )->cdata($letters[$x-1]) } }
		for my $y (1..8){ for my $x (0,9){ $rowandcollabels->text( 'id'=>"number$x$y", 'x'=>($x+0.25), 'y'=>($y+0.84), 'onclick'=>"sendid(evt,id)"  )->cdata($y) } }

		our $whitesquares = $svg->group( 'fill'=>'yellow', 'opacity'=>0.6 );
		my $blacksquares = $svg->group( 'fill'=>'red', 'opacity'=>0.6 );
		for my $x (1..8){ for my $y (1..8){
			if( ($x+$y) % 2 == 0 ){ $whitesquares->rect( 'id'=>"square$x$y", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1 ) }
			if( ($x+$y) % 2 == 1 ){ $blacksquares->rect( 'id'=>"square$x$y", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1 ) }
		}}

		my $pieces = $svg->group( 'id'=>'pieces' );
		foreach (@pieces){ $_->createSVGInGroup( $pieces ) }
	reverseBoard('y');
}

########################################## MAIN ##########################################
defineStartPieces();

defineSVG();

foreach (@pieces){ print "$_\n" }







###################################### WEBSOCKETING ######################################
sub getSVG{ $svg->xmlify }

#caller is Mojolicious::Controller.  Must specify main:: if you want that package...
websocket '/chesssocket' => sub {
	my $self = shift;
	print 'self has type ',ref($self),'.',"\n";
	Mojo::IOLoop->stream($self->tx->connection)->timeout(60*30);

	$self->on(
		json => sub {
    		my ($self, $hash) = @_;
			#      $whitesquares = $svg->group( 'fill'=>'green', 'opacity'=>0.6 );
			#make some change?

			#print caller . "\n";
			$hash->{'alert'} = "gotmessage";

#input
			#$hash->{'command'};
			#$hash->{'message'};
			#$hash->{'id'};
			#$hash->{'x'};
			#$hash->{'y'};
			#$hash->{'fill'};



#output
			$hash->{'command'} = "fillsquares";
			$hash->{'message'} = 'yo';
			$hash->{'id'} = "square56";
			$hash->{'x'} = 5;
			$hash->{'y'} = 6;
			$hash->{'fill'} = "#00e";



			$self->send({json => $hash});
		}
	);
};
get '/' => 'websocket';

app->start;

########################################### CSS ##########################################
__DATA__

@@ websocket.html.ep
<!DOCTYPE html>
<html>
	<head>
	    <title>Chessmojo</title>
		<style type="text/css">
			body{
				margin: 0px;
			}
			#container{
				position: absolute;
				height: 100%;
				width: 100%;
			}
			svg{
				position: absolute;
				height: 100%;
				width: 100%;
			}
		</style>

%###################################### JAVASCRIPT #######################################
		%= javascript begin
			var ws
			if ("WebSocket" in window) { ws = new WebSocket('<%= url_for('chesssocket')->to_abs %>') }
			if(typeof(ws) !== 'undefined') {
				function sendid (evt,id) {
						ws.send(JSON.stringify({'eventdata': evt.data, 'id': id}))
				}
				ws.onmessage = function (event,command,message,id,x,y,fill) {
					var json = JSON.parse(event.data)
					if( json.command=="fillsquares" ){

						document.getElementById(json.id).setAttribute('fill',json.fill)

					}
					else{

						document.getElementById('container').innerHTML += ' Message is "'+json.message+'".  Id is '+json.id+'. '

						document.getElementById(json.id).setAttribute('x',json.x)
						document.getElementById(json.id).setAttribute('y',json.y)
					}
				}
				ws.onopen = function (event) {
					sendid(event,'WebSocket support works! ♥')
				}
			}
			else {
				document.body.innerHTML += 'Browser does not support WebSockets.'
			}
		% end
	</head>

%###################################### HTML (BODY) ######################################
	<body>
		<div id="container"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 10 10">
			<%== main::getSVG() %>
		</svg></div>
	</body>
</html>
