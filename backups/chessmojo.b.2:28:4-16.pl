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
#our %colortofill = (
#	'white' => "#baeeee",
#	'black' => "#101010"
#);
my @letters = qw(a b c d e f g h);
my $svg;

##################################### HELPER FUNCTIONS ###################################
sub isEl{
	my $ref = shift;
	foreach (@_){ if( $ref ~~ $_ ){ return 1 } }
	return 0
}

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
  		for my $x (1..8){ for my $y (0,9){ $id = "letter$x$y"; $rowandcollabels->text( 'x'=>($x+0.25), 'y'=>(9-$y+0.84), 'onclick'=>qq(sendID(evt,"$id")) )->cdata($letters[$x-1]) } }
		for my $y (1..8){ for my $x (0,9){ $id = "number$x$y"; $rowandcollabels->text( 'x'=>($x+0.25), 'y'=>(9-$y+0.84), 'onclick'=>qq(sendID(evt,"$id"))  )->cdata($y) } }

		my $whitesquares = $svg->group( 'fill'=>"#4dffff", 'opacity'=>1 );
		my $blacksquares = $svg->group( 'fill'=>"#4d4dff", 'opacity'=>1 );
		for my $x (1..8){ for my $y (1..8){
			if( ($x+$y) % 2 == 0 ){ $id = $x.(9-$y); $whitesquares->rect( 'ID'=>"square$id", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1, 'onclick'=>"sendID(evt)" ) }
			if( ($x+$y) % 2 == 1 ){ $id = $x.(9-$y); $blacksquares->rect( 'ID'=>"square$id", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1, 'onclick'=>"sendID(evt)" ) }
		}}

		my $pieces = $svg->group( 'ID'=>'pieces', 'pointer-events'=>'none' );
		foreach (@pieces){ $_->createSVGInGroup( $pieces ) }
	reverseBoard('y');
}

sub coordToPiece{
	my ($coord) = @_;
	foreach (@pieces){ if( @$coord ~~ @{$_->coord} ){ return $_ } }
	return 0
}

