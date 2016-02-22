use Mojolicious::Lite; #use strict; #use warnings; # this caused "redefinition of 'new'" error when stated within the package

package room;

use piece;
use move;
use set;

#################################### HELPER FUNCTIONS ####################################

######################################## NEW ROOM ########################################
sub new{
	my $classname = shift;
	my %options = @_;
	my $room = bless {
		'controllers' => set->new, # a set of mojolicious controllers, one for each websocket connection
		'pieces' => [],
		'moves' => [],
		'cancastle' => {
			'white' => { 'left'=>1, 'right'=>1 },
			'black' => { 'left'=>1, 'right'=>1 }
		},
		'turn' => piece->new( 'color'=>'white', 'type'=>'king' ),
		'lcpiece' => '', # last clicked piece
		%options
	} => $classname;
	$room->defineStartPieces();
	return $room
}

######################################## STANDARD ########################################
sub piecesRef{
	my $room = shift;
	return $$room{'pieces'}
}
sub pieces{
	my $room = shift;
	return @{$room->piecesRef}
}
sub movesRef{
	my $room = shift;
	return $$room{'moves'}
}
sub moves{
	my $room = shift;
	return @{$room->movesRef}
}
sub controllersSet{
	my $room = shift;
	return $room->{'controllers'}
}
sub controllers{
	my $room = shift;
	return $room->controllersSet->elements
}
sub turn{
	my $room = shift;
	return $$room{'turn'}
}
sub LCPiece{
	my $room = shift;
	return $$room{'lcpiece'}
}

sub pushPieces{
	my $room = shift; #print "pushPieces input is @_";
	my @pieces = @_;
	push @{$room->piecesRef}, @pieces;
}
sub pushMoves{
	my $room = shift;
	my @moves = @_;
	push @{$room->movesRef}, @moves;
}
sub popMoves{
	my $room = shift;
	return pop @{$room->movesRef}
}
*popMove = \&popMoves;
sub addController{
	my $room = shift;
	my ($controller) = @_;
	$room->controllersSet->addElement($controller)
}
sub removeController{
	my $room = shift;
	my ($controller) = @_;
	$room->controllersSet->removeElement($controller)
}

sub setLCPiece{
	my $room = shift;
	my ($lcpiece) = @_;
	$$room{'lcpiece'} = $lcpiece;
}

sub canCastle{
	my $room = shift;
	my ($color,$side) = @_;
	return $$room{'cancastle'}{$color}{$side}
}
sub cannotCastle{
	my $room = shift;
	my ($color,$side) = @_;
	$$room{'cancastle'}{$color}{$side} = 0
}

######################################### UNIQUE #########################################
sub reverseBoard{
	my $room = shift;
	my $y = ($_[0] or '');
	if( $y eq 'y' ){ foreach ($room->pieces){ $_->setCoord( [ $_->X, 9-$_->Y ] ) } }
	else{
		foreach ($room->pieces){ $_->setCoord( [ 9-$_->X, 9-$_->Y ] ) }
	}
}

sub definePieceAndEnemy{
	my $room = shift; #print "indefinePieceAndEnemy";
	my ($x,$y,%options) = @_;
	$room->pushPieces( piece->new( %options, 'room'=>$room, 'color'=>'white', 'coord'=>[$x,$y] ) );
	$room->pushPieces( piece->new( %options, 'room'=>$room, 'color'=>'black', 'coord'=>[$x,9-$y] ) );
}
sub defineStartPieces{
	my $room = shift;
=pod
	$room->definePieceAndEnemy( 5, 1, 'type'=>'king');
	$room->definePieceAndEnemy( 4, 1, 'type'=>'queen');
	for my $x (1,8){ $room->definePieceAndEnemy( $x, 1, 'type'=>'rook' ) }
	for my $x (2,7){ $room->definePieceAndEnemy( $x, 1, 'type'=>'knight') }
	for my $x (3,6){ $room->definePieceAndEnemy( $x, 1, 'type'=>'bishop') }
	for my $x (1..8){ $room->definePieceAndEnemy( $x, 2, 'type'=>'pawn') }
=cut
	$room->definePieceAndEnemy( 4, 4, 'type'=>'queen');
	$room->definePieceAndEnemy( 3, 4, 'type'=>'pawn');
	$room->definePieceAndEnemy( 5, 4, 'type'=>'pawn');
}

