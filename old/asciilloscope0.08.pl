#!/usr/env/perl
#                      ASCIILOSCOPE
# A Terminal based real-time analog data visualisation tool.
# for more information visit:- https://github.com/saiftynet/ASCIILOSCOPE
# This program ANSI terminal escape codes for positioning and colours
# Not all terminals can handle these, sadly.
 
use strict; use warnings;
use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";
use Time::HiRes ("sleep");      # allow fractional sleeps
use Term::ReadKey;              # allow reading from keyboard
my $key;                      

my $VERSION=0.08;
# display parameters stored in hash for future conversion into an
# object orientated module 
my %traces;

%traces=(
  sin=>{
	data           =>[(undef) x 55],
	dataWindow     =>55,
    internals=>{x=>1},
    symbol   => "*",
    colour   => "red bold",
    source  => sub{
		shift @{$traces{sin}{data}} ;
		$traces{sin}{internals}{x}=0 if $traces{sin}{internals}{x}>200;
		push @{$traces{sin}{data}},sin (3.14*$traces{sin}{internals}{x}++/20)
		},
  },
  cos=>{
	data           =>[(undef) x 55],
	dataWindow     =>55,
    internals=>{x=>1},
    symbol   => "o",
    colour   => "green",
    source  => sub{
		shift @{$traces{cos}{data}} ;
		$traces{cos}{internals}{x}=0 if $traces{cos}{internals}{x}>200;
		push @{$traces{cos}{data}},cos (3.14*$traces{cos}{internals}{x}++/20)
		},
	}
);

my %borders=(
  simple=>{tl=>"+", t=>"-", tr=>"+", l=>"|", r=>"|", bl=>"+", b=>"-", br=>"+",},
  double=>{tl=>"╔", t=>"═", tr=>"╗", l=>"║", r=>"║", bl=>"╚", b=>"═", br=>"╝",},
);

my %display=(                  # display parameters
   showLogo   =>1,             # show logo or not
   showMenu   =>1,             # show menu or not
   enableColours=>1,           # enable colours
   borderStyle=>"double",      # border style
   height    =>15,             # vertical characters
   width     =>50,             # horizontal characters
   row       =>2,              # vertical position (from top left)
   column    =>8,              # horizontal position
   sampleRate=>100,            # number of samples per second
);
  
# traces may be disabled from being loaded by setting a disabled key
my @traceNames=map {$traces{$_}{disabled}?():$_} keys %traces;
my $activeTrace=$traceNames[0]//"";

my %actions=(                  # for keyboard driven actions
   9=>{ # tab makes next trace active
	   note=>"Tab = next trace",
	   proc=>sub{$activeTrace=pop @traceNames;
		   unshift @traceNames,$activeTrace; }
   },
   104=>{ # h hides trace
	   note=>"h = Hide/show",
	   proc=>sub{$traces{$activeTrace}{hidden}=!$traces{$activeTrace}{hidden};},
   },
   113=>{ # q exits
	   note=>"q = Exit",
	   proc=>sub{ printAt($display{row}+$display{height}+9,0,"Goodbye!");exit;},
   },
   112=>{  # Pause display (loop continues so keyboard is read)
	   note=>"p = Pause/Resume",
	   proc=>sub{$display{pause}=!$display{pause}},
   },
   115=>{  # stop individual trace
	   note=>"s = Stop trace/go",
	   proc=>sub{$traces{$activeTrace}{frozen}=!$traces{$activeTrace}{frozen}},
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
	   proc=>sub{$traces{$activeTrace}{yOffset}+=1;},
   },
   66 =>{ # shift display down by 1
	   note=>"🠋 = Shift down",
	   proc=>sub{$traces{$activeTrace}{yOffset}-=1;},
   },   
   42 =>{ # increase samples per full width0..(@{$currentTrace{data}}
	   note=>"* = Inc Window",
	   proc=>sub{unshift @{$traces{$activeTrace}{data}},($traces{$activeTrace}{data}[0]) x 10;
		         $traces{$activeTrace}{xMult}=$display{width}/(scalar @{$traces{$activeTrace}{data}});},
   },
   47 =>{ # decrease samples per full width
	   note=>"/ = Dec Window",
	   proc=>sub{@{$traces{$activeTrace}{data}}=@{$traces{$activeTrace}{data}}[9..@{$traces{$activeTrace}{data}}] if  @{$traces{$activeTrace}{data}}>15;
		         $traces{$activeTrace}{xMult}=$display{width}/( @{$traces{$activeTrace}{data}});},
   },
   43 =>{ # increase multiplier by 10%
	   note=>"+ = Magnify",
	   proc=>sub{$traces{$activeTrace}{yMult}*=1.1;},
   },
   45 =>{ # reduce multiplier by 10%
	   note=>"- = Reduce",
	   proc=>sub{$traces{$activeTrace}{yMult}*=0.9;},
   },
);

# example initial dataset...a sine wave preloaded to allow scaling -1 to 1
# subsequent data can be autoscaled again as required.  
foreach my $trace (@traceNames){
  $traces{$trace}{source}->() for (0..$traces{$trace}{dataWindow}); 
}
# Main routine
initialScreen();   # draw screen
foreach (@traceNames){
	$activeTrace=$_;
	autoLevels();
	};      # auto adjust the scaling based on initial sample
	
startScope();      # the loop that updates the scope's display



