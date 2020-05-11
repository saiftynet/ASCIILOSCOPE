# ASCIILOSCOPE
An oscilloscope in ASCII

The objective of this utility is to create a real time graphical monitoring of changing data from a terminal. The target applications may be monitoring electrical signals.  Clearly this is not as representative as a true graphical display, but it allows a simple illustration of input changes.  For my purposes it will allow me to select multipliers and offsets adjustments for signal captures by sensors for other applications.  It is also a test bed for the development of CursesSprites and eventual PerlayStation Terminal Games Console.  The development of these have been temporarily paused while I improve my understanding of terminal applications development (I am thinking of eventually disposing of Curses altogether, so Curses is not used in this application).  See [CHANGES](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/CHANGES.md) for updates. Conversion to a GUI, vector tracing appplication is projected, and may only require minor changes.

![Vesion 0.09](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/images/asciiloscope%20dual%20trace.gif)

Ihe display can be positioned and sized as needed. The keyboard is monitored for functions to be added as development continues.

### Features and function
This can be illustrated using the screenshot below.
![Screenshot2](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/images/Version%200.09.jpg)

* Tab = Makes next trace active if there are multiple traces
* q   = Quits the application
* p   = Pauses display and data capture for all traces
* s   = Stop/resume individual traces
* h   = hide/show traces
* a   = Auto levels, adjusts multipliers and offset so data fits in the screen
* &#8594;   = Speed up increase number of updates per second by 10
* &#8592;   = Slow down, reduce number of updates per second by 10
* &#8593;   = Shift up, increase offset so trace moves up the display
* &#8595;   = Shift down, decrease offset so trace moves down the display
* \*    = Inc Window, increase samples per full width of the screen
* \/    = Dec Window, decrease samples per full width of the screen
* \+    = Magnify, increase Y multiplier by 10%, zooming into trace
* \-    = Reduce, reduce multiplier by 10%, zooming out

### Adding traces
Traces were previously (from v 0.06) stored in a hash called, unsurpisingly, `%traces`.  From v 0.09, they can be created within the script, or preferably loaded from a external `.trc` (extension is suggested, not required). Files are structured like the conetents of a hash.

```
description   =>"Sine Trace",
name          =>"sin",
dataWindow    =>50,
internals     =>{x=>1},
symbol        => "*",
colour        => "red bold",
source        => sub{
                 my $self=shift;
		         shift @{$self->{data}} if @{$self->{data}}>$self->{dataWindow};
		         $self->{internals}{x}=0 if $self->{internals}{x}>200;
		         push @{$self->{data}},sin (3.14*$self->{internals}{x}++/20);
		      },
```
* `desription` is a user friendly description of the function
* `name` is the name of the trace and needsto be unique
* `dataWindow` is the number of data points displayed in each frame
* `internals` are specific to the plot where the user may store the internal variables for the trace functions
* `symbol` is the symbol used for the plot
* `source->()` is the function that retrieves the next data point. For illustration examples of sin and cos traces are supplied. Typically the function would remove the oldest datapoint (using `shift`) and insert (using `push`) the newest one at the other end. May be more reasonable to put in example triangle, sawtooth, square wave. A future trace will be the internal "trigger". The main purpose of this function is to capture external data for plotting.
* `colour` is a string of formatting options separated by spaces, e.g. "bold red strikethrough"

### Options
The display from version 0.09 onwards, the display setu up by creating a Display object.
```
my $display=new Display(       # display parameters
   showLogo   =>1,             # show scrolling logo or not
   showMenu   =>1,             # show menu or not
   enableColours=>1,           # enable colours
   refreshRate =>100,
);
```
### Creating a Trace Widget
It shoudld be possible to create multiple trace widgets. Widgets are given ids, and updated depdendent on `$display->{refreshRate}`.

```
# create a chart widget containing traces, and then "run" the scope
$display->chart({id=>"scope",row=>4,column=>8,height=>17,width=>50,
	            borderStyle=>"double",borderColour=>"bold blue",
	            title=>"ASCIIloscope Demo",titleColour=>"black on_yellow",
	            traces=>[@traces]});
$display->run("scope");
```

`$display->run(<widgetId list>)` starts a loop that redraws the contents of the widgets listed by their ids.

###  Dependencies
* Time::HiRes
* Term::ReadKey;  
* ANSI compatible terminal

### Things to do: -
See [CHANGES](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/CHANGES.md) for updates.

* Manual scale and offset adjustment (done in v0.02)
* Manual sample rate adjustment      (done in v0.02)
* Autoscaling is already implemented (in v0.02 can now be triggered any time)
* Drift adjustment                   (done in v0.04)
* Colour                             (done in v0.05 and improved in 0.07)
* Multiple independent traces        (done in v0.05)
* Triggers and Storage modes         
* Freeze frame                       (done in v0.07) 
* Export data to CSV and graphically to SVG
* Data anaylsis
* OO redesign                        (done in 0.09)


