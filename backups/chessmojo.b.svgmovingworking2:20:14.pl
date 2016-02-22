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
	foreach (@pieces){ $_->setCoord( [ 9-$_->X, 9-$_->Y ] ) }
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
	reverseBoard();
		$svg = SVG->new();

		my $rowandcollabels = $svg->group( 'opacity'=>0.1, 'style'=>"font-size:1px" );
  		for my $x (1..8){ for my $y (0,9){ $rowandcollabels->text( 'id'=>"letter$x$y", 'x'=>($x+0.25), 'y'=>($y+0.84), 'onclick'=>"changerect(evt)" )->cdata($letters[$x-1]) } }
		for my $y (1..8){ for my $x (0,9){ $rowandcollabels->text( 'id'=>"number$x$y", 'x'=>($x+0.25), 'y'=>($y+0.84), 'onclick'=>"changerect(evt)"  )->cdata($y) } }

		our $whitesquares = $svg->group( 'fill'=>'yellow', 'opacity'=>0.6 );
		my $blacksquares = $svg->group( 'fill'=>'red', 'opacity'=>0.6 );
		for my $x (1..8){ for my $y (1..8){
			if( ($x+$y) % 2 == 0 ){ our $square = $whitesquares->rect( 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1 ); our $popcorn; }
			if( ($x+$y) % 2 == 1 ){ $blacksquares->rect( 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1 ) }
		}}

		my $pieces = $svg->group( 'id'=>'pieces' );
		foreach (@pieces){ $_->createSVGInGroup( $pieces ) }
	reverseBoard();
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

      print caller . "\n";


			$hash->{id} = 0;
			#$main::popcorn = 2;
			#$main::square = $svg->group( 'x'=>9 );
			$hash->{stuff} = " Gotandsend back $hash->{stuff} ♥ ";
			$hash->{alert} = "gotmessage";
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

%#<script src="myscripts.js"></script>

%#		%= javascript begin


%#		% end
	</head>

%###################################### HTML (BODY) ######################################
	<body>
		<div id="container"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 10 10">
			<script type="text/javascript"><![CDATA[




			function changerect(evt,id) {
					var svgobj=evt.target;
					alert('object is:'+svgobj+'. And ID is:'+id);
					svgobj.style.opacity= 0.3;
					%#svgobj.setAttribute ('x', 2);
					document.getElementById(id).setAttribute('x',7);
				}



			var ws;
			if ("WebSocket" in window) { ws = new WebSocket('<%= url_for('chesssocket')->to_abs %>'); }
			if(typeof(ws) !== 'undefined') {
				function mysend (string) {
						ws.send(JSON.stringify({stuff: string}));
						%#a JSON hash {a:b} is {a=>b}
				};
				ws.onmessage = function (event) {
          var json = JSON.parse(event.data);

					%#idofsquare from event.data
					%#document.idofsquare = blue
					%#or
					%#document.body.divContainer = 'funcsvg()' (this would redo ALL svg stuff)
					%#or
					%#alter the CSS to recolor boxes.  This would not be capable of moving pieces, so i don't like this method.
					%#document.getElementById('container').innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 10 10">' + json.stuff + '</svg>';

%#					alert('before ('+json.id+')...');
					document.getElementById( json.id ).x = 300;
					document.getElementById( json.id ).style = "fill:blue";
					document.getElementById('container').innerHTML += ' Id is '+json.id+'.';
%#					alert('...and after ('+json.alert+').');

				};
				ws.onopen = function (event) {
					mysend('WebSocket support works! ♥');
				};
			}
			else {
				document.body.innerHTML += 'Browser does not support WebSockets.';
			}





			]]></script>
			<%== main::getSVG() %>
		</svg></div>
	</body>
</html>