sub deletePieceOnCoord{
	my ($coord) = @_;
	my $enemy = coordToPiece($coord);
	$enemy->setCoord([0,0]);
	return $enemy->ID
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



if( $$hash{'command'} eq 'squareclicked' ){
	#input
	my $coord = [$$hash{'x'},9-$$hash{'y'}];
	my $piece;
print "before\n";
	#1. if coord in options, move
	#if( defined $lastclickedpiece ){ $$hash{'message'} = "[$$hash{'x'},9-$$hash{'y'}] in ".Data::Dumper->Dump([$lastclickedpiece->options], [qw(*lastclickedpiece)]) }
	if( defined $lastclickedpiece && isEl($coord,$lastclickedpiece->options) ){
		# if so, move the piece and switch turn
		@$hash{qw(command ID x y lastclickedoptions)} = ('movepiece', $lastclickedpiece->ID, $$coord[0], 9-$$coord[1], $lastclickedpiece->optionIDs);

		if( chesspiece::isAPieceOn($coord) ){ # this must be done AFTER retrieving lastclickedpiece->optionIDs because the options can be based on where the enemy is (pawns)
			$$hash{'IDtoremove'} = deletePieceOnCoord($coord)
		}

		$lastclickedpiece->setCoord($coord); # this must be done AFTER populating hash since previous optionIDs are based on the previous coord of lastclickedpiece.

		my $lcp = $lastclickedpiece;
		# after moving a pawn, the only way somebody can end up behind him is if he just en-passanted
		if( $lcp->type eq 'pawn' ){
			if( $lcp->color eq 'white' and chesspiece::isAPieceOn([$lcp->X,$lcp->Y-1]) ){
				$$hash{'IDtoremove'} = deletePieceOnCoord([$lcp->X,$lcp->Y-1])
			}
			elsif( $lcp->color eq 'black' and chesspiece::isAPieceOn([$lcp->X,$lcp->Y+1]) ){
				$$hash{'IDtoremove'} = deletePieceOnCoord([$lcp->X,$lcp->Y+1])
			}
		}
		undef $lastclickedpiece;
		$turn->switchColor;
	}

	#2. if coord is piece of whose turn it is, displacy options
	elsif( $piece = coordToPiece($coord) and $piece->myTurn ){
		@$hash{qw(command options)} = ('fillsquares', $piece->optionIDs);
		if( defined $lastclickedpiece ){ $$hash{'lastclickedoptions'} = $lastclickedpiece->optionIDs; }
		$lastclickedpiece = $piece; # this is NOT a copy, it IS the piece, b/c objects are references.
	}
	else{
		@$hash{qw(command message)} = ('donothing', 'It is '.$turn->color.q('s turn and ).$turn->color.' cannot move there');
	}
}
else{ @$hash{qw(command message)} = ('donothing', 'webscoektmessage!') }

print "after\n";



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
			html, body{
				height: 100%;
				width: 100%;
				margin: 0px;
			}
			#container{
				%#position: absolute;
				%#height: 100%;
				%#width: 100%;
			}
			svg{
				position: absolute;
				height: 100%;
				width: 100%;
				%#-webkit-filter:invert(1);
			}
			path{
				stroke-width: 1.5;
			}
			.onepointsix{
				stroke-width: 1.6;
				stroke-linecap: round;
			}
			.none{
				fill: none;
			}
			.white{
				stroke: #fff;
				fill: #bcc;
				%#fill: <%==$main::colortofill{'white'}%>;
			}
			.black{
				stroke: #000;
				fill: #333;
			}
		</style>

%###################################### JAVASCRIPT #######################################
		%= javascript begin
			var ws
			if ("WebSocket" in window) { ws = new WebSocket('<%= url_for('chesssocket')->to_abs %>') }
			if(typeof(ws) !== 'undefined') {
				function sendID (evt) {
					x = evt.currentTarget.getAttribute('x')
					y = evt.currentTarget.getAttribute('y')
					ws.send( JSON.stringify({'command': 'squareclicked', 'x': x, 'y': y}) )
					document.getElementById('container').innerHTML += "<br />"
					%#document.getElementById('container').innerHTML += "id is "+ID+"<br />"
					document.getElementById('container').innerHTML += "target is "+evt.target+"<br />"
					document.getElementById('container').innerHTML += "currentTarget is "+evt.currentTarget+"<br />"
					document.getElementById('container').innerHTML += "x is "+evt.currentTarget.getAttribute('x')+"<br />"
					document.getElementById('container').innerHTML += "y is "+evt.currentTarget.getAttribute('y')+"<br />"
				}
				function sendmessage (evt,message) {
						ws.send(JSON.stringify({'command': 'donothing', 'message': message}))
				}
				ws.onmessage = function (event) {
					var json = JSON.parse(event.data)

					document.getElementById('container').innerHTML += ' Command is "'+json.command+'".'
					%#for (i=0; i<json.options.length; ++i){
					%#	document.getElementById('container').innerHTML += ' options['+i+'] is "'+json.options[i]+'".'
					%#}

					%# with this method, whenever i send the lastclickedoptions, therefore i want to erase them
					if( typeof(json.lastclickedoptions) !== 'undefined' ){
						for (i=0; i<json.lastclickedoptions.length; ++i){
							%# double quotes necessary
							document.getElementById(json.lastclickedoptions[i]).removeAttribute('style')
							%#document.getElementById(json.lastclickedoptions[i]).setAttribute('fill',"yellow")
						}
					}
					if( json.command=='fillsquares' ){
						for (i=0; i<json.options.length; ++i){
							%# double quotes necessary
							document.getElementById(json.options[i]).setAttribute('style',"opacity:0.5")
						}
					}

					if( json.command=='movepiece' ){
						%#alert('moving piece')
						document.getElementById(json.ID).setAttribute('x',json.x)
						document.getElementById(json.ID).setAttribute('y',json.y)
					}
					if( typeof(json.IDtoremove) !== 'undefined' ){
						document.getElementById(json.IDtoremove).setAttribute('x',-1)
						document.getElementById(json.IDtoremove).setAttribute('y',-1)
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
		<div style="float:left;background:yellow;width:33%;height:100%" >
			Hello there<br />
			I'm a div and my height it sad.
		</div>
		<div id="container"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 10 10">
			<defs>
				<filter id="invert">
					<feColorMatrix in="SourceGraphic" type="matrix" values="-1 0 0 0 1
                        													0 -1 0 0 1
                                    				                    	0 0 -1 0 1
                                                    	 					0 0 0 -1 0"/>
            	</filter>
            </defs>
			<%== main::getSVG() %>
		</svg></div>
	</body>
</html>
