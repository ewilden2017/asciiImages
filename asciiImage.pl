#!/usr/bin/perl

#Perl ASCII Image Creator. Turns image files into ASCII text file, base on image saturation.
#Copyright (C) 2015 Evan Wildenberg
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#Contact Evan Wildenberg at ewilden2017@gmail.com.
$main::VERSION = '0.2.0'; #<http://www.semver.org>.

use strict;
use Scalar::Util qw(looks_like_number);
use Getopt::Std;
use GD;

my @chars = ('@', '%', '#', '0', 'X', 'T','|', ':',  '.', '\'',' ');
my @charsHigh = split //, '$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\|()1{}[]?-_+~<>i!lI;:,"^`\'. ';
my $DefaultSampleSize = 10; #size of each pixel square
###############################################
#Actual code starts on line 84.
$Getopt::Std::STANDARD_HELP_VERSION = 1;
my $sampleSize = $DefaultSampleSize;
my $multiplier = 1;

sub HELP_MESSAGE {
	print  <<EOF;
	asciiImage.pl version $main::VERSION
	Usage: perl asciiImage.pl [Options] <Image> [Output]

	Coverts an Image to an ASCII file, based on saturation. Supports JPG, PNG, GD, GD2 and XBM files.

	Options:
	-d: Detailed - Uses more characters for palette. This gives more shades, but makes some differences harder to see.
	-s <Size>: Sample Size - Default 10, Specifies size of pixels each character represents
	-H: HTML - Outputs with html <pre> tags, font size set to Samle Size
	-r <Scale>: Multiplier for use with -H, increases size of font, making the image larger.
	-h: Help - display this help message
EOF
}

my %options = ();
getopts("hvs:r:Hd", \%options);

if (defined $options{'h'}) {
	HELP_MESSAGE();
	exit;
}

print "This is as verbose as it gets.\n\n" if defined $options{'h'};
$sampleSize = $options{'s'} if (defined $options{'s'} && looks_like_number($options{'s'}));
my $html = $options{'H'};
$multiplier = $options{'r'} if (defined $options{'H'} && defined $options{'r'} &&
	looks_like_number($options{'r'}));
@chars = @charsHigh if defined $options{'d'};

if (scalar @ARGV < 1 || scalar @ARGV > 2) {
	print "Error: Incorrect number of arguments.\n";
	HELP_MESSAGE();
	exit;
}

my $file = $ARGV[0];
my $img = GD::Image->new($file) or die "Error opening image: $!";

my $out;
my $close = 1;
if ($ARGV[1]) {
	open($out, ">", $ARGV[1]) or warn "Could not open output file:$!, defaulting to STDOUT...\n";
}
if (not $out) { $out = *STDOUT; $close = 0; }


my $c_length = scalar @chars;
#Start printing
my $fontSize = $sampleSize * $multiplier;
print $out "<pre style=\"font-size:${fontSize}px;\">" if $html;
my ($width, $height) = $img->getBounds;

for (my $y=0;$y <= $height;$y+=$sampleSize*2) {
	for (my $x = 0;$x <= $width;$x+=$sampleSize) {
		my $n = 0;
		my $avg = 0;

		#Determine average of pixel chunk
		for (my $a=0;$a <= $sampleSize;$a++) {
			for (my $b=0;$b <= $sampleSize*2;$b++) {
				my $Sx = $x + $a > $width ? $width : $x + $a;
				my $Sy = $y + $b > $height ? $height : $y + $b;
				my ($r, $g, $b) = $img->rgb($img->getPixel($Sx, $Sy));
        		my $sat = ($r + $g + $b) / (255 * 3);
        		$avg = ($n * $avg + $sat) / ($n + 1);
        		$n++;
			}
		}
		print $out $chars[int($avg * ($c_length - 1))];
	}
	print $out "\n";
}
print $out "</pre>" if $html;

close $out if $close = 1;
#The end.
