package piece;

use strict;
use warnings;

use move;
use room;

$\ = "\n";

#################################### HELPER FUNCTIONS ####################################
use overload
	'""' => \&stringify;
use Scalar::Util 'refaddr';

sub removeSelf{
	my ( $coord, @set ) = @_;
	my $i = 0; while( $i <= $#set ){
		if( $coord ~~ $set[$i]->toCoord ){ splice @set, $i, 1 }
		else{ ++$i }
	}
	return @set;
}

sub isEl{
	my $coord = shift;
	my @moves = @_;
	for my $move (@moves){ if( $coord ~~ $move->toCoord ){ return $move } }
	return 0
}

######################################### PIECE ##########################################
sub new{
	my $packagename = shift;
	my $uniqueID = $#mojo::pieces + 1; # Each piece's ID is it's index in @pieces.
	bless { 'ID'=>$uniqueID, 'type'=>'queen', 'coord'=>[0,0], 'color'=>'white', @_ } => $packagename
}

sub copy{
	my $piece = shift;
	bless { %$piece } => 'piece';
}

sub ID{
	my $piece = shift;
	return $$piece{'ID'}
}
sub type{
	my $piece = shift;
	return $$piece{'type'}
}

sub coord{
	my $piece = shift;
	return $$piece{'coord'}
}
sub setCoord{
	my $piece = shift;
	my ($coord) = @_;
	$$piece{'coord'} = $coord
}

sub X{
	my $piece = shift;
	return ${$piece->coord}[0]
}
sub Y{
	my $piece = shift;
	return ${$piece->coord}[1]
}

sub color{
	my $piece = shift;
	return $$piece{'color'}
}
sub otherColor{
	my $piece = shift;
	if( $piece->color eq 'white' ){ return 'black' }
	return 'white'
}
sub switchColor{
	my $piece = shift;
	$$piece{'color'} = $piece->otherColor
}
sub myTurn{
	my $piece = shift;
	if( $piece->color eq $mojo::turn->color ){ return 1 }
	return 0
}

sub isCoordOnBoard{
	my ($coord) = @_;
	my $X = $$coord[0];
	my $Y = $$coord[1];
	if( $X >= 1 and $Y >=1 and $X <= 8 and $Y <=8 ){ return 1 }
	return 0
}
sub isOnBoard{
	my $piece = shift;
	return isCoordOnBoard( $piece->coord )
}

sub onlyWhatsOnBoard{
	my @moves = @_;
		my $i=0; while ($i <= $#moves){
			if(isCoordOnBoard($moves[$i]->toCoord)){ ++$i }
			else{ splice @moves, $i, 1 }
		}
	return @moves;
}

sub reverseMoves{ # by default this flips the y axis only (like 'y')
	my @moves = @_;
		foreach (@moves){
			$_->setFromCoord([ $_->fromX, 9-$_->fromY ]); $_->setToCoord([ $_->toX, 9-$_->toY ]);
			if( defined $_->coMove ){ reverseMoves($_->coMove) }
		}
	return @moves
}

sub isAPieceOn{
	my ($coord) = @_;
	foreach (@mojo::pieces){ if( @$coord ~~ @{$_->coord} ){ return $_ } }
	return 0
}

sub isAnEnemyOn{
	my $piece = shift;
	my ($coord) = @_;
	foreach (@mojo::pieces){ if(   @$coord ~~ @{$_->coord}   &&   $piece->color ne $_->color   ){ return $_ } }
	#print "will return 0\n";
	return 0
}

sub isAFriendOn{
	my $piece = shift;
	my ($coord) = @_;
	foreach (@mojo::pieces){ if(   @$coord ~~ @{$_->coord}   &&   $piece->color eq $_->color   ){ return $_ } }
	return 0
}

sub isCoordInCheck{ # even though we are looking at a coord, we need to know in check by WHICH SIDE, therefore the $piece->color.
	my $piece = shift;
	my ($coord) = @_;
	foreach (@mojo::pieces){ if( $_->color ne $piece->color and isEl($coord,$_->moves('nocastle'))){ return 1 } } # must exclude castle moves to prevent infinite loop
	return 0
}

sub isValidEnPassant{ # takes in the space where we would find the ENEMY
	my $piece = shift;
	my ($coordofenemy) = @_;
	if( my $enemy = $piece->isAnEnemyOn($coordofenemy) ){
		my $lastmove = $mojo::moves[-1];
		# references numify to their addresses, so we can check for equality like so:
		if( refaddr($lastmove->piece)==refaddr($enemy) and $lastmove->moveType eq 'jump' ){ return $enemy }
	}
	return 0
}

