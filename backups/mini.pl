use Mojolicious::Lite;
use SVG;
use piece;

{
package SVG::Element;
	sub SVGOfPiece{ #this function is for use with SVG.pm stuff.  ex: $group->SVGOfPiece($piece)
		my ($root,$piece) = @_;
		my %moves = @_;

		my $svg = $root->svg( 'ID'=>$piece->ID, 'x'=>$piece->X, 'y'=>$piece->Y, 'class'=>$piece->color, %moves );
		my $innergroup = $svg->group( 'id'=>'groupid', 'class'=>'pawn', 'transform'=>"translate(0.005) scale(0.022)" );
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
}


get '/', sub {
	my $self = shift;
	$self->render( template=>'findex' );
};

app->secrets(['thou shall not pass']);
app->start;

__DATA__
@@ findex.html.ep
<html>
<head>
	<title>hi!</title>
<style>
.pawn{ fill:green;stroke:red }
</style>
</head>
<body>
	<div style="" width="100px" >
	<%== SVG::renderInlinePawnOfColor( 'black', 'style'=>"position:absolute;left:0;top:0;background-color:pink", 'id'=>'bigsvg', 'viewBox'=>"0 0 100 100", 'width'=>"200px", 'onclick'=>"clone()" ) %>
	</div>

<script>
%#var ws = newWebSocket( url_for('index')->to_abs );

var y=0
var Root=document.documentElement
function clone(){
alert('start')
 var G=document.getElementById("groupid")
 var NewG=G.cloneNode(true)
%# var move="translate("+0.4+","+0.4+")"
 var move="translate("+22.7+","+22.7+")"
 NewG.setAttributeNS(null,"transform",move)
%# Root.appendChild(NewG)
 document.getElementById("groupid").parentNode.appendChild(NewG)
 alert('added')
}
clone()

</script>

</body>
</html>
