# THIS SET IS FROZEN IN TIME, SERVING CHESSMOJO.

# We will create set objects, AND allow the user to treat arrays as sets if they want to.
package set{

use strict; use warnings;

#to do:  when no input is given, look for subject $_ variable
#when input is an array reference, setify it.

sub new{
	my $packagename = shift;
	my @elements = @_;
	bless [ @elements ] => $packagename;
}
=inprogress
sub setify{
	my $set = set->new;
	foreach(@_){
		if( ref($_) eq __PACKAGE__ ){

		}
	}
}
=cut
sub setify{ $_[0] }

sub copy{
#	my $set = setify @_;
	my $set = setify(shift);
	return set->new($set->elements)
}
*clone = \&copy;

sub elements{
	my $set = setify(shift);
	return @$set
}

sub magnitude{
	my $set = setify(shift);
	return my $magnitude = $set->elements
}
*size = \&magnitude;

use overload
	'""' => \&stringify,
	'+' => \&union,
	'-' => \&minus;

sub stringify{
	my $set = setify(shift);
	my @elements = $set->elements;
	my $s = '{ '; $s .= shift @elements; foreach (@elements){ $s.=", $_" }; $s.=' }';
	return $s
}

sub containsElement{
	my $set = setify(shift);
	my ($element) = @_;
	foreach ($set->elements){ if( $_ eq $element ){ return 1 } }
	return 0
}
*containsEl = \&containsElement;
sub isElement{
	my ($element,$set) = @_;
	return $set->containsElement($element)
}
*isEl = \&isElement;

sub addElements{
	my $set = setify(shift);
	my @elements = @_;
	foreach (@elements){ unless( $set->containsElement($_) ){ push @$set, $_ } }
	return $set
}
sub addElement{
	my $set = setify(shift);
	my ($element) = @_;
	return $set->addElements($element)
}
sub add{ # this returns the union, AND it alters setA to become that union
	my $setA = shift;
	my $setB = shift;
	return $setA->addElements( $setB->elements )
}
sub union{
	my $setAcopy = shift->copy;
	my $setB = shift;
	return $setAcopy->add($setB)
}

sub removeElement{
	my $set = setify(shift);
	my ($element) = @_;
	my $lastindex = $set->magnitude - 1;
	for my $i (0..$lastindex){ if( $element eq $$set[$i] ){ splice @$set, $i, 1; last } }
	return $set
}
sub removeElements{
	my $set = setify(shift);
	my @elements = @_;
	foreach (@elements){ $set = $set->removeElement($_) }
	return $set
}
sub remove{ # returns the difference, AND alters setA to become that difference
	my $setA = shift;
	my $setB = shift;
	return $setA->removeElements( $setB->elements )
}
*subtract = \&remove; # returns the difference, AND alters setA to become that difference
sub minus{ # returns the subtraction
	my $setAcopy = shift->copy;
	my $setB = shift;
	return $setAcopy->remove($setB)
}

sub intersect{
	my $setA = shift;
	my $setB = shift;
	my $intersection = set->new;
	foreach ($setA->elements){ if( isElement($_,$setB) ){ $intersection->addElement($_) } }
	return $intersection
}

sub symMinus{
	my $setA = shift;
	my $setB = shift;
	return $setA->union($setB)->remove( $setA->intersect($setB) )
}

sub isSubset{
	my $setA = shift;
	my $setB = shift;
 	foreach ($setA->elements){ unless( isElement($_,$setB) ){ return 0 } }
 	return 1
}
*subset = *isContainedIn = *isContained = \&isSubset;
sub isSuperset{
	my $setA = shift;
	my $setB = shift;
 	return $setB->isSubset($setA)
}
*superset = *isContaining = *contains = \&isSuperset;


} # end of package set
