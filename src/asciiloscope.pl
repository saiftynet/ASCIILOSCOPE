#!/usr/env/perl
#                      ASCIILOSCOPE
# A Terminal based real-time analog data visualisation tool.
# for more information visit:- https://github.com/saiftynet/ASCIILOSCOPE
# This program ANSI terminal escape codes for positioning and colours
# Not all terminals can handle these, sadly.

use strict;use warnings;

initialise();   # This function introduces the Trace and Display Package
                # as a subroutine.  one could put thes packages into
                # pm files, but included in this form for convenience

my $display=new Display(       # display parameters
   showLogo   =>0,             # show scrolling logo or not
   showMenu   =>1,             # show menu or not
   enableColours=>1,           # enable colours
   refreshRate =>100,
);

# create a chart widget containing traces
$display->chart({id=>"scope",row=>2,column=>8,height=>15,width=>50,
              borderStyle=>"double",borderColour=>"bold blue",
              title=>"ASCIIloscope Demo",titleColour=>"black on_yellow",
              traces=>[new Trace(traceFile=>"sin.trc") ] }); 

# create a statistics widget
$display->statBox({id=>"stat",row=>20,column=>8,height=>2,width=>50,
              borderStyle=>"double",borderColour=>"bold red",
              title=>"Statistics",titleColour=>"black on_yellow",});  

# add/ modify action to a key press..tabs previously just changed activeTrace
# now it also updates the statBox
$display->addAction(9,{userProc=>sub{
     $display->statBox("stat");
  }
});   

# add trace to existing 
$display->addTrace( new Trace(traceFile=>"ramp.trc") ,"scope");   

$display->run("scope");

exit;


## the following initialises twa packages Traces for handling the traces and
## Display that handles the display.  Ordinarily these would be loaded from .pm
## filed at a convenient @INC location, using `use`, but contained in this file
## for the time being for convenience.

