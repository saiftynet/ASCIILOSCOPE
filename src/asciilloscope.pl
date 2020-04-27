#!/usr/env/perl
#                      ASCIILOSCOPE
# A Terminal based real-time analog data visualisation tool.

use strict;use warnings;

use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";
use Time::HiRes ("sleep");      # allow fractional sleeps
use Term::ReadKey;              # allow reading from keyboard
my $key;                      

my $VERSION=0.05;

# display parameters stored in hash for future conversion into an
# object orientated module 

my @list;   # the data window

my %display=(                  # display parameters
   showLogo   =>1,             # show logo or not
   showMenu   =>1,             # show menu or not
   enableColours=>1,           # enable colours
   borderStyle=>"double",      # border style
   height    =>14,             # vertical characters
   width     =>50,             # horizontal characters
   row       =>2,              # vertical position (from top left)
   column    =>10,             # horizontal position
   sampleRate=>100,            # number of samples per second
   dataWindow=>55,             # number of samples in one window
   dataStore =>110,
   symbol    =>"*",            # plot symbol
   );        

my %actions=(                  # for keyboard driven actions
   113=>{ # q exits
	   note=>"q = Exit",
	   proc=>sub{ printAt($display{row}+$display{height}+9,0,"Goodbye!");exit;},
   },
   112=>{  # Freezes display (loop continues so keyboard is read)
	   note=>"p = Freeze",
	   proc=>sub{$display{pause}=1},
   },
   114=>{  # Resume
	   note=>"r = Resume",
	   proc=>sub{$display{pause}=0},
   },
   97 =>{  # Auto levels based on the current contents of @list
	   note=>"a = Auto levels",
	   proc=>sub{autoLevels()},
   },
   67 =>{  # increase sample rate by 10
	   note=>"🠞 = Speed up",
	   proc=>sub{$display{sampleRate}+=10;},
   },
   68 =>{  # reduce sample rate by 10
	   note=>"🠜 = Slow down",
	   proc=>sub{$display{sampleRate}=$display{sampleRate}>10?$display{sampleRate}-10:10;},
   },
   65 =>{  # shift display up by 1
	   note=>"🠉 = Shift up",
	   proc=>sub{$display{yOffset}+=1;},
   },
   66 =>{ # shift display down by 1
	   note=>"🠋 = Shift down",
	   proc=>sub{$display{yOffset}-=1;},
   },   
   42 =>{ # increase samples per full width
	   note=>"* = Inc Window",
	   proc=>sub{unshift @list,($list[0]) x 10;
		         $display{xMult}=$display{width}/(scalar @list);},
   },
   47 =>{ # decrease samples per full width
	   note=>"/ = Dec Window",
	   proc=>sub{@list=@list[9..$#list] if @list>15;
		         $display{xMult}=$display{width}/(scalar @list);},
   },
   43 =>{ # increase multiplier by 10%
	   note=>"+ = Magnify",
	   proc=>sub{$display{yMult}*=1.1;},
   },
   45 =>{ # reduce multiplier by 10%
	   note=>"- = Reduce",
	   proc=>sub{$display{yMult}*=0.9;},
   },
);

# example initial dataset...a sine wave preloaded to allow scaling -1 to 1
# subsequent data can be autoscaled again as required.                             
push @list,sin (3.14*$_/20) for (0..$display{dataWindow}); 
my $next=@list;

# Main routine
initialScreen();   # draw screen
autoLevels();      # auto adjust the scaling based on initial sample
startScope();      # the loop that updates the scope's display

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
	unshift @plotArea,colour("blue","bold").$border{tl}.($border{t}x$display{width}).$border{tr};
    push    @plotArea,$border{bl}.($border{b}x$display{width}).$border{br}.colour("reset");
    printAt($display{row},$display{column},@plotArea),;

    printAt( 3,$display{width}+$display{column}+3,
        map{$actions{$_}{note} } sort { $a <=> $b } keys %actions) if $display{showMenu};;
    
    printAt($display{row}+$display{height}+3,$display{column}-7<0?0:$display{column}-7,
    colour("yellow","bold").
    '   _    ___   __  _______  _    ___   ___   __   ___   ___  ___',
    '  /_\  / __| / _||_ _|_ _|| |  / _ \ / __| / _| / _ \ |  _\| __|',
    ' / _ \ \__ \| (_  | | | | | |_| (_) |\__ \| (_ | (_) || |_/| _| ',
    '/_/ \_\|___/ \__||___|___||___|\___/ |___/ \__| \___/ |_|  |___|'." v$VERSION".
    colour("reset") 
    ) if $display{showLogo};
};

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
};

# The scope function
sub startScope{
  ReadMode 'cbreak';
  while(1){
    unless ($display{pause}){
      shift @list;
	  push @list, sin (3.14*$next++/20); # the next data capture pushed into list
	  $next=0 if $next>200;              # limit the size of $next...
    }
    scatterPlot();                     # draw the trace
	sleep 1/$display{sampleRate};      # pause
	$key = ReadKey(-1);                # -1 means non-blocking read
	if ($key){
	  my $OrdKey = ord($key);
	  printAt( 1,$display{width}+$display{column}+2,"Key pressed = $OrdKey  ");
	  # Keys actions are stored in %actions
	  $actions{$OrdKey}{proc}->() if defined $actions{$OrdKey};
	}
  }  
  ReadMode 'normal';
};

# generates plots from the list by scaling to fit into display area      
sub scatterPlot{
  my @plots=map { [int( $_*$display{xMult}) ,
	  bound (int($display{yMult}*$list[$_] +$display{yOffset}-.5),0,$display{height}-1)] } (0..$#list);
  my @rows=(" "x$display{width})x$display{height};
  $rows[bound($display{yOffset},0,$display{height})]="-"x$display{width};
  foreach (@plots){
    substr ($rows[$$_[1]], $$_[0],1,$display{symbol});
  }
  printAt($display{row}+1,$display{column}+1,reverse @rows);
};

# routine that prints multiline strings at specific points on the terminal window
sub printAt{
	my ($row,$column,@textRows)=@_;
	my $blit="\033[?25l";
	$blit.= "\033[".$row++.";".$column."H".$_ foreach (@textRows) ;
	print $blit;
};

# sets the boundaries for a number assignment 
sub bound{  
	my ($number,$min,$max)=@_;
	return $max if $number>$max;
	return $min if $number<$min;
	return $number;	
}

sub colour{
	return "" unless $display{enableColours};
	my @formats=map {lc $_} @_;
	my %colours=(black=>30,red=>31,green=>32,yellow=>33,blue=>34,magenta=>35,cyan=>36,white=>37,reset=>0,
	             bold=>1, italic=>3, underline=>4, strikethrough=>9,);
	return join "",map {"\033[$colours{$_}m"}@formats;
}
