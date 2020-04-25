#!/usr/env perl
# ASCIILOSCOPE
# A Terminanl based real-time analog data visualistaion tool.

use strict;use warnings;

use utf8;
binmode STDOUT, ":utf8";

use Time::HiRes ("sleep");

use Term::ReadKey;
my $key;
my $OrdKey;

my $VERSION=0.02;

# display parameters stored in hash for future conversion into an
# object orientated 
my %display=(                  # display parameters
   borderStyle=>"double",      # border style
   height    =>14,             # vertical characters
   width     =>50,             # horizontal characters
   row       =>2,              # vertical position (from top left)
   column    =>10,             # horizontal position
   sampleRate=>100,            # number of samples per second
   symbol    =>"*",);              # plot symbol

my %actions=(                  # for keyboard driven actions
   113=>{
	   note=>"q = exit",
	   proc=>sub{ exit;},
   },
   97=>{
	   note=>"a = Auto levels",
	   proc=>sub{autoLevels()},
   },
   67=>{
	   note=>"🠞 = Speed up",
	   proc=>sub{$display{sampleRate}+=10;$OrdKey=0;},
   },
   68=>{
	   note=>"🠜 = Slow down",
	   proc=>sub{$display{sampleRate}=$display{sampleRate}>10?$display{sampleRate}-10:10;$OrdKey=0;},
   },
   65=>{
	   note=>"🠉 = Magnify",
	   proc=>sub{$display{yMult}*=1.1;$OrdKey=0;},
   },
   66=>{
	   note=>"🠋 = Reduce",
	   proc=>sub{$display{yMult}*=0.9;$OrdKey=0;},
   },
   

);

# example initial dataset...a sine wave preloaded to allow scaling
my @list=();                                 
push @list,sin (3.14*$_/20) for (0..55); 
my $next=@list;

# Main routine
initialScreen();   # draw screen
autoLevels();      # auto adjust the scaling based on initial sample
startScope();      # the loop that updates the scope's display

print "\033[18;0H";#jump to 18,0 

# draws the frame and other features outside the 
sub initialScreen{           
	my @plotArea=();
    my %borders=(
        simple=>{tl=>"+", t=>"-", tr=>"+", l=>"|", r=>"|", bl=>"+", b=>"-", br=>"+",},
        double=>{tl=>"╔", t=>"═", tr=>"╗", l=>"║", r=>"║", bl=>"╚", b=>"═", br=>"╝",},
    );
    my %border=%{$borders{$display{borderStyle}}};
	foreach (0..$display{height}){
		$plotArea[$_]=$border{l}.(" "x$display{width}).$border{r};
	}
	unshift @plotArea,$border{tl}.($border{t}x$display{width}).$border{tr};
    push    @plotArea,$border{bl}.($border{b}x$display{width}).$border{br};
    printAt($display{row},$display{column},@plotArea);

    printAt( 3,$display{width}+$display{column}+3,
        map{$actions{$_}{note} } sort { $a <=> $b } keys %actions);
    
    printAt($display{row}+$display{height}+3,$display{column}-7<0?0:$display{column}-7,
    '   _    ___   __  _______  _    ___   ___   __   ___   ___  ___',
    '  /_\  / __| / _||_ _|_ _|| |  / _ \ / __| / _| / _ \ |  _\| __|',
    ' / _ \ \__ \| (_  | | | | | |_| (_) |\__ \| (_ | (_) || |_/| _| ',
    '/_/ \_\|___/ \__||___|___||___|\___/ |___/ \__| \___/ |_|  |___|'." v$VERSION",
    );
}

# uses the data in the @list to autscale the waveform for display
sub autoLevels{
  my $max=$list[0];my $min=$list[0];
  foreach my $y (@list){
    $max=$y if  $y>$max;
    $min=$y if  $y<$min;
  } 
  $display{yMult}=($display{height}-2)/($max-$min);
  $display{yOffset}=-$min*$display{yMult}+1;
  $display{xMult}=$display{width}/(scalar @list);
	
}

# The scope function
sub startScope{
  ReadMode 'cbreak';
  while(1){
	  shift @list;
	  push @list, sin (3.14*$next++/20); # the next data capture pushed into list
	  scatterPlot();                     # draw the trace
	  $next=0 if $next>200;              # limit the size of the trace
	  sleep 1/$display{sampleRate};      # pause
	  $key = ReadKey(-1);                # non-blocking read of keyboard
	  $OrdKey = ord($key) if $key;       # read key
	  if ($OrdKey){
		printAt( 1,$display{width}+$display{column}+2,"Key pressed = $OrdKey  ");
	    last if $OrdKey ==113 ;          # q is the quit key
	                                     # other keys actions are stored in %actions
	    $actions{$OrdKey}{proc}->() if defined $actions{$OrdKey};
	  }
	}  
  };

# generates plots from the list by scaling to fit into display area      
sub scatterPlot{
  my @plots=map { [int( $_*$display{xMult}) ,
	  bound (int($display{yMult}*$list[$_] +$display{yOffset}),0,$display{height}-1)] } (0..$#list);
  my @rows=(" "x$display{width})x$display{height};
  foreach (@plots){
    substr ($rows[$$_[1]], $$_[0],1,$display{symbol});
  }
  printAt($display{row}+2,$display{column}+1,reverse @rows);
}
# routine that prints multiline strings at specific points on the terminal window
sub printAt{
	my ($row,$column,@textRows)=@_;
	my $blit="\033[?25l";
	$blit.= "\033[".$row++.";".$column."H".$_ foreach (@textRows) ;
	print $blit;
}	

# sets the boundaries for a number assignment 
sub bound{  
	my ($number,$min,$max)=@_;
	return $max if $number>$max;
	return $min if $number<$min;
	return $number;	
}



