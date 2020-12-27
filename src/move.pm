package move;

use strict;
use warnings;

use piece;

#################################### HELPER FUNCTIONS ####################################
use overload
	'""' => \&humanNotation;

sub coordToChessNotation{
	my ($coord) = @_;
	return $mojo::letters[$$coord[0]-1].$$coord[1]
}

######################################### MOVE ###########################################
sub new{
	my $packagename = shift;
	my %options = @_;
		my $fromcoord = $options{'piece'}->coord; # needs to be frozen in time.
	#options are qw(piece fromcoord tocoord piecetoremove type)
	bless { 'fromcoord'=>$fromcoord, 'type'=>'regular', %options } => $packagename
}

sub coMove{
	my $move = shift;
	return $$move{'comove'}
}
sub setCoMove{
	my $move = shift;
	my $comove = move->new(@_);
	$$move{'comove'} = $comove;
}

sub piece{
	my $move = shift;
	return $$move{'piece'}
}
sub setPiece{
	my $move = shift;
	my ($piece) = @_;
	$$move{'piece'} = $piece;
}

sub type{
	my $move = shift;
	return $$move{'type'}
}
sub setType{
	my $move = shift;
	my ($type) = @_;
	$$move{'type'} = $type;
}

sub toCoord{
	my $move = shift;
	return $$move{'tocoord'}
}
sub setToCoord{
	my $move = shift;
	my ($coord) = @_;
	$$move{'tocoord'} = $coord;
}

sub fromCoord{
	my $move = shift;
	return $$move{'fromcoord'}
}
sub setFromCoord{
	my $move = shift;
	my ($coord) = @_;
	$$move{'fromcoord'} = $coord;
}

sub fromY{
	my $move = shift;
	return ${$move->fromCoord}[1]
}
sub toY{
	my $move = shift;
	return ${$move->toCoord}[1]
}
sub fromX{
	my $move = shift;
	return ${$move->fromCoord}[0]
}
sub toX{
	my $move = shift;
	return ${$move->toCoord}[0]
}

sub pieceToRemove{
	my $move = shift;
	return $$move{'piecetoremove'}
}
sub setPieceToRemove{
	my $move = shift;
	my ($piecetoremove) = @_;
	$$move{'piecetoremove'} = $piecetoremove;
}

sub checkForPromotion{
	my $move = shift;
	if( $move->toY == 8 ){ print 'prom!. '; $move->setType('promotion') } # all pieces are WHITE when we check their possible moves
}

sub chessNotation{
	my $move = shift;
	my %typetoletter = ( qw(king K queen Q rook R knight N bishop B), 'pawn' => '' );
		my $chessnotation = $typetoletter{$move->piece->type};
		# pawn captures add the COL of the pawn
		# pawn en passants are no different.  They don't actually say the location of the pawn captured.
		$chessnotation .= 'x' if defined $move->pieceToRemove;
		$chessnotation .= coordToChessNotation($move->toCoord);
	return $chessnotation
}

sub humanNotation{
	my $move = shift;
		my $humannotation = $move->piece->color.' '.$move->piece->type.' from '.coordToChessNotation($move->fromCoord).' to '.coordToChessNotation($move->toCoord).'.';
		$humannotation .= ' Captured a '.$move->pieceToRemove->color.' '.$move->pieceToRemove->type.'.' if defined $move->pieceToRemove;
	return $humannotation
}



1
