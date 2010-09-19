/* Events -- This file supports the system events
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: events.as,v 1.10 2003/06/26 04:56:31 abansod Exp $
 */ 

_global.EVENT_BASE_EVENTNUMBER		= 0;

/* ----- Events sent to modules ----- */

// event module needs to intialize
_global.EVENT_MODULE_INITALIZE		= EVENT_BASE_EVENTNUMBER;

// event module needs to finalze
_global.EVENT_MODULE_FINALIZE		= EVENT_BASE_EVENTNUMBER + 1;

// user requested advancement, but it failed
_global.EVENT_NAVIGATION_ADVANCEFAILED	= EVENT_BASE_EVENTNUMBER + 2;

// event module should layout itself
_global.EVENT_MODULE_PAINT		= EVENT_BASE_EVENTNUMBER + 3;

/* ----- Events Navigation sends to Runtime and itself ----- */

// the caller must continue to navigation (this was a non navigable node)
_global.EVENT_NAVIGATION_RENAVIGATE	= EVENT_BASE_EVENTNUMBER + 4;

// error occured in the navigations
_global.EVENT_NAVIGATION_ERROR		= EVENT_BASE_EVENTNUMBER + 5;

// successfully navigated
_global.EVENT_NAVIGATION_SUCCESS	= EVENT_BASE_EVENTNUMBER + 6;

// a set tag was encoutered
_global.EVENT_NAVIGATION_SET		= EVENT_BASE_EVENTNUMBER + 7;

// attempt to navigate forward
_global.EVENT_NAVIGATION_ATTEMPTFORWARD	= EVENT_BASE_EVENTNUMBER + 8;

// attempt to navigate backwards
_global.EVENT_NAVIGATION_ATTEMPTBACK	= EVENT_BASE_EVENTNUMBER + 9;


/*  ----------  Sound Events are handled by library_soundControl ----- */

// play the sound, regardless of whether it is playing.
_global.EVENT_SOUNDCONTROL_PLAY				= EVENT_BASE_EVENTNUMBER + 10;

// pause the sound, regardless of whether it is playing.
_global.EVENT_SOUNDCONTROL_PAUSE			= EVENT_BASE_EVENTNUMBER + 11;

// if the sound is playing, pause it.  if it is paused or stopped, play it.
_global.EVENT_SOUNDCONTROL_TOGGLEPLAYPAUSE		= EVENT_BASE_EVENTNUMBER + 12;

// stop the sound, and rewind the track to the beginning.
_global.EVENT_SOUNDCONTROL_STOP				= EVENT_BASE_EVENTNUMBER + 13;

// rewind the track. does not affect play status.
_global.EVENT_SOUNDCONTROL_REWIND			= EVENT_BASE_EVENTNUMBER + 14;

// begin loading the sound, but don't play it.
_global.EVENT_SOUNDCONTROL_LOADWITHOUTPLAY		= EVENT_BASE_EVENTNUMBER + 15;

// begin loading the sound, and play when it is preloaded enough to stream
_global.EVENT_SOUNDCONTROL_LOADANDPLAYWHENBUFFERED	= EVENT_BASE_EVENTNUMBER + 16;

// begin loading the sound, and play when it is completely loaded.
_global.EVENT_SOUNDCONTROL_LOADANDPLAYWHENLOADED	= EVENT_BASE_EVENTNUMBER + 17;

/* ----- Events For Loader and PreLoader ----- */

// all modules were loaded
_global.EVENT_LOADER_SUCCESS				= EVENT_BASE_EVENTNUMBER + 18;

// preloader was unable to find file
_global.EVENT_LOADER_FILENOTFOUND			= EVENT_BASE_EVENTNUMBER + 19;

// the last number, all user level events go above this
_global.EVENT_BASE_LASTNUMBER				= EVENT_BASE_EVENTNUMBER + 20;

