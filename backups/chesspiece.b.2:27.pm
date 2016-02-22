package chesspiece;

use strict;
use warnings;

#################################### HELPER FUNCTIONS ####################################
use overload
	'""' => \&stringify;

sub removeArray{
	my ( $guytoremove, @set ) = @_;
	my $i = 0; while( $i <= $#set ){
		if( @$guytoremove ~~ @{$set[$i]} ){ splice @set, $i, 1 }
		else{ ++$i }
	}
	return @set;
}

###################################### CHESSPIECE ########################################
sub new{
	my $chesspiece = shift;
	my $uniqueID = $#main::pieces + 1; # Each chesspiece's ID is it's index in @pieces.
	bless { 'ID'=>$uniqueID, 'type'=>'queen', 'coord'=>[0,0], 'color'=>'white', @_ } => $chesspiece
}

sub ID{ my $obj = shift; return $obj->{'ID'} }
sub type{ my $obj = shift; return $obj->{'type'} }

sub coord{ my $obj = shift; return $obj->{'coord'} }
sub setCoord{ my $obj = shift; my ($coord) = @_; $obj->{'coord'} = $coord }

sub X{ my $obj = shift; return $obj->coord->[0] }
sub Y{ my $obj = shift; return $obj->coord->[1] }

sub color{ my $obj = shift; return $obj->{'color'} }
sub otherColor{ my $obj = shift; if( $obj->color eq 'white' ){ return 'black' }else{ return 'white' } }
sub switchColor{ my $obj = shift; $obj->{'color'} = $obj->otherColor }
sub myTurn{ my $obj = shift; if( $obj->color eq $main::turn->color ){ return 1 } return 0 }




sub isCoordOnBoard{
	my ($coord) = @_;
	my $X = $coord->[0];
	my $Y = $coord->[1];
	if( $X >= 1 && $Y >=1 && $X <= 8 && $Y <=8 ){ return 1 }
	return 0
}
sub isOnBoard{ my $obj = shift; return isCoordOnBoard( $obj->coord ) }

sub onlyWhatsOnBoard{ #only allows y values to reach double digits and still function. therefore always fix x in sub options, and let y depend on it
	my @places;
		foreach( @_ ){ if( isCoordOnBoard($_) ){ push @places, $_ } }
	return @places;
}

sub reverseOptions{
	my @options;
		foreach (@_){ push @options, [ 9-$_->[0], 9-$_->[1] ]  }
	return @options
}

sub isAPieceOn{
	my ($coord) = @_;
	foreach (@main::pieces){ if( @$coord ~~ @{$_->coord} ){ return 1 } }
	return 0
}

sub isAnEnemyOn{
	my $obj = shift;
	my ($coord) = @_;
	foreach (@main::pieces){ if(   @$coord ~~ @{$_->coord}   &&   $obj->color ne $_->color   ){ return 1 } }
	#print "will return 0\n";
	return 0
}

sub isAFriendOn{
	my $obj = shift;
	my ($coord) = @_;
	foreach (@main::pieces){ if(   @$coord ~~ @{$_->coord}   &&   $obj->color eq $_->color   ){ return 1 } }
	return 0
}

sub qualifyIndividualOptions {
	my $obj = shift;
	my @individualoptions = @_;
	my $i = 0; while( $i <= $#individualoptions ){
		if( $obj->isAFriendOn($individualoptions[$i]) ){ splice @individualoptions, $i, 1 }
		else{ ++$i }
	}
	return @individualoptions
}

