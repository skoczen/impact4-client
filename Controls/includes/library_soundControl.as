/*
// Events sent by soundControl
EVENT_SOUNDCONTROL_FAILEDLOAD
EVENT_SOUNDCONTROL_STOPPED
EVENT_SOUNDCONTROL_PLAYED
EVENT_SOUNDCONTROL_PAUSED
EVENT_SOUNDCONTROL_FINISHEDPLAYING
EVENT_SOUNDCONTROL_MUTED

e.g.
sendEventToModules(getCurrentModules(), EVENT_NAVIGATION_ADVANCEFAILED, "compositeFinalizable failed");
oh
replace currentModules with getCurrentModules()
// send an event to modules (either a single module or an array)
// set modules[0]="runtime" to raise a runtime event
// set modules[0]="navigation" to raise a navigation event
_global.sendEventToModules = function(modules, event, text)

// */

// Variables Used: 
var loadingAction = "stream";	// What to do when loading. Options are: 
								// stream - start playing as soon as possible, stream the sound.
								// preloadThenPlay - load the entire sound, then play it.
								// preloadAndStop - load the sound, but don't start playing. 
var playheadPosition = 0;		// position of the playhead, in seconds.
var playStatus = 0;				// status of playback:
								//	0 = stopped, playheadPosition = 0;
								//	1 = paused
								//	2 = playing
var pathToSounds = "Resources/";// Path to the sound files.


 
// Initialization								
var currentSound; // = new setCurrentSound("","","0:00");  	// sets up the currentSound Object		
var soundComplete = false; 		// tracks whether the sound is complete or not.
var playID; 	 // interval ID. 



// ********************* Functions ********************* // 
// ** Sets up the currentSound object.  trackURL and trackPlayLength are REQUIRED ** //
function setCurrentSound(	trackURL, 			// URL of the track (scoping assumes file is in /Resources
							trackName, 			// Text that describes the sound file
							trackPlayLength,	// Length of track. Format is m:ss.  
							trackVolume,		// Volume of playback. (0-100, 0 is silence).  Defaults to 100.
							trackDoneAction,	// Function to call when the track finishes playing.  Scoping needs to be correct. Optional.
							controlPlayPause, 	// Show the play/pause control. True shows, False hides.  Boolean, defaults to True.
							controlRewind, 		// Show the rewind control. True shows, False hides.  Boolean, defaults to True.
							controlMute,		// Show the mute control. True shows, False hides.  Boolean, defaults to True.
							controlStop			// Show the stop control. True shows, False hides.  Boolean, defaults to True.
							// soundObj			// The actual sound object. Not passed as a parameter.
							// trackSeconds		// The length of the track in seconds. Calculated on load based on trackPlayLength.
							// currentVolume 	// Actual volume of the track. Changes as mute is pressed. 
							) {
	
if ( existsAndValid(trackURL) ) {
		// check for http:// header - if there, don't add path.
		if (trackURL.substring(0,4) == "http" ) {
			this.trackURL = trackURL;
		} else {
			this.trackURL = pathToSounds + trackURL;
		}
	} else {
		st("Can't load soundtrack file!\n(trackURL (" + trackURL + ") is invalid)");
		showDialogMessage("Can't load soundtrack file!\n(trackURL is invalid)", new Array("OK") )
		sendEventToModules(getCurrentModules(), EVENT_SOUNDCONTROL_FAILEDLOAD, "trackURL is invalid");
	}

	this.trackName = trackName;
	if (existsAndValid(trackPlayLength) ) {
		this.trackPlayLength = trackPlayLength;
	} else {
		st("library_soundControl: ** ALERT ** trackPlayLength was not passed. Progress bar will not function correctly.");
	}
	
	if (existsAndValid(trackVolume) ) {
		this.trackVolume = trackVolume;
		
	} else {
		this.trackVolume = _getValue("impact4.configuration.currentVolume");
	
	}
	
	this.trackDoneAction = eval(trackDoneAction);
	if (!existsAndValid(controlPlayPause) ) {
		controlPlayPause = true;
	}
	if (!existsAndValid(controlRewind) ) {
		controlRewind = true;
	}
	if (!existsAndValid(controlMute) ) {
		controlMute = true;
	}
	if (!existsAndValid(controlStop) ) {
		controlStop = true;
	}	
	this.trackControls = new trackControlObj(controlPlayPause, controlRewind, controlMute, controlStop);
	this.currentVolume = this.trackVolume;
	this.soundObj = new Sound();
								
	return this;					
}
							

