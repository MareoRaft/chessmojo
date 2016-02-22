#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/";
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../Mojolicious-4.81/lib";
use chesspiece;
use Mojolicious::Lite;
use Mojolicious::Static;
use Mojo::IOLoop;
use SVG;

##################################### DEFAULT VARIABLES ##################################
our @pieces = ();
our $turn = chesspiece->new( 'color'=>'white', 'type'=>'king' );
our $lastclickedpiece;
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

	#1. if coord in options, move
	if( defined $lastclickedpiece && isEl($coord,$lastclickedpiece->options) ){
		# if so, move the piece and switch turn
		@$hash{qw(command ID x y lastclickedoptions)} = ('movepiece', $lastclickedpiece->ID, $$coord[0], 9-$$coord[1], $lastclickedpiece->optionIDs);

		if( chesspiece::isAPieceOn($coord) ){ # this must be done AFTER retrieving lastclickedpiece->optionIDs because the options can be based on where the enemy is (pawns)
			$$hash{'IDtoremove'} = deletePieceOnCoord($coord)
		}

		#$" = ',';
		#moved $lcp->ID from [$lcp->X,$lcp->Y] to @$coord...

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

		#...and removed $$hash{'IDtoremove'} or nothing

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
else{ @$hash{qw(command message)} = ('didntclickasquare', 'webscoektmessage!') }




			$self->send({json => $hash});
		}
	);
};

#get '/' => sub {
#  my $self = shift;
#  $self->res->headers->cache_control('max-age=1, no-cache');
#  $self->render(template => 'websocket');
#};

my $static = Mojolicious::Static->new;
push @{$static->paths}, "$FindBin::Bin/";

app->start;