sub qualifyIndividualMoves{
	my $piece = shift;
	my @individualmoves = @_;
	my $i = 0; while( $i <= $#individualmoves ){
		if( $piece->isAFriendOn($individualmoves[$i]) ){ splice @individualmoves, $i, 1 }
		else{ ++$i }
	}
	return @individualmoves
}

sub qualifyLineOfMoves{
	my $piece = shift;
	my @lineofmoves = @_;
	my $state = 'before';
	for( my $i=0; $i<=$#lineofmoves; ++$i ){ #print "color is ",$piece->color," and coord is ",${$piece->coord}[0],',',${$piece->coord}[1]; print "linemoves are "; foreach(@lineofmoves){print "[$$_[0],$$_[1]]" } print " i is $i.\n";
		if( $lineofmoves[$i] ~~ $piece->coord ){ $state = 'after'; }#print "state is $state\n"; }
		elsif( $piece->isAFriendOn($lineofmoves[$i]) && $state eq 'before' ){ splice @lineofmoves, 0, $i+1; $i=-1; }#print "\tfound friend, state=before.\n"; }
		elsif( $piece->isAnEnemyOn($lineofmoves[$i]) && $state eq 'before' ){ splice @lineofmoves, 0, $i; $i=0; }#print "\tfound enemy, state=before.\n"; }
		elsif( $piece->isAFriendOn($lineofmoves[$i]) && $state eq 'after' ){  splice @lineofmoves, $i; last }#print "\tfound friend, state=after.\n";
		elsif( $piece->isAnEnemyOn($lineofmoves[$i]) && $state eq 'after' ){ splice @lineofmoves, $i+1; last }#print "\tfound enemy, state=after.\n";
		#<STDIN>;
	}
	return @lineofmoves;
}

sub pawnMoves{ # for white pawns specifically
	my $piece = shift;
	my @moves; my $enemy;
		push @moves, move->new( 'piece'=>$piece, 'tocoord'=>[$piece->X,$piece->Y+1], 'movetype'=>'step' ) if !isAPieceOn( [ $piece->X, $piece->Y+1 ] );
		push @moves, move->new( 'piece'=>$piece, 'tocoord'=>[$piece->X,$piece->Y+2], 'movetype'=>'jump' ) if $piece->Y==2 and !isAPieceOn( [ $piece->X, $piece->Y+2 ] ) and !isAPieceOn( [ $piece->X, $piece->Y+1 ] );#jump 2 first move only

		push @moves, [ $piece->X+1, $piece->Y+1 ] if $piece->isAnEnemyOn( [$piece->X+1,$piece->Y+1] ); #capture diagonally right
		push @moves, [ $piece->X-1, $piece->Y+1 ] if $piece->isAnEnemyOn( [$piece->X-1,$piece->Y+1] ); #capture diaganolly left
		push @moves, move->new( 'piece'=>$piece, 'tocoord'=>[$piece->X+1,$piece->Y+1], 'piecetoremove'=>$enemy, 'movetype'=>'enpassant' ) if $enemy = $piece->isValidEnPassant([$piece->X+1,$piece->Y]);
		push @moves, move->new( 'piece'=>$piece, 'tocoord'=>[$piece->X-1,$piece->Y+1], 'piecetoremove'=>$enemy, 'movetype'=>'enpassant' ) if $enemy = $piece->isValidEnPassant([$piece->X-1,$piece->Y]);
	return @moves
}

sub canCastleLeft{ # we will disqualify castling at the moment of king or rook movement, not in this function
	my $piece = shift;
	my $room = shift;
	if( $room->canCastle($piece->color,'left') ){ print "vargood";
		for my $x (2..4){ if( isAPieceOn([$x,1]) ){ print "piceon $x,1"; return 0 } }
		for my $x (1..5){ if( $piece->isCoordInCheck([$x,1]) ){ print "coord $x,1 in check"; return 0 } }
		print "returning1"; return mojo::coordToPiece([1,1])
	}
	print "atend"; return 0
}

sub canCastleRight{ # we will disqualify castling at the moment of king or rook movement, not in this function
	my $piece = shift;
	my $room = shift;
	if( $cancastle{$piece->color}{'right'} ){ print "vargood";
		for my $x (6..7){ if( isAPieceOn([$x,1]) ){ print "piceon $x,1"; return 0 } }
		for my $x (5..8){ if( $piece->isCoordInCheck([$x,1]) ){ print "coord $x,1 in check"; return 0 } }
		print "returning1"; return mojo::coordToPiece([8,1])
	}
	print "atend"; return 0
}