sub qualifyLineOfOptions{
	my $obj = shift;
	my @lineofoptions = @_;
	my $state = 'before';
	for( my $i=0; $i<=$#lineofoptions; ++$i ){ #print "color is ",$obj->color," and coord is ",${$obj->coord}[0],',',${$obj->coord}[1]; print "lineoptions are "; foreach(@lineofoptions){print "[$$_[0],$$_[1]]" } print " i is $i.\n";
		if( $lineofoptions[$i] ~~ $obj->coord ){ $state = 'after'; }#print "state is $state\n"; }
		elsif( $obj->isAFriendOn($lineofoptions[$i]) && $state eq 'before' ){ splice @lineofoptions, 0, $i+1; $i=-1; }#print "\tfound friend, state=before.\n"; }
		elsif( $obj->isAnEnemyOn($lineofoptions[$i]) && $state eq 'before' ){ splice @lineofoptions, 0, $i; $i=0; }#print "\tfound enemy, state=before.\n"; }
		elsif( $obj->isAFriendOn($lineofoptions[$i]) && $state eq 'after' ){  splice @lineofoptions, $i; last }#print "\tfound friend, state=after.\n";
		elsif( $obj->isAnEnemyOn($lineofoptions[$i]) && $state eq 'after' ){ splice @lineofoptions, $i+1; last }#print "\tfound enemy, state=after.\n";
		#<STDIN>;
	}
	return @lineofoptions;
}

sub whitePawnOptions{
	my $obj = shift;
	my @options; my @lineofoptions;
		push @lineofoptions, ( [ $obj->X, $obj->Y ], [ $obj->X, $obj->Y+1 ] );
		push @lineofoptions, [ $obj->X, $obj->Y+2 ] if $obj->Y==2; #jump 2 first move
		push @options, $obj->qualifyLineOfOptions(@lineofoptions);

		push @options, [ $obj->X+1, $obj->Y+1 ] if $obj->isAnEnemyOn( [$obj->X+1,$obj->Y+1] ); #capture
		push @options, [ $obj->X-1, $obj->Y+1 ] if $obj->isAnEnemyOn( [$obj->X-1,$obj->Y+1] ); #capture
		push @options, [ $obj->X+1, $obj->Y+1 ] if $obj->isAnEnemyOn( [$obj->X+1,$obj->Y] ) and 1;#thatpawnjustjumpedtwo; #enpassant
		push @options, [ $obj->X-1, $obj->Y+1 ] if $obj->isAnEnemyOn( [$obj->X-1,$obj->Y] ) and 1;#thatpawnjustjumpedtwo; #enpassant
	return @options
}

sub options{
	my $obj = shift;
	my @options; my @lineofoptions; my @individualoptions;
	if( $obj->isOnBoard ){ #return "onboard";
		if( $obj->type eq 'rook' || $obj->type eq 'queen' ){
			@lineofoptions=(); for my $x (1..8){ push @lineofoptions, [$x,$obj->Y] } push @options, $obj->qualifyLineOfOptions(@lineofoptions);
			@lineofoptions=(); for my $y (1..8){ push @lineofoptions, [$obj->X,$y] } push @options, $obj->qualifyLineOfOptions(@lineofoptions);
		}
		if( $obj->type eq 'bishop' || $obj->type eq 'queen' ){ #IF, not ELSIF
			@lineofoptions=(); for my $x (1..8){ push @lineofoptions, [$x,$x - $obj->X + $obj->Y] } push @options, $obj->qualifyLineOfOptions(@lineofoptions);
			@lineofoptions=(); for my $x (1..8){ push @lineofoptions, [$x,$obj->X + $obj->Y - $x] } push @options, $obj->qualifyLineOfOptions(@lineofoptions);
		}
		elsif( $obj->type eq 'knight' ){
			for my $dx (-2,2){ for my $dy (-1,1){ push @individualoptions, [ $obj->X+$dx, $obj->Y+$dy ] } }
			for my $dy (-2,2){ for my $dx (-1,1){ push @individualoptions, [ $obj->X+$dx, $obj->Y+$dy ] } }
			@options = $obj->qualifyIndividualOptions(@individualoptions);
		}
		elsif( $obj->type eq 'pawn' ){
			if( $obj->color eq 'white' ){ @options = $obj->whitePawnOptions }
			else{ &main::reverseBoard(); @options = reverseOptions($obj->whitePawnOptions); &main::reverseBoard() }
		}
		elsif( $obj->type eq 'king' ){
			for my $dx (-1,0,1){ for my $dy (-1,0,1){ push @individualoptions, [ $obj->X+$dx, $obj->Y+$dy ] } }
			@options = $obj->qualifyIndividualOptions(@individualoptions);
		}
	}
	@options = onlyWhatsOnBoard(@options); #onlyWhatsOnBoard() is only really going to be needed for the knight.
	#notes that options may be redundant in that the same Coord can appear mulitple times. currently it is not because of below:
	@options = removeArray($obj->coord,@options);

#	foreach (@options){
#		my $slope = [   $obj->X - $_->[0],   $obj-Y - $_->[1]   ];

#x-y line: y = mx + b or (y-yo) / (x-xo) = m, which becomes y = y0 + (x-x0)*m
#line: t from 0 to 1:		start(t) + finish(1-t)

	return @options;
}