// ** Creates a trackControls object. ** //
function trackControlObj(playPause, rewind, mute, controlStop) {
	this.playPause = playPause;
	this.rewind = rewind;
	this.mute = mute;
	this.stopSound = controlStop;
	
	return this;
	
}


// Called every half-second, updates progress bar, checks for completion or load. 
function updateTrackStatus() {

	// set volume
	currentSound.soundObj.setVolume(currentSound.currentVolume);

	// update seconds elapsed.
	totalSecondsElapsed = currentSound.soundObj.position / 1000;
	minutesElapsed = Math.floor(totalSecondsElapsed / 60);
	secondsElapsed = Math.round(totalSecondsElapsed % 60);
	if (secondsElapsed < 10) {updateSoundControls
		secondsElapsed = "0" + secondsElapsed;
	}

	elapsedString = minutesElapsed + ":" + secondsElapsed;
	percentElapsed = (totalSecondsElapsed / currentSound.trackSeconds) * 100;
	percentElapsed = (percentElapsed >= 100) ? 100: percentElapsed;

	// check for completion
	if (percentElapsed == 100 && totalSecondsElapsed > 0.5) {
		if (!soundComplete) {
			soundIsComplete();
		}
	}


	trackDurationLoaded = currentSound.soundObj.duration;
	totalSecondsLoaded = trackDurationLoaded / 1000;
	percentLoaded = (totalSecondsLoaded / currentSound.trackSeconds) * 100;
	percentLoaded = (percentLoaded > 100) ? 100: percentLoaded;
	
	updateSoundControls(elapsedString, percentElapsed, percentLoaded);
	
	

}



function updateSoundControls(timeElapsedString, percentElapsed, percentLoaded) {
	progressBar.setBarPercent(percentElapsed);
	progressBar.setLoadedPercent(percentLoaded);
	progressBar.timeText = timeElapsedString + " played / " + currentSound.trackPlayLength + " total"

}
					
function playTrack() {
	if (playheadPosition <= -1 || playheadPosition > currentSound.trackSeconds) {
			playheadPosition = 0;
	}
	st("library_soundControl starting playback at " + playheadPosition);
	currentSound.soundObj.start(playheadPosition);
	playStatus = 2;
	sendEventToModules(getCurrentModules(), EVENT_SOUNDCONTROL_PLAYED, "User has triggered playback");
	soundComplete = false;
	playID = setInterval( updateTrackStatus, 500 );
}

function pauseTrack() {
	playheadPosition = currentSound.soundObj.position /1000;
	st("library_soundControl paused the track at " + playheadPosition);
	currentSound.soundObj.stop();
	if (! (currentSound.soundObj.duration > 0) ) {
		playheadPosition = -1;
		playStatus = 0;
	} else {
		playStatus = 1;
	}
	sendEventToModules(getCurrentModules(), EVENT_SOUNDCONTROL_PAUSED, "User has paused the sound");
	updateTrackStatus();
	clearInterval(playID)
}


function stopTrack() {
	st("library_soundControl stopped the track.");
	playStatus = 0;
	sendEventToModules(getCurrentModules(), EVENT_SOUNDCONTROL_STOPPED, "User has stopped the sound");
	playheadPosition = 0;
	currentSound.soundObj.stop();
	currentSound.soundObj.start(playheadPosition);
	currentSound.soundObj.stop();
	playPause.gotoAndStop(3);
	updateTrackStatus();
	clearInterval(playID)
}

function rewindTrack() {
	playheadPosition = 0;
	if (playStatus == 2) {
		playTrack();
	} else {
		playStatus = 0;
		sendEventToModules(getCurrentModules(), EVENT_SOUNDCONTROL_STOPPED, "User has stopped the sound");
	}
	updateTrackStatus();
	clearInterval(playID)
}

