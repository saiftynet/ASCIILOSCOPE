# ASCIILOSCOPE
An oscilloscope in ASCII

The objective of this utility is to create a real time graphical monitoring of changing data from a terminal. The target applications may be monitoring electrical signals.  Clearly this is not as representative as a true graphical display, but it allows a simple illustration of input changes.  For my purposes it will allow me to select multipliers and offsets adjustments for signal captures by sensors for other applications.  It is also a test bed for the development of CursesSprites and eventual PerlayStation Terminal Games Console.  The development of these have been temporarily paused while I improve my understanding of terminal applications development (I am thinking of eventually disposing of Curses altogether).

![Screenshot1](https://github.com/saiftynet/ASCIILOSCOPE/blob/master/images/asciiloscope.gif)

Ihe display can be positioned and sized as needed. The Keyboard is monitored for functions to be added as development continues

Things to do: -

* Manual scale and offset adjustment (partly done in v0.02)
* Manual sample rate adjustment      (done in v0.02)
* Autoscaling is already implemented (in v0.02 can now be triggered any time)
* Drift adjustment            
* Multiple traces
* Triggers and Storage modes
* Freeze frame
* Export data to CSV and graphically to SVG
* Data anaylsis