sub optionIDs{
	my $obj = shift; #if( !defined $obj ){ return [] } program still complains though...
	my @options = $obj->options;
		foreach (@options){ $_ = 'square'.$$_[0].$$_[1] }
	return \@options
}

sub createSVGInGroup{
	my $obj = shift;
	my $group = shift;
	my %options = @_;

	my $id = $obj->ID; my $svg = $group->svg( 'ID'=>$id, 'x'=>$obj->X, 'y'=>$obj->Y, 'fill'=>$main::colortofill{$obj->color}, %options );
#	my $id = $obj->ID; my $svg = $group->svg( 'ID'=>$id, 'onclick'=>"sendID(evt,$id)", 'x'=>$obj->X, 'y'=>$obj->Y, 'fill'=>$main::colortofill{$obj->color}, %options );
	my $innergroup = $svg->group( 'transform'=>"translate(0.005) scale(0.022)" );
	if( $obj->type eq 'pawn' ){
		$innergroup->path(
			'd'=>"M 22 9 C 19.792 9 18 10.792 18 13 C 18 13.885103 18.29397 14.712226 18.78125 15.375 C 16.829274 16.496917 15.5 18.588492 15.5 21 C 15.5 23.033947 16.442042 24.839082 17.90625 26.03125 C 14.907101 27.08912 10.5 31.578049 10.5 39.5 L 33.5 39.5 C 33.5 31.578049 29.092899 27.08912 26.09375 26.03125 C 27.557958 24.839082 28.5 23.033948 28.5 21 C 28.5 18.588492 27.170726 16.496917 25.21875 15.375 C 25.70603 14.712226 26 13.885103 26 13 C 26 10.792 24.208 9 22 9 z ",
			'stroke'=>"black",
			'class'=>'onepointsix'
 		);
 	}
 	elsif( $obj->type eq 'knight' ){
 		$innergroup->path(
			'd'=>"M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18",
		);
		$innergroup->path(
			'd'=>"M 24,18 C 24.384461,20.911278 18.447064,25.368624 16,27 C 13,29 13.180802,31.342892 11,31 C 9.95828,30.055984 12.413429,27.962451 11,28 C 10,28 11.187332,29.231727 10,30 C 9,30 5.9968392,30.999999 6,26 C 6,24 12,14 12,14 C 12,14 13.885866,12.097871 14,10.5 C 13.273953,9.505631 13.5,8.5 13.5,7.5 C 14.5,6.5 16.5,10 16.5,10 L 18.5,10 C 18.5,10 19.281781,8.0080745 21,7 C 22,7 22,10 22,10",
		);
		$innergroup->path(
			'type'=>"arc",
			'cx'=>"8.5",
			'cy'=>"23.5",
			'rx'=>"0.5",
			'ry'=>"0.5",
			'd'=>"M 9 23.5 A 0.5 0.5 0 1 1  8,23.5 A 0.5 0.5 0 1 1  9 23.5 z",
			'transform'=>"translate(0.5, 2)",
		);
		$innergroup->path(
			'type'=>"arc",
			'cx'=>"14.5",
			'cy'=>"15.5",
			'rx'=>"0.5",
			'ry'=>"1.5",
			'd'=>"M 15 15.5 A 0.5 1.5 0 1 1  14,15.5 A 0.5 1.5 0 1 1  15 15.5 z",
			'transform'=>"matrix(0.866025, 0.5, -0.5, 0.866025, 9.69263, -5.17339)",
		);
		$innergroup->path(
			'class'=>'none',
			'd'=>"M 37,39 C 38,19 31.5,11.5 25,10.5"
		);
 	}
	elsif( $obj->type eq 'bishop' ){
		$innergroup->path( 'd'=>"M 9,36 C 12.385255,35.027671 19.114744,36.430821 22.5,34 C 25.885256,36.430821 32.614745,35.027671 36,36 C 36,36 37.645898,36.541507 39,38 C 38.322949,38.972328 37.354102,38.986164 36,38.5 C 32.614745,37.527672 25.885256,38.958493 22.5,37.5 C 19.114744,38.958493 12.385255,37.527672 9,38.5 C 7.6458978,38.986164 6.6770511,38.972328 6,38 C 7.3541023,36.055343 9,36 9,36 z " );
		$innergroup->path( 'd'=>"M 15,32 C 17.5,34.5 27.5,34.5 30,32 C 30.5,30.5 30,30 30,30 C 30,27.5 27.5,26 27.5,26 C 33,24.5 33.5,14.5 22.5,10.5 C 11.5,14.5 12,24.5 17.5,26 C 17.5,26 15,27.5 15,30 C 15,30 14.5,30.5 15,32 z " );
		$innergroup->path(
			'type'=>"arc",
			'cx'=>"22.5",
			'cy'=>"10",
			'rx'=>"2.5",
			'ry'=>"2.5",
			'd'=>"M 25 10 A 2.5 2.5 0 1 1  20,10 A 2.5 2.5 0 1 1  25 10 z",
			'transform'=>"translate(0,-2)"
		);
		$innergroup->path( 'class'=>'none', 'd'=>"M 17.5,26 L 27.5,26" );
		$innergroup->path( 'class'=>'none', 'd'=>"M 15,30 L 30,30" );
		$innergroup->path( 'class'=>'none', 'd'=>"M 22.5,15.5 L 22.5,20.5" );
		$innergroup->path( 'class'=>'none', 'd'=>"M 20,18 L 25,18", ); }
	elsif( $obj->type eq 'rook' ){
		$innergroup->path( 'd'=>"M 9,39 L 36,39 L 36,36 L 9,36 L 9,39 z " );
		$innergroup->path( 'd'=>"M 12,36 L 12,32 L 33,32 L 33,36 L 12,36 z " );
		$innergroup->path( 'd'=>"M 11,14 L 11,9 L 15,9 L 15,11 L 20,11 L 20,9 L 25,9 L 25,11 L 30,11 L 30,9 L 34,9 L 34,14" );
		$innergroup->path( 'd'=>"M 34,14 L 31,17 L 14,17 L 11,14" );
		$innergroup->path( 'd'=>"M 31,17 L 31,29.500018 L 14,29.500018 L 14,17" );
		$innergroup->path( 'd'=>"M 31,29.5 L 32.5,32 L 12.5,32 L 14,29.5" );
		$innergroup->path( 'd'=>"M 11,14 L 34,14" );
	}
	elsif( $obj->type eq 'king' ){
		$innergroup->path(
			'd'=>"M 22.5,11.625 L 22.5,6",
		);
		$innergroup->path(
			'd'=>"M 22.5,25 C 22.5,25 27,17.5 25.5,14.5 C 25.5,14.5 24.5,12 22.5,12 C 20.5,12 19.5,14.5 19.5,14.5 C 18,17.5 22.5,25 22.5,25",
		);
		$innergroup->path(
			'd'=>"M 11.5,37 C 17,40.5 27,40.5 32.5,37 L 32.5,30 C 32.5,30 41.5,25.5 38.5,19.5 C 34.5,13 25,16 22.5,23.5 L 22.5,27 L 22.5,23.5 C 19,16 9.5,13 6.5,19.5 C 3.5,25.5 11.5,29.5 11.5,29.5 L 11.5,37 z ",
		);
		$innergroup->path(
			'd'=>"M 20,8 L 25,8",
		);
		$innergroup->path(
			'd'=>"M 11.5,29.5 C 17,27 27,27 32.5,30",
		);
		$innergroup->path(
			'd'=>"M 11.5,37 C 17,34.5 27,34.5 32.5,37",
		);
		$innergroup->path(
			'd'=>"M 11.5,33.5 C 17,31.5 27,31.5 32.5,33.5",
		);
	}
	elsif( $obj->type eq 'queen' ){
		$innergroup->path(
			'cx'=>"7", 'cy'=>"13", 'rx'=>"2", 'ry'=>"2",
			'd'=>"M 9 13 A 2 2 0 1 1  5, 13 A 2 2 0 1 1  9 13 z", 'transform'=>"translate(-1, -1)"
		);
		$innergroup->path(
			'type'=>"arc",
			'cx'=>"7", 'cy'=>"13", 'rx'=>"2", 'ry'=>"2",
			'd'=>"M 9 13 A 2 2 0 1 1  5, 13 A 2 2 0 1 1  9 13 z", 'transform'=>"translate(15.5, -5.5)"
		);
		$innergroup->path(
			'type'=>"arc",
			'cx'=>"7", 'cy'=>"13", 'rx'=>"2", 'ry'=>"2",
			'd'=>"M 9 13 A 2 2 0 1 1  5, 13 A 2 2 0 1 1  9 13 z", 'transform'=>"translate(32, -1)"
		);
		$innergroup->path(
			'cx'=>"7", 'cy'=>"13", 'rx'=>"2", 'ry'=>"2",
			'd'=>"M 9 13 A 2 2 0 1 1  5, 13 A 2 2 0 1 1  9 13 z", 'transform'=>"translate(7, -4.5)"
		);
		$innergroup->path(
			'type'=>"arc",
			'cx'=>"7", 'cy'=>"13", 'rx'=>"2", 'ry'=>"2",
			'd'=>"M 9 13 A 2 2 0 1 1  5, 13 A 2 2 0 1 1  9 13 z", 'transform'=>"translate(24, -4)"
		);
		$innergroup->path( 'd'=>"M 9, 26 C 17.5, 24.5 30, 24.5 36, 26 L 38, 14 L 31, 25 L 31, 11 L 25.5, 24.5 L 22.5, 9.5 L 19.5, 24.5 L 14, 10.5 L 14, 25 L 7, 14 L 9, 26 z " );
		$innergroup->path( 'd'=>"M 9, 26 C 9, 28 10.5, 28 11.5, 30 C 12.5, 31.5 12.5, 31 12, 33.5 C 10.5, 34.5 10.5, 36 10.5, 36 C 9, 37.5 11, 38.5 11, 38.5 C 17.5, 39.5 27.5, 39.5 34, 38.5 C 34, 38.5 35.5, 37.5 34, 36 C 34, 36 34.5, 34.5 33, 33.5 C 32.5, 31 32.5, 31.5 33.5, 30 C 34.5, 28 36, 28 36, 26 C 27.5, 24.5 17.5, 24.5 9, 26 z " );
		$innergroup->path( 'stroke'=>"black", 'd'=>"M 11.5, 30 C 15, 29 30, 29 33.5, 30" );
		$innergroup->path( 'stroke'=>"black", 'd'=>"M 12, 33.5 C 18, 32.5 27, 32.5 33, 33.5" );
	}
	else{}
}

sub stringify{
	my $obj = shift;
	my $toprint = 'ID: '.$obj->ID.'. A '.$obj->color.' '.$obj->type.' has position ['.$obj->X.','.$obj->Y.']. And '.($obj->isOnBoard? 'is': 'is not')." on the board. Options...\n";
	$toprint .= "OPTIONS:\n";
	foreach( $obj->options ){ $toprint .= join(',',@$_)."\n" }
	return $toprint
}

1