function loadSound() {
		// load the sound
		soundComplete = false;
		currentSound.soundObj = null;
		currentSound.soundObj = new Sound();
		currentSound.soundObj.onSoundComplete = soundIsComplete;
	

		// take action based on loadingAction
		switch (loadingAction) {
			case "stream":
					currentSound.soundObj.loadSound(currentSound.trackURL, true);
					playTrack();
					break;
			case "preloadThenPlay":
					currentSound.soundObj.loadSound(currentSound.trackURL, false);
					currentSound.onLoad = playTrack();
					break;
			case "preloadAndStop":
					currentSound.soundObj.loadSound(currentSound.trackURL, false);
					currentSound.soundObj.stop();
					break;
			default:
					playTrack();
					break;
		}
		
				
		// calculate actual play length in seconds
		var trackSeconds = currentSound.trackPlayLength;
		var colonLocation = trackSeconds.indexOf(":");
		var min = trackSeconds.slice(0,colonLocation);
		var sec = trackSeconds.slice(colonLocation+1,trackSeconds.length);
		min = min *1;
		sec = sec *1;
		currentSound.trackSeconds = (min*60)  + sec;
		
		// set trackName for mouseover
		progressBar.trackName = currentSound.trackName;
		
		// enable/disable controls.
		rewind._visible = currentSound.trackControls.rewind;
		playPause._visible = currentSound.trackControls.playPause;
		stopControl._visible = currentSound.trackControls.stopSound;
		mute._visible = currentSound.trackControls.mute;
			
			
}

function soundIsComplete() {
		soundComplete = true;
		currentSound.trackDoneAction();
		sendEventToModules(getCurrentModules(), EVENT_SOUNDCONTROL_FINISHEDPLAYING, "The track finished playing, onSoundComplete has been triggered.");
		playStatus = 0;
		currentSound.soundObj.stop();
		playPause.gotoAndStop(3);


}


