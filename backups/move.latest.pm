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
		my $piece = $options{'piece'};
		my $fromcoord = $piece->coord; # needs to be frozen in time.
	#options are qw(piece fromcoord tocoord piecetoremove movetype)
	bless { 'fromcoord'=>$fromcoord, 'movetype'=>'regular', %options } => $packagename
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

sub movetype{
	my $move = shift;
	return $$move{'movetype'}
}

sub tocoord{
	my $move = shift;
	return $$move{'tocoord'}
}

sub setTocoord{
	my $move = shift;
	my ($coord) = @_;
	$$move{'tocoord'} = $coord;
}

sub fromcoord{
	my $move = shift;
	return $$move{'fromcoord'}
}

sub setFromcoord{
	my $move = shift;
	my ($coord) = @_;
	$$move{'fromcoord'} = $coord;
}

sub fromY{
	my $move = shift;
	return ${$move->fromcoord}[1]
}
sub toY{
	my $move = shift;
	return ${$move->tocoord}[1]
}
sub fromX{
	my $move = shift;
	return ${$move->fromcoord}[0]
}
sub toX{
	my $move = shift;
	return ${$move->tocoord}[0]
}

sub piecetoremove{
	my $move = shift;
	return $$move{'piecetoremove'}
}

sub setPiecetoremove{
	my $move = shift;
	my ($piecetoremove) = @_;
	$$move{'piecetoremove'} = $piecetoremove;
}

sub chessNotation{
	my $move = shift;
	my %typetoletter = ( qw(king K queen Q rook R knight N bishop B), 'pawn' => '' );
		my $chessnotation = $typetoletter{$move->piece->type};
		# pawn captures add the COL of the pawn
		# pawn en passants are no different.  They don't actually say the location of the pawn captured.
		$chessnotation .= 'x' if defined $move->piecetoremove;
		$chessnotation .= coordToChessNotation($move->tocoord);
	return $chessnotation
}

sub humanNotation{
	my $move = shift;
		my $humannotation = $move->piece->color.' '.$move->piece->type.' from '.coordToChessNotation($move->piece->coord).' to '.coordToChessNotation($move->tocoord).'.';
		$humannotation .= ' Captured a '.$move->piecetoremove->color.' '.$move->piecetoremove->type.'.' if defined $move->piecetoremove;
	return $humannotation
}



1