sub castleMoves{ # for white kings specifically
	my $king = shift;
	my $room = shift;
	my @moves;
		if( my $rook = $king->canCastleLeft($room) ){
			my $castlemove = move->new( 'piece'=>$rook, 'tocoord'=>[4,1] );
			push @moves, move->new( 'piece'=>$king, 'tocoord'=>[3,1], 'movetype'=>'castle', 'comove'=>$castlemove )
		}
		if( my $rook = $king->canCastleRight($room) ){
			my $castlemove = move->new( 'piece'=>$rook, 'tocoord'=>[6,1] );
			push @moves, move->new( 'piece'=>$king, 'tocoord'=>[7,1], 'movetype'=>'castle', 'comove'=>$castlemove )
		}
	return @moves
}

sub coordsToMoves{
	my $piece = shift;
	my @possiblecoords = @_;
	# if it's a coord, make it a move. otherwise, it is already a move so do nothing.
	foreach (@possiblecoords){ if( ref($_) eq 'ARRAY' ){ $_ = move->new( 'piece'=>$piece, 'tocoord'=>$_ ) } }
	return @possiblecoords
}

sub whiteMoves{
	my $piece = shift;
	my ($nocastle) = @_;
	my @moves; my @lineofmoves; my @individualmoves;
		if( $piece->type eq 'rook' || $piece->type eq 'queen' ){
			@lineofmoves=(); for my $x (1..8){ push @lineofmoves, [$x,$piece->Y] } push @moves, $piece->qualifyLineOfMoves(@lineofmoves);
			@lineofmoves=(); for my $y (1..8){ push @lineofmoves, [$piece->X,$y] } push @moves, $piece->qualifyLineOfMoves(@lineofmoves);
		}
		if( $piece->type eq 'bishop' || $piece->type eq 'queen' ){ #IF, not ELSIF
			@lineofmoves=(); for my $x (1..8){ push @lineofmoves, [$x,$x - $piece->X + $piece->Y] } push @moves, $piece->qualifyLineOfMoves(@lineofmoves);
			@lineofmoves=(); for my $x (1..8){ push @lineofmoves, [$x,$piece->X + $piece->Y - $x] } push @moves, $piece->qualifyLineOfMoves(@lineofmoves);
		}
		elsif( $piece->type eq 'knight' ){
			for my $dx (-2,2){ for my $dy (-1,1){ push @individualmoves, [ $piece->X+$dx, $piece->Y+$dy ] } }
			for my $dy (-2,2){ for my $dx (-1,1){ push @individualmoves, [ $piece->X+$dx, $piece->Y+$dy ] } }
			@moves = $piece->qualifyIndividualMoves(@individualmoves);
		}
		elsif( $piece->type eq 'pawn' ){
			@moves = $piece->pawnMoves
		}
		elsif( $piece->type eq 'king' ){
			for my $dx (-1,0,1){ for my $dy (-1,0,1){ push @individualmoves, [ $piece->X+$dx, $piece->Y+$dy ] } }
			@moves = $piece->qualifyIndividualMoves(@individualmoves);
			#print "before";
			push @moves, $piece->castleMoves($room) unless defined $nocastle;
			#print "after";
		}
	#print "\n moves before: @moves\n\n";
	@moves = $piece->coordsToMoves(@moves);
	#print "\n moves as moves: @moves\n\n";
	@moves = onlyWhatsOnBoard(@moves);
	#print "\n moves after what's on board: @moves\n\n";
	@moves = removeSelf($piece->coord,@moves);
	#print "\n moves after remove: @moves\n\n";
	return @moves
}

sub moves{ # moves are moves!
	my $piece = shift;
	my ($nocastle) = @_;
	my @moves;
	if( $piece->isOnBoard ){
		if( $piece->color eq 'white' ){
			@moves = $piece->whiteMoves($nocastle)
		}
		elsif( $piece->color eq 'black' ){
			mojo::reverseBoard('y'); @moves = reverseMoves($piece->whiteMoves($nocastle)); mojo::reverseBoard('y')
		}
	}
	return @moves
}

sub moveIDs{
	my $piece = shift;
	my @moves = $piece->moves;
		foreach (@moves){ $_ = 'square'.$_->toX.$_->toY }
	return \@moves
}

sub stringify{
	my $piece = shift;
	my $toprint = 'ID: '.$piece->ID.'. A '.$piece->color.' '.$piece->type.' has position ['.$piece->X.','.$piece->Y.']. And '.($piece->isOnBoard? 'is': 'is not')." on the board. Moves...\n";
	$toprint .= "OPTIONStempremoved:\n";
	#foreach( $piece->moves ){ $toprint .= join(',',@$_)."\n" }
	return $toprint
}

1