sub coordToPiece{
	my $room = shift;
	my ($coord) = @_;
	foreach ($room->pieces){ if( @$coord ~~ @{$_->coord} ){ return $_ } }
	return 0
}
sub deletePieceOnCoord{
	my $room = shift;
	my ($coord) = @_;
	my $enemy = $room->coordToPiece($coord);
	$enemy->setCoord([-1,-1]);
	return $enemy
}

sub blast{
	my $room = shift;
	my ($inforef) = @_;
	$_->send($inforef) foreach ($room->controllers);
}
sub makeMove{
	my $room = shift;
	my ($move) = @_;
	my $piece = $move->piece;
	my %ball;
	# NOT SURE IF THIS NEXT LINE IS RIGHT.  IT WAS LEFT OUT BEFORE, BUT SEEMS NECESSARY!
		if( defined $move->pieceToRemove ){ $move->pieceToRemove->setCoord([-1,-1]) }
		elsif( $piece->isAnEnemyOn($move->toCoord) ){
			my $piecetoremove = $room->deletePieceOnCoord($move->toCoord);
			$move->setPieceToRemove($piecetoremove);
		}
	#BEFORE WE JUST HAD:
=pod
		if( !defined $move->pieceToRemove and $piece->isAnEnemyOn($move->toCoord) ){
			my $piecetoremove = $room->deletePieceOnCoord($move->toCoord);
			$move->setPieceToRemove($piecetoremove);
		}
=cut

		# perl data itself
			$piece->setCoord($move->toCoord);

		# to notation record
			$room->pushMoves( $move );

		# to javascript (we pass a ball back and forth between JS and Perl)
			@ball{qw(command ID x y message)} = ('movepiece', $piece->ID, $move->toX, $move->toY, $move->humanNotation);
			$ball{'IDtoremove'} = $move->pieceToRemove->ID if defined $move->pieceToRemove;

	if( $piece->type eq 'king' ){ $room->cannotCastle($piece->color,'left') and $room->cannotCastle($piece->color,'right') }
	elsif( $piece->type eq 'rook' ){
		if( $piece->X == 1 ){ $room->cannotcastle($piece->color,'left') }
		elsif( $piece->X == 8 ){ $room->cannotCastle($piece->color,'right') }
	}

	if( defined $move->coMove ){
		my %comoveball = $room->makeMove( $move->coMove );
		$room->blast({json => \%comoveball});
	}
	else{ $room->turn->switchColor }

	return %ball
}
sub squareClicked{
	my $room = shift;
	my ($self,%ball) = @_;
	my $coord = [ $ball{'x'}, $ball{'y'} ];
	my $piece;
	# before proceeding, make sure it's your turn!
	if( $self->stash('color') ne $room->turn->color ){
		@ball{qw(command message)} = ('donothing', 'It is '.$room->turn->color."'s turn and you are ".$self->stash('color').'.');
		$self->send({json => \%ball});
	}
	#1. if coord is piece of whose turn it is, display moves
	elsif( $piece = $room->coordToPiece($coord) and $piece->myTurn ){
		@ball{qw(command moves)} = ('fillsquares', $piece->moveIDs); #print 'yo'; my $l = $piece->moves; print $l; print @{$piece->moveIDs}; #foreach (@{$piece->moves}){ print $_->humanNotation };
		$room->setLCPiece( $piece ); # this is NOT a copy, it IS the piece, b/c objects are references.
		$self->send({json => \%ball});
	}
	#2. if coord in moves of the last clicked piece, move
	elsif( $room->LCPiece and $room->LCPiece->myTurn and my $move = piece::isEl($coord,$room->LCPiece->moves) ){
		%ball = $room->makeMove( $move );
		$self->stash('room')->blast({json => \%ball});
	}
	#3. nothing meaningful was clicked
	else{
		@ball{qw(command message)} = ('donothing', 'It is '.$room->turn->color.q('s turn and ).$room->turn->color.' cannot move there.');
		$self->send({json => \%ball});
	}
}

use overload
	'""' => \&stringify;

sub stringify{
	my $room = shift;
	my $toprint;
	{
	local $" = ',';
		my @controllers = $room->controllers; $toprint .= "Controllers are: @controllers";
		my @pieces = $room->pieces; $toprint .= "pieces are: @pieces";
	}
	return $toprint
}

1
