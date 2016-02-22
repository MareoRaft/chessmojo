package mojo;

use FindBin;
use lib "$FindBin::Bin/";
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../Library/Perl/5.16/Downloads";
use lib "$FindBin::Bin/../Library/Perl/5.16/Custom";

use Mojo::Cache;
use Mojolicious::Lite; #use strict; #use warnings;
use Mojolicious::Static;
use Mojo::IOLoop;

use SVG;
use room;

##################################### DEFAULT VARIABLES ##################################
our @letters = qw(a b c d e f g h);
our %roomnametoroom = ();
our $defaultroom = room->new;
our $svg;
our @roomnames = ();
open( my $fh, '<', "public/lexis.txt" ) or die "Could not open the lexis!!!";
	push @roomnames => trim($_) while( <$fh> );
close( $fh ) or die "Could not CLOSE the lexis!";

##################################### HELPER FUNCTIONS ###################################
sub trim{ my ($i) = @_; $i =~ s/^\s+|\s+$//g; $i }

use Data::Dumper;

sub saveUserPrefs{
	my ($username,$prefs) = @_;
	print "sound is $$prefs{'sound'}!!";
	print "highlight is $$prefs{'highlight'}!!";
	open( my $fh, '>', "public/users/$username.txt" ) or warn "Cannot create file for user $username.";
		print $fh Data::Dumper->Dump( [$$prefs{'jss'}], ['jss'] ), "\n";
		print $fh '$sound = '.$$prefs{'sound'}.';', "\n";
		print $fh '$highlight = "'.$$prefs{'highlight'}.'";', "\n";
	close( $fh );
}

sub getUserPrefs{
	my ($username,$directembed) = @_;
	my $string;
	open( my $fh, '<', "public/users/$username.txt" ) or warn "Cannot retrieve file $username.txt" and return '';
		{ local undef $/; $string = <$fh> }
	close( $fh );
		# some regex's will change it from a perl hash to a javascript hash
		if( defined $directembed ){
			$string =~ s/\$jss/var userjss/;
			$string =~ s/=>/:/g;
			$string =~ s/\$sound/var usersound/;
			$string =~ s/\$highlight/var userhighlight/;
			$string .= q(userprefs = { 'jss':userjss, 'sound':usersound, 'highlight':userhighlight };); # semicolons for separation (no enter necessarily)
			$string .= 'setPrefs(userprefs);';
			return $string
		}
		else{
			my ($jss,$sound,$highlight);
				eval $string;
			return { 'jss'=>$jss, 'sound'=>$sound, 'highlight'=>$highlight }
		}
}

{
package Mojolicious::Controller;
	sub color{
		my $self = shift;
		if( @_ ){ $self->stash(color=>$_[0]) }
		return $self->stash('color')
	}

	sub placePieces{
		my $self = shift;
		my @piecesforjson = ();
		foreach my $piece ($self->stash('room')->pieces){
			my $piecehash = { 'ID'=>$piece->ID, 'x'=>$piece->X, 'y'=>$piece->Y }; # X and Y are functions, not hard values.  Therefore we can't just pass the object.
			push @piecesforjson => $piecehash;
		}
		my %ball; @ball{qw(command pieces message)} = ('placepieces', \@piecesforjson, 'placing the pieces!');
		$self->send({json => \%ball});
	}

	sub setRoom{
		my $self = shift;
		my $oldroomname = ($self->stash('roomname') or ''); # if there was no old room, then the stash is empty, so $oldroomname will be blank...
		#print "oldroomname is $oldroomname.";
		my $roomname = ($_[0] or 'default');
		return ($roomname,$roomnametoroom{$roomname}) if( $roomname eq $oldroomname ); # why bother switching if you're already there??

		if( $oldroomname and exists $roomnametoroom{$oldroomname} ){ $roomnametoroom{$oldroomname}->removeController($self) }
		$roomnametoroom{$roomname} = room->new() unless exists $roomnametoroom{$roomname};
		$roomnametoroom{$roomname}->addController($self); # the room has self as one of its controllers
		$self->stash(roomname=>$roomname); # the controller knows what roomname it's in
		$self->session(roomname=>$roomname); # for reloading purposes
		$self->stash(room=>$roomnametoroom{$roomname}); # the controller knows what room it's in
		$self->placePieces; # this makes sure the board is up to date upon entry (if in the middle of a game)
		return ($roomname,$roomnametoroom{$roomname})
	}

	sub setColor{
		my $self = shift;
		my ($cr) = @_; # cr is for color requested # print "cr is $cr \n";
		my $takencolor = 'unknown';

		my $totaloccupation = 0;
		my %colortooccupyval = ( ''=>0, 'none'=>0, 'a spectator'=>0, 'open'=>0, 'white'=>1, 'black'=>1, 'both'=>2 );
		foreach( $self->stash('room')->controllers ){ if( "$self" ne "$_" ){
			$totaloccupation += $colortooccupyval{ $_->color };
			$takencolor = 'white' if $_->color eq 'white';
			$takencolor = 'black' if $_->color eq 'black';
		}}
		my %colortorequiredval = ( ''=>'inf', 'none'=>'inf', 'a spectator'=>'inf', 'open'=>0, 'white'=>1, 'black'=>1, 'both'=>0 );
		unless( $cr ~~ %colortorequiredval ){ return 0 }
		if( $totaloccupation <= $colortorequiredval{$cr} ){ if( $cr ne $takencolor ){
			$self->color($cr);
			return 1
		}}
		return 0
	}
}

sub randString{
	my $minlength = ( $_[0] or 0 );
	my $length = int( $minlength+6*rand() ); #print "length is $length";
	my @letters = ('a'..'z');
	my $string = '';
	for (1..$length){	$string .= $letters[int(26*rand())]	}
	return $string
}

sub randRoomName{
	#while(1){
		#my $name = randString(4);
		#unless( exists $roomnametoroom{$name} ){ return $name }
	#}
	my $randindex = int($#roomnames*rand());
	return $roomnames[$randindex]
}

######################################## SVG SETUP #######################################
{
package SVG::Element;
	sub SVGOfPiece{ #this function is for use with SVG.pm stuff.  ex: $group->SVGOfPiece($piece)
		my ($root,$piece) = @_;
		my %moves = @_;

		my $svg = $root->svg( 'ID'=>$piece->ID, 'x'=>$piece->X, 'y'=>$piece->Y, 'class'=>$piece->color, %moves );
		my $innergroup = $svg->group( 'transform'=>"translate(0.005) scale(0.022)" );
		if( $piece->type eq 'pawn' ){
			$innergroup->path(
				'd'=>"M 22 9 C 19.792 9 18 10.792 18 13 C 18 13.885103 18.29397 14.712226 18.78125 15.375 C 16.829274 16.496917 15.5 18.588492 15.5 21 C 15.5 23.033947 16.442042 24.839082 17.90625 26.03125 C 14.907101 27.08912 10.5 31.578049 10.5 39.5 L 33.5 39.5 C 33.5 31.578049 29.092899 27.08912 26.09375 26.03125 C 27.557958 24.839082 28.5 23.033948 28.5 21 C 28.5 18.588492 27.170726 16.496917 25.21875 15.375 C 25.70603 14.712226 26 13.885103 26 13 C 26 10.792 24.208 9 22 9 z ",
				'class'=>'onepointsix'
			);
		}
		elsif( $piece->type eq 'knight' ){
			$innergroup->path( 'd'=>"M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18" );
			$innergroup->path( 'd'=>"M 24,18 C 24.384461,20.911278 18.447064,25.368624 16,27 C 13,29 13.180802,31.342892 11,31 C 9.95828,30.055984 12.413429,27.962451 11,28 C 10,28 11.187332,29.231727 10,30 C 9,30 5.9968392,30.999999 6,26 C 6,24 12,14 12,14 C 12,14 13.885866,12.097871 14,10.5 C 13.273953,9.505631 13.5,8.5 13.5,7.5 C 14.5,6.5 16.5,10 16.5,10 L 18.5,10 C 18.5,10 19.281781,8.0080745 21,7 C 22,7 22,10 22,10" );
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
		elsif( $piece->type eq 'bishop' ){
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
		elsif( $piece->type eq 'rook' ){
			$innergroup->path( 'd'=>"M 9,39 L 36,39 L 36,36 L 9,36 L 9,39 z " );
			$innergroup->path( 'd'=>"M 12,36 L 12,32 L 33,32 L 33,36 L 12,36 z " );
			$innergroup->path( 'd'=>"M 11,14 L 11,9 L 15,9 L 15,11 L 20,11 L 20,9 L 25,9 L 25,11 L 30,11 L 30,9 L 34,9 L 34,14" );
			$innergroup->path( 'd'=>"M 34,14 L 31,17 L 14,17 L 11,14" );
			$innergroup->path( 'd'=>"M 31,17 L 31,29.500018 L 14,29.500018 L 14,17" );
			$innergroup->path( 'd'=>"M 31,29.5 L 32.5,32 L 12.5,32 L 14,29.5" );
			$innergroup->path( 'd'=>"M 11,14 L 34,14" );
		}
		elsif( $piece->type eq 'king' ){
			$innergroup->path( 'd'=>"M 22.5,11.625 L 22.5,6" );
			$innergroup->path( 'd'=>"M 22.5,25 C 22.5,25 27,17.5 25.5,14.5 C 25.5,14.5 24.5,12 22.5,12 C 20.5,12 19.5,14.5 19.5,14.5 C 18,17.5 22.5,25 22.5,25" );
			$innergroup->path( 'd'=>"M 11.5,37 C 17,40.5 27,40.5 32.5,37 L 32.5,30 C 32.5,30 41.5,25.5 38.5,19.5 C 34.5,13 25,16 22.5,23.5 L 22.5,27 L 22.5,23.5 C 19,16 9.5,13 6.5,19.5 C 3.5,25.5 11.5,29.5 11.5,29.5 L 11.5,37 z " );
			$innergroup->path( 'd'=>"M 20,8 L 25,8" );
			$innergroup->path( 'd'=>"M 11.5,29.5 C 17,27 27,27 32.5,30" );
			$innergroup->path( 'd'=>"M 11.5,37 C 17,34.5 27,34.5 32.5,37" );
			$innergroup->path( 'd'=>"M 11.5,33.5 C 17,31.5 27,31.5 32.5,33.5" );
		}
		elsif( $piece->type eq 'queen' ){
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
			$innergroup->path( 'd'=>"M 11.5, 30 C 15, 29 30, 29 33.5, 30" );
			$innergroup->path( 'd'=>"M 12, 33.5 C 18, 32.5 27, 32.5 33, 33.5" );
		}
	}
}
{
package SVG;
	sub renderInline{
		my $svg = shift;
		my %attributes = @_; #print %attributes;
			my $prestring = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"';
			$prestring .= qq( $_="$attributes{$_}") foreach (keys %attributes);
			$prestring .= '>';
			my $svgstring = $svg->xmlify( -standalone=>'no' );
			$svgstring =~ s/<\?xml[^?]*\?>//; # this seems to be merely a declaration, and may be good to have (but for now we delete it)
			$svgstring =~ s/<!DOCTYPE svg[^>]*>//; # this too
			$svgstring =~ s/<svg[^>]*>//;
		return $prestring.$svgstring
	}
	sub renderInlinePiece{
		my ($piece,%attributes) = @_;
		my $pieceSVG = SVG->new; # we don't really need to make this new every time...
		$pieceSVG->SVGOfPiece($piece);
		return $pieceSVG->renderInline( %attributes )
	}
	sub renderInlinePawnOfColor{
		my ($color,%attributes) = @_;
		my $piece = piece->new( 'color'=>$color, 'type'=>'pawn' );
		return renderInlinePiece( $piece, %attributes )
	}
	sub renderInlinePieceOfType{
		my ($type,%attributes) = @_;
		my $piece = piece->new( 'type'=>$type );
		return renderInlinePiece( $piece, %attributes )
	}
}
sub defineSVG{ # we want a global SVG that is only made once (when the server launches)
	my ($defaultroom) = @_;
	$defaultroom->reverseBoard('y');
		$svg = SVG->new;
		my $id;

		my $rowandcollabels = $svg->group( 'opacity'=>0.1, 'style'=>"font-size:1px" );
  		for my $x (1..8){ for my $y (0,9){ $id = "letter$x$y"; $rowandcollabels->text( 'x'=>($x+0.25), 'y'=>(9-$y+0.84), 'onclick'=>"sendCoord(evt)" )->cdata($mojo::letters[$x-1]) } }
		for my $y (1..8){ for my $x (0,9){ $id = "number$x$y"; $rowandcollabels->text( 'x'=>($x+0.25), 'y'=>(9-$y+0.84), 'onclick'=>"sendCoord(evt)" )->cdata($y) } }

		my $whitesquares = $svg->group( 'class'=>"whitesquares" );
		my $blacksquares = $svg->group( 'class'=>"blacksquares" );
		for my $x (1..8){ for my $y (1..8){
			if( ($x+$y) % 2 == 0 ){ $id = $x.(9-$y); $whitesquares->rect( 'ID'=>"square$id", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1, 'onclick'=>"sendCoord(evt)" ) }
			if( ($x+$y) % 2 == 1 ){ $id = $x.(9-$y); $blacksquares->rect( 'ID'=>"square$id", 'x'=>$x, 'y'=>$y, 'height'=>1, 'width'=>1, 'onclick'=>"sendCoord(evt)" ) }
		}}
		my $pieces = $svg->group( 'ID'=>'pieces', 'pointer-events'=>'none' );
		foreach ($defaultroom->pieces){ $pieces->SVGOfPiece($_) } # a standard set of pieces will do, thus the defaultroom
	$defaultroom->reverseBoard('y');
}

defineSVG($defaultroom);

###################################### WEBSOCKETING ######################################
get '/' => sub {
	my $self = shift;
	if( $self->session('roomname') eq '$roomname' ){ print 'default blank session variable overridden.'; $self->session(roomname=>'') }
	my $roomname = ($self->param('roomname') or $self->param('room') or $self->session('roomname') or randRoomName() or 'Mojo'); $self->stash(roomname=>$roomname); $self->session(roomname=>$roomname); # if they don't specify a room, they go to roomname 'Mojo', the default room where everyone hangs out
	my $username = ($self->param('username') or $self->param('user') or 'default'); $self->stash(username=>$username); # in stash, we MUST use barewords for the keys
	my $colorrequested = ($self->param('colorrequested') or $self->param('color') or 'open'); $self->stash(colorrequested=>$colorrequested);
	$self->res->headers->cache_control('max-age=1, no-cache'); # client side caching
	$self->stash(
		whitesquarecolor=>"#4dffff", blacksquarecolor=>"#4d4dff",
		whitestrokecolor=>"white", blackstrokecolor=>"black",
		whitepiececolor=>"#becfcf", blackpiececolor=>"#444",
		highlightcolor=>"yellow"
	);
	$self->render('template'=>'index', 'format'=>'html', 'handler'=>'ep');
};

get '/style' => sub {
	my $self = shift;
	$self->res->headers->cache_control('max-age=1, no-cache'); # client side caching
	$self->render( 'template'=>'style', 'format'=>'css', 'handler'=>'ep', 'handler'=>'ep' );
};

get '/javascript' => sub{
	my $self = shift;
	my $roomname = $self->param('roomname'); $self->stash(roomname=>$roomname); # in stash, we MUST use barewords for the keys
	my $username = $self->param('username'); $self->stash(username=>$username);
	my $colorrequested = $self->param('colorrequested'); $self->stash(colorrequested=>$colorrequested);
	$self->res->headers->cache_control('max-age=1, no-cache'); # client side caching
	$self->render('template'=>'javascript', 'format'=>'js', 'handler'=>'ep');
};

websocket '/socket' => sub {
	my $self = shift;
	print $self->session('roomname').'!!!!!!!'."\n\n"; # good! it shares the same session variables as the get /
	$self->res->headers->cache_control('max-age=1, no-cache'); # client side caching # just added!!!
	my $username = $self->param('username'); # gets it from url if user did input that
	my $roomname = $self->param('roomname'); # gets it from url if user did input that
	my $room = $self->setRoom($roomname);
	my $colorrequested = $self->param('colorrequested'); $self->color('a spectator'); $self->setColor($colorrequested);
	# assuming all established websockets are new
	Mojo::IOLoop->stream($self->tx->connection)->timeout(60*30); # deleting this does not fix the 'is_websocket on undefined' error when reloading...

	$self->on( finish => sub{ # this catches ALL closing websockets (whether the close is initiated by server or client, clean or dirty)
		my ($websocket, $exitcode, $reason ) = @_;
		$room->removeController($self); # very important, so that self doesn't get called later on.
		print "Websocket finished!\n";
	} );

	$self->on( # there is an on( message =>, but we are using on( json =>.  There is also on( finish =>...
		json => sub{
			my ($self, $ball) = @_;
			my $command = $$ball{'command'};
			if( $command eq 'squareclicked' ){
				$room->squareClicked($self,%$ball) # blasting included in squareClicked()
			}
			elsif( $command eq 'promote' ){
				$room->promote($$ball{'type'})
			}
			elsif( $command eq 'saveuserprefs' and $$ball{'username'} ne '' ){
				#print $$ball{'prefs'};
				saveUserPrefs( $$ball{'username'}, $$ball{'prefs'} );
				#print 'saved!!!!';
			}
			elsif( $command eq 'getuserprefs' ){
				@$ball{qw(command prefs)} = ( 'loadprefs', getUserPrefs($$ball{'username'}) );
				#print 'loaded';
				$self->send({json => $ball})
			}
			elsif( $command eq 'setroom' ){ print 'attempting to set room',"\n";
				( $$ball{'roomname'}, $room ) = $self->setRoom($$ball{'roomname'}); # the use of $room here allows us to use "$room" elsewhere in this function instead of $self->stash('room')
				#print $$ball{'roomname'};
				$self->send({json => $ball})
			}
			elsif( $command eq 'setcolor' ){
				if( $self->setColor($$ball{'colorrequested'}) ){ $self->send({json => $ball}) }
			}
#			elsif( $command eq 'finish' ){ no longer needed, see on( finish => sub
#				print "finishing...\n";
#				$room->removeController($self); # very important, so that self doesn't get called later on.
#				$self->finish; # we will NOT remove room or roomname from self's stash, because when self is finished, it's gone anyway!
#			}
			else{
				@$ball{qw(command message)} = ('didntclickasquare', 'webscoektmessage!');
				$room->blast({json => $ball})
			}
		}
	);
};

get '/missing' => sub { shift->render('does_not_exist') }; #i guess it's okay to cache missing ho ho
get '/dies' => sub { die 'Intentional error' }; # this is a sad death

my $static = Mojolicious::Static->new;
push @{$static->paths}, "$FindBin::Bin/";

#server side caching:
app->renderer->cache(Mojo::Cache->new('max_keys'=>1)); # tell mojolicious to avoid caching (but, this only works when the same page isn't being fetched twice in a row.)
#so if i reload, wouldn't that be fetching twice in a row?  Would it then fail?  (I'm assuming this is SERVER caching, not browser caching. please verify)
# You are correct, this is SERVER side caching (we already took care of browser caching with the response headers for cache control). Whenever you refresh, you are actually rendering two things: index.html.ep and style.css.ep (since once you load index.html, the browser will then request style.css). Therefore, this hack works. (I wish they supported either a 'max_keys' of 0 or an undef cache, but that's a bug in the Mojolicious code. It doesn't bother me much, but if it bothers you then you can report it.)
app->secrets(['thou shall not pass']);
app->start;