# draws the frame and other features outside the 
sub initialScreen{           
	my @frame=();
   
    #  Borderstyle...display{borderStyle} chooses style
    my %border=%{$borders{$display{borderStyle}}};
	foreach (0..$display{height}-1){
		$frame[$_]=$border{l}.(" "x$display{width}).$border{r};
	}
	unshift @frame,colour("blue bold").$border{tl}.($border{t}x$display{width}).$border{tr};
	my $bLine=join $border{b}x2, map {colour($traces{$_}{colour})." $traces{$_}{symbol} $_ ".colour("blue bold")} @traceNames;
	my $bLineLength=length stripColours($bLine);
	$bLine=($border{b}x2).$bLine.($border{b}x($display{width}-2-$bLineLength));
    push    @frame,$border{bl}.$bLine.$border{br}.colour("reset");
    printAt($display{row},$display{column},@frame);
    
    # Print Menu...disable by setting $display{showMenu} to zero
    printAt( 3,$display{width}+$display{column}+3,
        map{$actions{$_}{note} } sort { $a <=> $b } keys %actions) if $display{showMenu};;
    
    # Print logo...disable by setting $display{showLogo} to zero
    printAt($display{row}+$display{height}+2,$display{column}-2<0?0:$display{column}-2,
    colour("yellow bold").
    '   _    ___   __  _______  _    ___   ___   __   ___   ___  ___',
    '  /_\  / __| / _||_ _|_ _|| |  / _ \ / __| / _| / _ \ |  _\| __|',
    ' / _ \ \__ \| (_  | | | | | |_| (_) |\__ \| (_ | (_) || |_/| _| ',
    '/_/ \_\|___/ \__||___|___||___|\___/ |___/ \__| \___/ |_|  |___|'." v$VERSION".
    colour("reset") 
    ) if $display{showLogo};
};

# uses the data in the @list to autscale the waveform for display
sub autoLevels{
  my $max=$traces{$activeTrace}{data}[0];my $min=$traces{$activeTrace}{data}[0];
  foreach my $y (@{$traces{$activeTrace}{data}}){
    $max=$y if  $y>$max;
    $min=$y if  $y<$min;
  } 
  $traces{$activeTrace}{yMult}=($display{height}-2)/($max-$min);
  $traces{$activeTrace}{yOffset}=-$min*$traces{$activeTrace}{yMult}+1;
  $traces{$activeTrace}{xMult}=$display{width}/(scalar @{$traces{$activeTrace}{data}});
};

# The scope function
sub startScope{
  ReadMode 'cbreak';
  while(1){
	unless ($display{pause}){  # unless pausing continue updatingftea
	  foreach (@traceNames){
		$traces{$_}{source}->() unless $traces{$_}{frozen} 
	   }
	};
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
  my @rows=(" "x$display{width})x$display{height};
  foreach my $tr (@traceNames){
	  next if $traces{$tr}{hidden};
	  my @plots2=map {$traces{$tr}{data}[$_]?
			[int( $_*$traces{$tr}{xMult}) ,
			bound (int($traces{$tr}{yMult}*$traces{$tr}{data}[$_] +$traces{$tr}{yOffset}-.5),
				 0,$display{height}-1)]:()
			 } (0..(@{$traces{$tr}{data}}-1));
		
		foreach (@plots2){
		  substr ($rows[$$_[1]], $$_[0],1,$traces{$tr}{symbol});
		}
	}
	my $zeroLine=bound($traces{$activeTrace}{yOffset},0,$display{height}-1);
	$rows[$zeroLine]=~s/ /-/g;
   
   foreach my $tr (@traceNames){
	  next if $traces{$tr}{hidden};
	   my $colour=colour($traces{$tr}{colour});my $reset=colour("reset");
	   my $symbol=$traces{$tr}{symbol};
	   foreach my $row (0..$#rows){
		   $rows[$row]=~s/([$symbol]+)/$colour$1$reset/g;
	   }
   }
   # reverse rows and print as screen counts zero as top 
   printAt($display{row}+1,$display{column}+1,reverse @rows);
};



# sets the boundaries for a number assignment 
sub bound{  
	my ($number,$min,$max)=@_;
	return $max if $number>$max;
	return $min if $number<$min;
	return $number;	
}

### The following are the routines that use ANSI Colour/position codes.
### Should be adapted if wanting to be ported for non ANSI terminal e.g.
### create Curses routines. Effects can be also produced using


# routine that prints multiline strings at specific points on the terminal window
# takes array of string or ref to such an array
sub printAt{
	my ($row,$column,@textRows)=@_;
	@textRows = @{$textRows[0]} if ref $textRows[0];  
	my $blit="\033[?25l";
	$blit.= "\033[".$row++.";".$column."H".$_ foreach (@textRows) ;
	print $blit;
};

# allows colour to be set
sub colour{
	return "" unless $display{enableColours};
	my $fmts=shift; return "" unless $fmts; 
	my @formats=map {lc $_} split / /,$fmts;
	my %colours=(black=>30,red=>31,green=>32,yellow=>33,blue=>34,magenta=>35,cyan=>36,white=>37,reset=>0,
	             bold=>1, italic=>3, underline=>4, strikethrough=>9,);
	return join "",map {defined $colours{$_}?"\033[$colours{$_}m":""} @formats;
}

# remove formating esc codes from string
sub stripColours{
  my $line=shift;
  $line=~s/\033\[[^m]+m//g;
  return $line;
}