function existsAndValid(obj) {
	if (obj == null || obj == "" || typeof(obj) == "undefined" ) {
		return false;
	} else {
		return true;
	}
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////// STUFF FROM SSKOCZEN'S SITE BELOW. DOES NOTHING FOR I4. I'M TOO LAZY TO DELETE IT JUST YET. ///////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





/*

// mp3Runtime code
// variables to be used
var xmlFileName;
var tracksXML = new XML();
var albumArray = new Array;
var allTracksArray = new Array;
var albumKeyForTracksArray = new Array;
var totalTracks;
var randomPlayOrder;
var repeatTrack;
var playing;

var prevTrackNum;
var currentTrackNum; 
var nextTrackNum;
var playheadPosition;
var trackIsDone;
var nextTrackSeconds;
var totalTrackSeconds;
var musicVolume;
var pathToMusic = "../Resources";
//var pathToMusic = "http://www.quantumimagery.com/_sews/v5/music/";
var percentLoaded;

var currentSound.soundObj = new Sound();
var nextTrackSound = new Sound();
currentSound.soundObj.onSoundComplete = gotoNextTrack;
nextTrackSound.onSoundComplete = gotoNextTrack;

// functions to call:
//updateTimeAndBar("1:23", 64);
//setTrackInfo("Toad The Wet Sprocket", "Coil", "Amnesia", "5:04");


function initialize () {
	// called when mp3Player (_parent) loads.
	// variables to be used
	xmlFileName = "xml/musicInfo.xml";
	tracksXML = new XML();
	tracksXML.onLoad = doneLoadingXML;
	tracksXML.ignoreWhite = true;
	tracksXML.load(xmlFileName);
	
	totalTracks = 0;
	randomPlayOrder = false;
	repeatTrack = false;
	
	prevTrackNum = -1;
	currentTrackNum = 0;
	nextTrackNum = -1;
	playheadPosition = 0;
	trackIsDone = false;
	playing = false;
	musicVolume = 100;
	
}

function gotoNextTrack () {
	currentTrackNum = nextTrackNum;
	setTrackNums();
	updateSoundObjects ();
	updateTrackInfo (currentTrackNum)
	
}

function gotoPrevTrack () {
	currentTrackNum = prevTrackNum;
	setTrackNums();
	//currentSound.soundObj = prevTrackSound;
	updateSoundObjects ();
	updateTrackInfo (currentTrackNum)	
}

function gotoTrackNum (number) {

	currentTrackNum = number;
	if (!playing) {
		playing = true;
		_parent.pausePlayClip.playPauseGraphics.gotoAndStop("pause_off");
	}

	playheadPosition =0;
	setTrackNums();
	//playTheSound();
	updateTrackInfo (currentTrackNum)
	updateSoundObjects();
	
}

function togglePlayPause () {
	if ( playing ) {
		playing = false; 
		pauseTheSound();
	} else {
		playing = true;
		playTheSound();
	}
	
	
}

function pauseTheSound () {
	playheadPosition = currentSound.soundObj.position /1000;
	superTrace("paused the music at " + playheadPosition);
	currentSound.soundObj.stop();
	if (! (currentSound.soundObj.duration > 0) ) {
		playheadPosition = -1;	
	}
}

function playTheSound () {
	
	superTrace("started the music at " + playheadPosition);
	
	//if (playheadPosition > 0 || playheadPosition <= -1) {
		//currentSound.soundObj.setVolume(musicVolume);
		//superTrace("current volume =  " + currentSound.soundObj.getVolume());
		if (playheadPosition <= -1) {
			playheadPosition = 0;
		}
		currentSound.soundObj.start(playheadPosition);
	/*} else {
		updateSoundObjects();
		//currentSound.soundObj.start();
	}//
}

function updateSoundObjects () {

		superTrace("hitting playing test in updateSoundObjects. playing var = " + playing);		
		if (playing == false) {
			//superTrace("setting playheadPosition = -1");
			playheadPosition = -1;
		} else {
			playheadPosition = 0;
		}
		currentSound.soundObj.stop();
		var tempXML = new XML (allTracksArray[currentTrackNum]);
		var nextURL = tempXML.firstChild.attributes.fileName;
		if (nextURL.slice(0,5) != "http:") {
			nextURL = pathToMusic + nextURL
		}
		nextTrackSeconds = tempXML.firstChild.attributes.playTime;
		var colonLocation = nextTrackSeconds.indexOf(":");
		var nextMin = nextTrackSeconds.slice(0,colonLocation);
		var nextSec = nextTrackSeconds.slice(colonLocation+1,nextTrackSeconds.length);
		nextMin = nextMin *1;
		nextSec = nextSec *1;
		totalTrackSeconds = (nextMin*60)  + nextSec;
		superTrace("loading current track, file:" + nextURL);
		currentSound.soundObj = null;
		currentSound.soundObj = new Sound();
		currentSound.soundObj.onSoundComplete = gotoNextTrack;
		currentSound.soundObj.loadSound(nextURL, true);
		superTrace("just after loadSound, playheadPosition = " + playheadPosition);   
	
	if (playing ) {
		currentSound.soundObj.start(playheadPosition);
	}
	
	
	/*
	// Removed all next track caching, since the browser caches a truncated file if it's not completely preloaded.
	
	
	// Code to preload the next track - unused, but hopefully it caches..
	var tempXML = new XML (allTracksArray[nextTrackNum]);
	var nextURL = pathToMusic + tempXML.firstChild.attributes.fileName;
	nextTrackSeconds = tempXML.firstChild.attributes.playTime;
	var colonLocation = nextTrackSeconds.indexOf(":");
	var nextMin = nextTrackSeconds.slice(0,colonLocation);
	var nextSec = nextTrackSeconds.slice(colonLocation+1,nextTrackSeconds.length);
	nextMin = nextMin *1;
	nextSec = nextSec *1;
	nextTrackSeconds = (nextMin*60)  + nextSec;
	superTrace("preloading next track, file:" + nextURL);
	nextTrackSound = null;
	nextTrackSound = new Sound;
	nextTrackSound.onSoundComplete = gotoNextTrack;
	nextTrackSound.loadSound(nextURL, true);
	nextTrackSound.setVolume(0);
	nextTrackSound.stop();
	
	*/
	/*
	
	tempXML = new XML (allTracksArray[nextTrackNum]);
	nextURL = pathToMusic + tempXML.firstChild.attributes.fileName;
	superTrace("preloading next track, file:" + nextURL);
	emptyJpgClip.loadMovie(nextURL);
	
	//
}

/*   from old system, because flash can't stop a sound an keep streaming it (because it sucks!)

function updateToCurrentTrack () {
// backup in case macromedia fixes their player
	//currentSound.soundObj.stop();
	playheadPosition = 0;

	var tempXML = new XML (allTracksArray[currentTrackNum]);
	var nextURL = pathToMusic + tempXML.firstChild.attributes.fileName;
	nextTrackSeconds = tempXML.firstChild.attributes.playTime;
	var colonLocation = nextTrackSeconds.indexOf(":");
	var nextMin = nextTrackSeconds.slice(0,colonLocation);
	var nextSec = nextTrackSeconds.slice(colonLocation+1,nextTrackSeconds.length);
	nextMin = nextMin *1;
	nextSec = nextSec *1;
	totalTrackSeconds = (nextMin*60)  + nextSec;
	superTrace("loading current track, file:" + nextURL);
	currentSound.soundObj = null;
	currentSound.soundObj = new Sound;
	currentSound.soundObj.onSoundComplete = gotoNextTrack;
	currentSound.soundObj.loadSound(nextURL, true);

	
	superTrace("hitting playing test. playing var = " + playing);
	if (!playing) {
		currentSound.soundObj.stop();
		//currentSound.soundObj.setVolume(0);
		//superTrace("current volume =  " + currentSound.soundObj.getVolume());
	} else {
		currentSound.soundObj.start(playheadPosition);
	}
	
	/*
	// Code to preload the next track - impossible with MX
	var tempXML = new XML (allTracksArray[nextTrackNum]);
	var nextURL = pathToMusic + tempXML.firstChild.attributes.fileName;
	nextTrackSeconds = tempXML.firstChild.attributes.playTime;
	var colonLocation = nextTrackSeconds.indexOf(":");
	var nextMin = nextTrackSeconds.slice(0,colonLocation);
	var nextSec = nextTrackSeconds.slice(colonLocation+1,nextTrackSeconds.length);
	nextMin = nextMin *1;
	nextSec = nextSec *1;
	nextTrackSeconds = (nextMin*60)  + nextSec;
	superTrace("preloading next track, file:" + nextURL);
	nextTrackSound = null;
	nextTrackSound = new Sound;
	nextTrackSound.onSoundComplete = gotoNextTrack;
	nextTrackSound.loadSound(nextURL, false);
	nextTrackSound.stop();

}


/*   from old system off sskoczen's site,  gutted because flash can't stop a sound and keep streaming it (because it sucks!)
function updateToCurrentTrack () {
// leave in in case macromedia fixes their player
	//currentSound.soundObj.stop();
	playheadPosition = 0;

	var tempXML = new XML (allTracksArray[currentTrackNum]);
	var nextURL = pathToMusic + tempXML.firstChild.attributes.fileName;
	nextTrackSeconds = tempXML.firstChild.attributes.playTime;
	var colonLocation = nextTrackSeconds.indexOf(":");
	var nextMin = nextTrackSeconds.slice(0,colonLocation);
	var nextSec = nextTrackSeconds.slice(colonLocation+1,nextTrackSeconds.length);
	nextMin = nextMin *1;
	nextSec = nextSec *1;
	totalTrackSeconds = (nextMin*60)  + nextSec;
	superTrace("loading current track, file:" + nextURL);
	currentSound.soundObj = null;
	currentSound.soundObj = new Sound;
	currentSound.soundObj.onSoundComplete = gotoNextTrack;
	currentSound.soundObj.loadSound(nextURL, true);

	
	superTrace("hitting playing test. playing var = " + playing);
	if (!playing) {
		currentSound.soundObj.stop();
		//currentSound.soundObj.setVolume(0);
		//superTrace("current volume =  " + currentSound.soundObj.getVolume());
	} else {
		currentSound.soundObj.start(playheadPosition);
	}
	
	/*
	// Code to preload the next track - impossible with MX
	var tempXML = new XML (allTracksArray[nextTrackNum]);
	var nextURL = pathToMusic + tempXML.firstChild.attributes.fileName;
	nextTrackSeconds = tempXML.firstChild.attributes.playTime;
	var colonLocation = nextTrackSeconds.indexOf(":");
	var nextMin = nextTrackSeconds.slice(0,colonLocation);
	var nextSec = nextTrackSeconds.slice(colonLocation+1,nextTrackSeconds.length);
	nextMin = nextMin *1;
	nextSec = nextSec *1;
	nextTrackSeconds = (nextMin*60)  + nextSec;
	superTrace("preloading next track, file:" + nextURL);
	nextTrackSound = null;
	nextTrackSound = new Sound;
	nextTrackSound.onSoundComplete = gotoNextTrack;
	nextTrackSound.loadSound(nextURL, false);
	nextTrackSound.stop();

}
function updateTrackInfo (trackNum) {
	
 	var tempAlbumXML = new XML (albumArray[trackNum]);
	var tempTracksXML = new XML(allTracksArray[trackNum]);
	tempAlbumXML = tempAlbumXML.firstChild;
	tempTracksXML = tempTracksXML.firstChild;
	
	//superTraceNodeInfo(tempAlbumXML);
	//superTraceNodeInfo(tempTracksXML);
	
	var artist = tempAlbumXML.attributes.artist;
	var album = tempAlbumXML.attributes.name;
	var name = tempTracksXML.attributes.name;
	var playTime = tempTracksXML.attributes.playTime;
	
	_parent.setTrackInfo(artist, album, name, playTime);

}

function updateTrackProgress () {
	// update seconds elapsed.
	
		//playheadPosition = currentSound.soundObj.position;
		totalSecondsElapsed = currentSound.soundObj.position / 1000;
		minutesElapsed = Math.floor(totalSecondsElapsed / 60);
		secondsElapsed = Math.round(totalSecondsElapsed % 60);
		if (secondsElapsed < 10) {
			secondsElapsed = "0" + secondsElapsed;
		}
	
		elapsedString = minutesElapsed + ":" + secondsElapsed;
		percentElapsed = (totalSecondsElapsed / totalTrackSeconds) * 100;

		trackDurationLoaded = currentSound.soundObj.duration;
		totalSecondsLoaded = trackDurationLoaded / 1000;
		percentLoaded = (totalSecondsLoaded / totalTrackSeconds) * 100;
		
		_parent.updateTimeAndBar(elapsedString, percentElapsed, percentLoaded);
		
		//playheadPosition = playheadPosition / 1000;
		
		

}


function superTraceTrackInfo () {

	superTrace("//-------  Track Info -------\\\\");
	superTrace("  randomPlayOrder = " + randomPlayOrder);
	superTrace("  repeatTrack = " + repeatTrack);
	superTrace("  prevTrackNum = " + prevTrackNum);
	superTrace("  currentTrackNum = " + currentTrackNum);
	superTrace("  nextTrackNum = " + nextTrackNum);
	superTrace("  playheadPosition = " + playheadPosition);
	superTrace("  trackIsDone = " + trackIsDone);
	superTrace("\\\\-----  End Track Info -----//");

}

function superTraceNodeInfo ( node ) {
	superTrace("node.status = " + node.status);
	superTrace("node.hasChildNodes() = " + node.hasChildNodes());
	superTrace("node.nodeType = " + node.nodeType);
	superTrace("node.nodeName = " + node.nodeName);
	superTrace("node.nodeValue = " + node.nodeValue);
	superTrace("node.attributes.name = " + node.attributes.name);
	superTrace("node.childNodes = " + node.childNodes);
	superTrace("node.childNodes.length = " + node.childNodes.length);
	superTrace("node.toString = " + node.toString());
	

}


//*/