sub initialise{
  
package Trace;
  use strict; use warnings;
  
  our $VERSION    = '0.10';
  
  sub new{
    my ($class, %args) = @_;
    my $self={};
    $self->{trace}={};
    foreach (keys %args){
         $self->{$_}=$args{$_} unless $_ eq "traceFile";
      }
    bless ($self,$class);
    loadTrace($self, "./".$args{traceFile}) if  $args{traceFile}; #and -e $args{traceFile};
    return $self;  
  }
  
  sub help{
    print "help\n";
  }
  
  sub loadTrace{
  my ($self,$traceFile)=@_;
  die "file $traceFile not found $!" unless -e $traceFile;
  my %import=do "./$traceFile" or die "Failed to load external traces $traceFile $!";
    foreach (keys %import){
      $self->{$_}=$import{$_};
    }
    $self->{data}=[] unless $self->{data};
    $self->nextData while @{$self->{data}}<$self->{dataWindow};
  }  
  
  sub nextData{
  my $self=shift;
  $self->{source}($self);  
  }
  sub setPlotArea{
   my ($self,$height,$width)=@_;
   $self->{height}= $height;
   $self->{width} = $width ;
     $self->autoLevels();
  }
  
  sub scatterPlot{
  my ($self,$plotArea)=@_;
  $plotArea//=[(" " x $self->{width}) x $self->{height}];
  return $plotArea if $self->{hidden};
  my @plots=map {$self->{data}[$_]?
      [int( $_*$self->{xMult}) ,
      bound (int($self->{yMult}*$self->{data}[$_] +$self->{yOffset}-.5),
         0,$self->{height}-1)]:()
       } (0..(@{$self->{data}}-1));
  foreach (@plots){
      substr ($plotArea->[$$_[1]], $$_[0],1,$self->{symbol}) if $$_[1]<$self->{height} and $$_[0]<$self->{width};
    }     
  return $plotArea
  }
  
  sub zeroLine{
  my ($self,$plotArea)=@_;
  my $zeroLine=bound($self->{yOffset}-0.5,0,$self->{height}-1);
  $plotArea->[$zeroLine]=~s/ /-/g;
  return $plotArea
  }
  
  sub colourise{
  my ($self,$plotArea)=@_;
  my $colour=$display->colour($self->{colour});my $reset=$display->colour("reset");
  foreach my $row (0..@$plotArea-1){
       $$plotArea[$row]=~s/([$self->{symbol}]+)/$colour$1$reset/g;
     }
  return $plotArea;
  }
  
  sub autoLevels{
    my $self=shift;
    $self->stats();
    $self->{yMult}=($self->{height}-2)/($self->{stats}{max}-$self->{stats}{min});
    $self->{yOffset}=-$self->{stats}{min}*$self->{yMult}+1;
    $self->{xMult}=$self->{width}/(scalar @{$self->{data}});
  };
 
 sub stats{
  my $self=shift;
  unless ($self->{data}->[0]){
    $self->nextData while @{$self->{data}}<$self->{dataWindow};
  }
    $self->{stats}{max}=$self->{data}->[0];$self->{stats}{min}=$self->{data}->[0]; $self->{stats}{sum}=0;
    my $squares=0;
    foreach my $y (@{$self->{data}}){
    next unless $y;
      $self->{stats}{max}=$y if  $y>$self->{stats}{max};
      $self->{stats}{min}=$y if  $y<$self->{stats}{min};
      $self->{stats}{sum}+=$y;
      $squares+=$y**2;
    } 
    $self->{stats}{mean}=$self->{stats}{sum}/$self->{dataWindow};
    $self->{stats}{rms}=sqrt ($squares/$self->{dataWindow});
    
 }
 
 sub bound{  
  my ($number,$min,$max)=@_;
  return $max if $number>$max;
  return $min if $number<$min;
  return $number;  
  }  
  
  sub getset{
    my ($self,$key,$value)=@_;
    $self->{$key}=$value if $value;
    return $self->{$key};
  }    
    
1;
package Display;
use strict; use warnings;
use Time::HiRes ("sleep");      # allow fractional sleeps 
use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";
use Term::ReadKey;              # allow reading from keyboard
our $key;        
our @traceNames;
our $activeTrace;
our $lastTrace;

our $VERSION    = '0.10';

our %actions=(                  # for keyboard driven actions
   9=>{ # tab makes next trace active
     note=>"Tab = next trace",
     proc=>sub{my ($self,$tr)=@_;
       $lastTrace=$activeTrace;
       $activeTrace=pop @traceNames;
       unshift @traceNames,$activeTrace }
   },
   104=>{ # h hides trace
     note=>"h = Hide/show",
     proc=>sub{my ($self,$tr)=@_;$$tr{hidden}=!$$tr{hidden};},
   },
   113=>{ # q exits
     note=>"q = Exit",
     proc=>sub{ printAt(20,0,"Goodbye!");exit;},
   },
   112=>{  # Pause display (loop continues so keyboard is read)
     note=>"p = Pause/Resume",
     proc=>sub{my ($self,$tr)=@_;$self->{pause}=!$self->{pause}},
   },
   115=>{  # stop individual trace
     note=>"s = Stop trace/go",
     proc=>sub{my ($self,$tr)=@_;$$tr{frozen}=!$$tr{frozen}},
   },
   97 =>{  # Auto levels based on the current contents of @list
     note=>"a = Auto levels",
     proc=>sub{my ($self,$tr)=@_;$self->{traces}{$activeTrace}->autoLevels()},
   },
   67 =>{  # increase sample rate by 10
     note=>"→ = Speed up",
     proc=>sub{my ($self,$tr)=@_;$self->{refreshRate}+=10;},
   },
   68 =>{  # reduce sample rate by 10
     note=>"← = Slow down",
     proc=>sub{my ($self,$tr)=@_;$self->{refreshRate}=$self->{refreshRate}>10?$self->{refreshRate}-10:10;},
   },
   65 =>{  # shift display up by 1
     note=>"↑ = Shift up",
     proc=>sub{my ($self,$tr)=@_;$self->{traces}{$activeTrace}{yOffset}+=1;},
   },
   66 =>{ # shift display down by 1
     note=>"↓ = Shift down",
     proc=>sub{my ($self,$tr)=@_;$self->{traces}{$activeTrace}{yOffset}-=1;},
   },   
   42 =>{ # increase samples per full width0..(@{$currentTrace{data}}
     note=>"* = Inc Window",
     proc=>sub{my ($self,$tr)=@_;unshift @{$self->{traces}{$activeTrace}{data}},($self->{traces}{$activeTrace}{data}[0]) x 10;
             $self->{traces}{$activeTrace}{xMult}=$$tr{width}/(scalar @{$self->{traces}{$activeTrace}{data}});},
   },
   47 =>{ # decrease samples per full width
     note=>"/ = Dec Window",
     proc=>sub{my ($self,$tr)=@_;@{$$tr{data}}=@{$$tr{data}}[9..@{$$tr{data}}] if  @{$$tr{data}}>15;
             $$tr{xMult}=$$tr{width}/( @{$$tr{data}});},
   },
   43 =>{ # increase multiplier by 10%
     note=>"+ = Magnify",
     proc=>sub{my ($self,$tr)=@_;return unless $activeTrace;$self->{traces}{$activeTrace}{yMult}*=1.1;},
   },
   45 =>{ # reduce multiplier by 10%
     note=>"- = Reduce",
     proc=>sub{my ($self,$tr)=@_;$self->{traces}{$activeTrace}{yMult}*=0.9;},
   },
);

our %borders=(
  simple=>{tl=>"+", t=>"-", tr=>"+", l=>"|", r=>"|", bl=>"+", b=>"-", br=>"+",},
  double=>{tl=>"╔", t=>"═", tr=>"╗", l=>"║", r=>"║", bl=>"╚", b=>"═", br=>"╝",},
  thin  =>{tl=>"┌", t=>"─", tr=>"┐", l=>"│", r=>"│", bl=>"└", b=>"─", br=>"┘",},  
  thick =>{tl=>"┏", t=>"━", tr=>"┓", l=>"┃", r=>"┃", bl=>"┗", b=>"━", br=>"┛",}, 
);

sub new{
    my ($class, %args) = @_;
    my $self={};
    $self->{traces}={};
    foreach (keys %args){
         $self->{$_}=$args{$_}
      }
      $self->{widgets}={};
      bless ($self,$class);
      $self->logo()  if $self->{showLogo};
      $self->menu()  if $self->{showMenu};
      return $self;
}

sub printAt{
  my ($row,$column,@textRows)=@_;
  @textRows = @{$textRows[0]} if ref $textRows[0];  
  my $blit="\033[?25l";
  $blit.= "\033[".$row++.";".$column."H".$_ foreach (@textRows) ;
  print $blit;
  print "\n"; # seems to flush the STDOUT buffer...if not then set $| to 1 
};

sub box{
  my ($self,$widgetData)=@_;
  $self->addWidget("box",$widgetData) unless $$widgetData{type};
  my %args=%$widgetData;
  $args{borderStyle}//="simple";
  my ($colour, $reset)=("","");
  if ($args{borderColour}){
    $colour=$self->colour($args{borderColour});
    $reset =$self->colour("reset");
  }
  my %border=%{$borders{$args{borderStyle}}};
  printAt ($args{row}-1,$args{column}-1,
      $colour.$border{tl}.($border{t} x $args{width}).$border{tr},
      ($border{l}.(" " x $args{width}).$border{r}) x $args{height},
      $border{bl}.($border{b} x $args{width}).$border{br}.$reset );
  if ($$widgetData{title}){
    printAt($args{row}-1,$args{column}+2,$self->colour($$widgetData{titleColour})." ".$$widgetData{title}." ".$self->colour("reset"));
  }
  print "\033[". 23 .";". 0 . "H";
}

sub chart{
  my ($self,$widgetData)=@_;
  $widgetData=$self->{widgets}{$widgetData} unless ref $widgetData;
  my %args=%$widgetData;
  unless ($$widgetData{type}){ # if widget not previously added
    $self->box($widgetData);
    my $legendRow=$args{height}+$args{row};
    my $legendColumn=$args{column}+2;
    foreach my $trace (@{$args{traces}}){
      $trace->setPlotArea($args{height},$args{width});
      printAt($legendRow,$legendColumn," ".$self->colour($trace->{colour}).$trace->{symbol}." ".$trace->{name}." ");
      $legendColumn+=5+length $trace->{name};
      $self->{traces}{$trace->{name}}=$trace;
      push @traceNames,$trace->{name};
      $activeTrace=$trace->{name};
      die unless defined $self->{traces}{$activeTrace}{yMult};
    } ;
    $$widgetData{started}=1;
    $self->addWidget("chart",$widgetData);
  };
  my $plot;
    unless ($self->{pause}){
    undef $plot;
    return unless @{$args{traces}};
    foreach my $trace (@{$args{traces}}){
      $plot= $trace->scatterPlot($plot) ;
      $plot= $trace->zeroLine ($plot) if $trace->{name} eq $activeTrace;
      $trace->nextData() unless $trace->{frozen};
    }
    foreach my $trace (@{$args{traces}}) {
      $plot=$trace->colourise($plot)
    }
    printAt ($args{row},$args{column}, reverse @$plot);
  }
}  

sub statBox{  #a widget that displays the statistics for current widget
  my ($self,$widgetData)=@_;
  $widgetData=$self->{widgets}{$widgetData} unless ref $widgetData;
  my %args=%$widgetData;
  unless ($$widgetData{type}){
     $self->box($widgetData);
    }
  printAt ($args{row},$args{column},       
     map{$_?statString($self,$_):()}($activeTrace,$lastTrace) );
     
     
  sub statString{
    my ($self,$traceName)=@_;    
    $self->{traces}{$traceName}->stats();
    return colour($self,$self->{traces}{$traceName}{colour}).($self->{traces}{$traceName}{name}).colour($self,"reset").
     " max=" .(sprintf "%.3g",$self->{traces}{$traceName}{stats}{max}).
     " min=" .(sprintf "%.3g",$self->{traces}{$traceName}{stats}{min}).
     " mean=".(sprintf "%.3g",$self->{traces}{$traceName}{stats}{mean}).
     " rms=" .(sprintf "%.3g",$self->{traces}{$traceName}{stats}{rms})
    
  }
}

sub addAction{
  my ($self,$key, $actionData)=@_;
  my %args=%$actionData;
  foreach my $k (keys %args){
    $actions{$key}{$k}=$args{$k};
  }
}

sub addTrace{
  my ($self, $trace, $widget)=@_;
  push @{$self->{widgets}{$widget}{traces}},$trace;
  foreach my $tr (@{$self->{widgets}{$widget}{traces}}){
    foreach  (0..$#traceNames){
      if ($tr->{name} eq $traceNames[$_]){
        splice @traceNames, $_, 1;
        last;
      }
    }
  }
  $self->{widgets}{$widget}{type}=undef;
  $self->chart($widget)
}

sub run{
  my ($self,@widgetIds)=@_;
  ReadMode 'cbreak';
  while(1){
    foreach my $id(@widgetIds){
    if (exists $self->{widgets}->{$id}){
      if ($self->{widgets}->{$id}->{type} eq "chart"){$self-> chart($id)} 
    }
    }
  sleep 1/$self->{refreshRate};
  $key = ReadKey(-1);                # -1 means non-blocking read
  if ($key){
    my $OrdKey = ord($key);
    printAt (20,60,"key pressed=$OrdKey");
    # Keys actions are stored in %actions
    $actions{$OrdKey}{proc}->($self,$self->{traces}{$activeTrace}) if defined $actions{$OrdKey}{proc} and $activeTrace;
    $actions{$OrdKey}{userProc}->($self,$self->{traces}{$activeTrace}) if defined $actions{$OrdKey}{userProc};    
  }
  }  
  ReadMode 'normal';  
}  

sub addWidget{
  my ($self,$type,$widgetData)=@_;
  $$widgetData{type}=$type;
  $self->{widgets}->{$$widgetData{id}}=$widgetData;
}

sub drawWidget{
  my ($self,$widgetData)=@_;
  if ($$widgetData{type}=="box") { $self->box($widgetData); };
}

sub scrollIn{
  my ($row,$column,$width,@message)=@_;
  my $at=$column+$width;my $start=0;
  my $l=length $message[0];
  foreach my $section(0..$width+$l){
    my @sliced=();
    $start++ if $section>$width;
    my $length=$section<$width?$section:($width+$l-$section+1)>$width?$width:($width+$l-$section+1);
    
    foreach my $mRow (@message){
    push @sliced,(substr $mRow." ",$start,$length);
     }
   printAt ($row,$at, @sliced);  
   $at-- unless $at==$column;
     sleep 0.02;
    }
}

sub logo{
  my $self=shift;
  print $self->colour("bold yellow");
  scrollIn(8,8,70,
    '   _    ___   __  _______  _    ___   ___   __   ___   ___  ___ ',
    '  /_\  / __| / _||_ _|_ _|| |  / _ \ / __| / _| / _ \ |  _\| __|',
    ' / _ \ \__ \| (_  | | | | | |_| (_) |\__ \| (_ | (_) || |_/| _| ',
    '/_/ \_\|___/ \__||___|___||___|\___/ |___/ \__| \___/ |_|  |___|');
    print $self->colour("reset");
}

sub menu{
  my $self=shift;
  # Print Menu...disable by setting $display{showMenu} to zero
    printAt( 2,62, $self->colour("underline")."MENU".$self->colour("reset"),map{$actions{$_}{note} } sort { $a <=> $b } keys %actions);
}

## colour handling routines....could be more elegantly done iusing Term::ANSIColor
## This is a more compact version

sub stripColours{
  my $line=shift;
  $line=~s/\033\[[^m]+m//g;
  return $line;
}

sub colour{
  my ($self,$fmts)=@_;
  return "" unless $fmts and $self->{enableColours}; 
  my @formats=map {lc $_} split / +/,$fmts;   
  my %colours=(black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, strikethrough=>9,);
  return join "",map {defined $colours{$_}?"\033[$colours{$_}m":""} @formats;
}

1;
}
