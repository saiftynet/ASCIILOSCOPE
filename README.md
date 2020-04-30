# ASCIILOSCOPE
An oscilloscope in ASCII

The objective of this utility is to create a real time graphical monitoring of changing data from a terminal. The target applications may be monitoring electrical signals.  Clearly this is not as representative as a true graphical display, but it allows a simple illustration of input changes.  For my purposes it will allow me to select multipliers and offsets adjustments for signal captures by sensors for other applications.  It is also a test bed for the development of CursesSprites and eventual PerlayStation Terminal Games Console.  The development of these have been temporarily paused while I improve my understanding of terminal applications development (I am thinking of eventually disposing of Curses altogether).  See [CHANGES](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/CHANGES.md) for updates.

![Screenshot1](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/images/asciiloscope.gif)

Ihe display can be positioned and sized as needed. The Keyboard is monitored for functions to be added as development continues.

### Features and function
This can be illustrated using the screenshot below.

![Screenshot2](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/images/Version%200.06.jpg)

### Adding traces
Traces are currently (from v 0.06) stored in a hash called, unsurpisingly, `%traces`.  Within this the traces are stored as references to hashes e.g.

```
 cos=>{
  data           =>[(undef) x 55],
  dataWindow     =>55,
  internals      =>{x=>1},
  symbol         => "o",
  colour         => "green",
  source         => sub{
		shift @{$traces{cos}{data}} ;
		$traces{cos}{internals}{x}=0 if $traces{cos}{internals}{x}>200;
		push @{$traces{cos}{data}},cos (3.14*$traces{cos}{internals}{x}++/20)
  },
	
},
```
* `data` is the store of collected raw data. Initially populated with `undef`, these are preloaded with datapoints to allow autoscaling and plotting.
* `dataWindow` if the size of datastore
* `internals` are specific to the plot where the user may store the interbnal variables for the trace functions
* `symbol` is the sympbol used forthe plot
* `source->()` is the function that retrieves the next data point. For illustration examples of sin and cos traces are supplied. Typically the function would remove the oldest datapoint (using `shift`) and insert (using `push`) the newest one at the other end.
May be more reasonable to put in example triangle, sawtooth, squarewave. a future trace will be the internal "trigger". The main purpose of this function is to capture external data for plotting.

### Options
The display can be configured from the `$display` hash.
```
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
   );
```

### Things to do: -
See [CHANGES](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/CHANGES.md) for updates.

* Manual scale and offset adjustment (done in v0.02)
* Manual sample rate adjustment      (done in v0.02)
* Autoscaling is already implemented (in v0.02 can now be triggered any time)
* Drift adjustment                   (done in v0.04)
* Colour                             (done in v0.05 and improved in 0.07)
* Multiple independent traces        (done in v0.05)
* Triggers and Storage modes         
* Freeze frame                       (partly done in v0.04) 
* Export data to CSV and graphically to SVG
* Data anaylsis


