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
our $turn = chesspiece->new( 'color'=>'white', 'type'=>'king' );
our $lastclickedpiece;
our %colortofill = (
	'white' => "#eee",
	'black' => "#451111"
);
my @letters = qw(a b c d e f g h);
my $svg;

##################################### HELPER FUNCTIONS ###################################
sub reverseBoard{
	my $y = ($_[0] or '');
	if( $y eq 'y' ){ foreach (@pieces){ $_->setCoord( [ $_->X, 9-$_->Y ] ) } }
	else{
		foreach (@pieces){ $_->setCoord( [ 9-$_->X, 9-$_->Y ] ) }
	}
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
		my $id;

		my $rowandcollabels = $svg->group( 'opacity'=>0.1, 'style'=>"font-size:1px" );
  		for my $x (1..8){ for my $y (0,9){ $id = "letter$x$y"; $rowandcollabels->text( 'ID'=>$id, 'x'=>($x+0.25), 'y'=>(9-$y+0.84), 'onclick'=>"sendID(evt,'$id')" )->cdata($letters[$x-1]) } }
		for my $y (1..8){ for my $x (0,9){ $id = "number$x$y"; $rowandcollabels->text( 'ID'=>$id, 'x'=>($x+0.25), 'y'=>(9-$y+0.84), 'onclick'=>"sendID(evt,'$id')"  )->cdata($y) } }

		my $whitesquares = $svg->group( 'fill'=>'yellow', 'opacity'=>0.6 );
		my $blacksquares = $svg->group( 'fill'=>'red', 'opacity'=>0.6 );
		for my $x (1..8){ for my $y (1..8){
			if( ($x+$y) % 2 == 0 ){ $id = $x.(9-$y); $whitesquares->rect( 'ID'=>"square$id", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1, 'onclick'=>"sendID(evt,$id)" ) }
			if( ($x+$y) % 2 == 1 ){ $id = $x.(9-$y); $blacksquares->rect( 'ID'=>"square$id", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1, 'onclick'=>"sendID(evt,$id)" ) }
		}}

		my $pieces = $svg->group( 'ID'=>'pieces' );
		foreach (@pieces){ $_->createSVGInGroup( $pieces ) }
	reverseBoard('y');
}

sub clickedCoord{
	my ($coord) = @_;
	if( $coord ~~ $lastclickedpiece->options ){ # check if it's one of the options of last clicked piece
		# if so, move the piece and switch turn
		my $piece = @pieces[$lastclickedpiece->ID];
		$piece->setCoord($coord);
		$turn->switchColor;
		#return qw(command ID x y)
		return ('movepiece', $piece->ID, $piece->X, $piece->Y);
	}
	return ('donothing');
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
	#tell mojolicious to not cache the page.

	$self->on(
		json => sub {
    		my ($self, $hash) = @_;



#input

			#check first if this is a piece's ID, if so,
			if( $$hash{'ID'} =~ /^\d+$/ ){ print "MATCH";
				my $piece = @pieces[$$hash{'ID'}]; $lastclickedpiece = $piece;
				if( $piece->myTurn ){
					$$hash{'options'} = $piece->optionIDs;
					$$hash{'command'} = "fillsquares";

				}
				# if it's a black piece and it's white's turn, act like a box (squareID)
				else{
					@$hash{qw(command ID x y)} = clickedCoord($piece->coord);
				}
			}
			elsif( $$hash{'ID'} =~ /^square(\d\d)$/ ){ @$hash{qw(command ID x y)} = clickedCoord([split '', $1]) }






#output
			$$hash{'message'} = "yo command is $$hash{'command'}";
			$$hash{'ID'} = "square56";
			$$hash{'x'} = 5;
			$$hash{'y'} = 6;
			$$hash{'fill'} = "#00e";



			$self->send({json => $hash});
		}
	);
};

get '/' => sub {
  my $self = shift;
  $self->res->headers->cache_control('max-age=1, no-cache');
  $self->render(template => 'websocket');
};

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
				function sendID (evt,ID) {
					ws.send(JSON.stringify({'eventdata': evt.data, 'ID': ID}))
					document.getElementById('container').innerHTML += "<br />"
					document.getElementById('container').innerHTML += "id is "+ID+"<br />"
					document.getElementById('container').innerHTML += "target is "+evt.target+"<br />"
					document.getElementById('container').innerHTML += "currentTarget is "+evt.currentTarget+"<br />"
				}
				function sendmessage (evt,message) {
						ws.send(JSON.stringify({'message': message}))
				}
				ws.onmessage = function (event,command,message,ID,x,y,fill) {
					var json = JSON.parse(event.data)
					document.getElementById('container').innerHTML += ' Message is "'+json.message+'".'

					document.getElementById('container').innerHTML += json.options[0]
					for (i=0; i<json.options.length; ++i){
						document.getElementById('container').innerHTML += ' options['+i+'] is "'+json.options[i]+'".'
					}

					if( json.command=="fillsquares" ){
						for (i=0; i<json.options.length; ++i){
							document.getElementById(json.options[i]).setAttribute('fill',json.fill)
						}
					}
					else{

						document.getElementById(json.ID).setAttribute('x',json.x)
						document.getElementById(json.ID).setAttribute('y',json.y)
					}
				}
				ws.onopen = function (event) {
					document.getElementById('container').innerHTML += ' onopen. '
					sendmessage(event,'WebSocket support works! ♥')
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
