/* Interface -- Visual interface system hooks, etc
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: interface.as,v 1.9 2003/10/22 06:05:33 sskoczen Exp $
 */ 

fscommand ("fullscreen","true");
stop();

element_ProgressBar.updateBar(0);

// called when next is clicked
function clickNext () {
	showHideMenu();
	sendEventToModules("navigation", EVENT_NAVIGATION_ATTEMPTFORWARD, "Next Clicked");
	//_setValue("runtime.nextClicked", true);
	//_parent.navigation.gotoAndPlay("processNavigation");
	//nextFrame();
	
}

// called when back is clicked
function clickBack () {
	showHideMenu();
	sendEventToModules("navigation", EVENT_NAVIGATION_ATTEMPTBACK, "Back Clicked");
	//_setValue("runtime.backClicked", true);
	//_parent.navigation.gotoAndPlay("processNavigation");
	//prevFrame();
	
}

// toggles a menu drawer to come or go
function showHideMenu ( clipName ) {
	//st("showing/hiding drawer " + clipName);
	if (drawerHelp._currentframe != 1) 
		drawerHelp.play();

	if (drawerReview._currentframe != 1) 
		drawerReview.play();
		
	if (drawerContact._currentframe != 1) 
		drawerContact.play();
		
	if (drawerExit._currentframe != 1) 
		drawerExit.play();
		
	var tempDrawer = clipName;
	tempDrawer.play();
	
}

// sets the interface section text
function setCurrentSection(newString) {
	this.currentSectionText = newString;
}

// sets the interface title
function setSurveyTitle (newString ) {
	this.surveyTitleText = newString; 
}

// load the load -- NOTE: unused
function loadLogo () {
	// load a static swf filename, that's been created by generator to include the logo.
	loadMovie("logo.swf",elementLogoClip);
}

// enables or disables a element on the interface	
function setElementStatus (elementName, booleanStatus) {
	// True is enabled
	// False is disabled.
	tempObj = elementName;
	if (booleanStatus) {
		tempObj.gotoAndStop("enabled");
	} else {
		tempObj.gotoAndStop("disabled");
	}
}	

// This function sets the shell color to either a rgb set, or a color object.
// if both are specified, the color object is used.
function setShellColor (red,green,blue,colorObject) {
	
	//TODO: Create global convertRGBtoColorObject function.

	
	var colorObjectShell = new Color(elementShellface);

	if (colorObject != "" && colorObject != null) 
	{
		// if the color object is passed
		colorObjectShell.setTransform( temp_convertRGBToColorObject(colorObject) );
	} else {
		// otherwise, use the RGB values, if present
		if (red != "" && red != null && green != "" && green != null && blue != "" && blue != null) {
			colorObjectShell.setTransform(temp_convertRGBToColorObject(red,green,blue)); 
		}  
	}

}
	
// sets the background color	
function setBackgroundColor (red,green,blue,colorObject) {
	// TODO: Verify that MX still doesn't support runtime stage coloring. 
	
	var colorObjectBackground = new Color(elementBackground);

	if (colorObject != "" && colorObject != null) {
		// if the color object is passed
		colorObjectBackground.setTransform(temp_convertRGBToColorObject(colorObject));
	} else {
		// otherwise, use the RGB values, if present
		if (red != "" && red != null && green != "" && green != null && blue != "" && blue != null) {
			colorObjectBackground.setTransform(temp_convertRGBToColorObject(red,green,blue)); 
		}
	}
	
}

// holder function for rgb to color object conversation
function temp_convertRGBToColorObject(red, green, blue, alpha) {
	var tempColorObj = new Object();
	tempColorObj.ra = red;
	tempColorObj.rb = 255;
	tempColorObj.ga = green;
	tempColorObj.gb = 255;	
	tempColorObj.ba = blue;
	tempColorObj.bb = 255;
	if (alpha != "" && alpha != null) {
		tempColorObj.aa = alpha;
	} else {colorObjectShell.setTransform( temp_convertRGBToColorObject(red,green,blue) ); colorObjectShell.setTransform( temp_convertRGBToColorObject(red,green,blue) ); 
		tempColorObj.aa = 100;
	}
	tempColorObj.ab = 255;
 
	return tempColorObj;

}

var maxButtons = 8;

// shows a dialog box, with functionToCall as callback
_global.showDialogMessage = function (messageText, arrayOfOptions, functionToCall) {
//	st("messageText = " + messageText + " arrayOfOptions = " + arrayOfOptions + " functionToCall = " + functionToCall);
	

	dialogBox.gotoAndStop("show");
	// can not get htis line of code to work after 1st instance.
	dialogBox.dialogBoxAndText.dialogButtonOrig._visible = false;
	// remove dup'd clips


	for (j=0; j<=maxButtons; j++) {
		tempObj = "dialogBox.dialogBoxAndText.dialogButton" + j;
		tempObj = eval(tempObj);
		if (typeof (tempObj) == "movieclip" ) {
			removeMovieClip(tempObj);
			tempObj._y -= 2000;
		}
	}

		
	// set variables
	startDialogHeight = dialogBox.dialogBoxAndText.dialogText._height;
	startDialogY = dialogBox.dialogBoxAndText.dialogBox._y;
	startTextSize = dialogBox.dialogBoxAndText.dialogButtonOrig.buttonText.textWidth;
	
	startingBtnX = dialogBox.dialogBoxAndText.dialogButtonOrig._x;
	startingBtnY = dialogBox.dialogBoxAndText.dialogButtonOrig._y;
	totalButtonWidth = 0;
	buttonSpacing = 10;
	halfSpace = buttonSpacing /2;
	currentButtonPos = startingBtnY;
	
	
	// set dialog box size.
	dialogBox.dialogBoxAndText.dialogText.autosize = "right";
	dialogBox.dialogBoxAndText.dialogText.text = messageText;
	newDialogHeight = dialogBox.dialogBoxAndText.dialogText._height;
	difference = newDialogHeight - startDialogHeight;
	dialogBox.dialogBoxAndText.dialogButtonOrig._y = startingBtnY + difference;
	dialogBox.dialogBoxAndText.dialogBox._y = startDialogY + difference;
	
	// loop and duplicate clips, set text, and set button width
	for (j=0; j < arrayOfOptions.length; j++) {
		tempObj = "dialogBox.dialogBoxAndText.dialogButton" + j;
		//st("tempObj = " + tempObj);
		//st("dialogBox.dialogBoxAndText.dialogButtonOrig = " + dialogBox.dialogBoxAndText.dialogButtonOrig);
		dialogBox.dialogBoxAndText.dialogButtonOrig.duplicateMovieClip("dialogButton" + j,allocNewLevel());
		tempObj = eval(tempObj);	
		
		tempObj.textValue = arrayOfOptions[j];
		tempObj.buttonText.autosize = "center";
		tempObj.buttonText.text = tempObj.textValue;
		tempObj.buttonNum = j;
		tempObj.firstTextSize = startTextSize;
		tempObj.init();
		//st("functionToCall = " + functionToCall);
		tempObj.functionToCall = functionToCall;
		
		tempObj._y = startingBtnY + difference;
		sideBufferTemp = 25; // equal to side portions which aren't calculated yet at execution time.
		tempWidth = tempObj.buttonText.textWidth + sideBufferTemp;
		
			if (j==0) {
				currentButtonPos = startingBtnX - (tempWidth / 2);
			}

			tempObj._x = currentButtonPos + (tempWidth / 2);
			currentButtonPos = tempObj._x + (tempWidth / 2) + buttonSpacing;

	}
	
	
	leftAdjust = 0;
	leftAdjust = startingBtnX - ( ( (tempObj._x + (tempObj._width /2) )  - (dialogBox.dialogBoxAndText.dialogButton0._x ) ) /2 ) + sideBufferTemp;
	//st("leftAdjust = " + leftAdjust);
	
	// loop and set positions
	for (j=0; j < arrayOfOptions.length; j++) {
		tempObj = "dialogBox.dialogBoxAndText.dialogButton" + j;
		tempObj = eval(tempObj);	
		//st("tempObj = " + tempObj);
		
		tempObj._x += leftAdjust;

	}
	
	if (j > maxButtons) {
		maxButtons = j;
	}
	dialogBox.dialogBoxAndText.dialogButtonOrig._visible = false;
	dialogBox.play();
}

//  Set up progress tag listener
_global.interfaceEventHandler = function (event, passedObj)
{
	switch(event)
	{
		case EVENT_MODULE_PAINT:
			trace("Interface got a Paint.");
			doProgressUpdate(passedObj);
			break;
	}
}

function doProgressUpdate(passedObj) {

	// if it's from the update percent
	if (typeof(passedObj) == "number") {
		//trace("from calculated percent");
		updateBar(passedObj);
	} else {
		//trace("from a finished load");
		// get list of modules
		var currMods = new Array();
		currMods = getCurrentModules();
	
	
	// the below code is a temporary fix for progress bar manual sets. 
		for (var q=0; q< currMods.length; q++) {
			if ( typeof(_getValue(currMods[q] + ".percentDone"))  == "number") {
				
				updateBar( _getValue(currMods[q] + ".percentDone") );
			}
			
			if ( typeof(_getValue(currMods[q] + ".sectionText"))  == "string") {
				setCurrentSection(_getValue(currMods[q] + ".sectionText"));
			}

		}
		trace("percentDone = " + _getValue(currMods[q] + ".percentDone"));
		trace("sectionText = " + _getValue(currMods[q] + ".sectionText"));
				
		/*
		Enable this code once Composites work correctly in i4.
	
		var progressObj = -1;
		// cycle through, look for progress object
		for (var q=0; q< currMods.length; q++) {
			if ( typeof(_getValue(currMods[q] + ".progress"))  == "object") {
				progressObj = _getValue(currMods[q] + ".progress");
			}
		}
		
		// update the progress
		if (progressObj != -1) {
			if (typeof(progressObj.percentDone) == "number") {
				updateBar(progressObj.percentDone);
			}
			
			if ( typeof(progressObj.sectionText) == "string" ) {
				setCurrentSection(progressObj.sectionText);
			}
			
			if ( typeof(progressObj.surveyTitle) == "string" ) {
				setSurveyTitle(progressObj.surveyTitle);
			} 
			
		} else {
			//trace("no modules have progress objects.");
		}
		
		//*/
	
	}

	// notes: progressObj can have the following properties:
	// percentDone
	// sectionText
	// surveyTitle

}



//*/

// bootstrap the interface
function initialize (elementTooltipEnabled, elementProgressBarEnabled, elementBackArrowEnabled, elementNextArrowEnabled, elementLogoClipEnabled, elementShellFaceEnabled, elementBackgroundEnabled, progressPercent, currentSectionText, surveyTitleText, shellRed, shellGreen, shellBlue, shellColorObject, backRed, backGreen, backBlue, backColorObject) {
	//NOTE: This function initializes all values for the interface movie.	
	if (elementTooltipEnabled) {
		setElementStatus(elementTooltip, true);
	} else { 
		setElementStatus(elementTooltip, false);
	}

	if (elementProgressBarEnabled) {
		setElementStatus(elementProgressBar, true);
	} else { 
		setElementStatus(elementProgressBar, false);
	}
	
	if (elementBackArrowEnabled) {
		setElementStatus(elementBackArrow, true);
	} else { 
		setElementStatus(elementBackArrow, false);
	}
	
	if (elementNextArrowEnabled) {
		setElementStatus(elementNextArrow, true);
	} else { 
		setElementStatus(elementNextArrow, false);
	}
	
	if (elementLogoClipEnabled) {
		setElementStatus(elementLogoClip, true);
	} else { 
		setElementStatus(elementLogoClip, false);
	}
	
	if (elementShellfaceEnabled) {
		setElementStatus(elementShellface, true);
	} else { 
		setElementStatus(elementShellface, false);
	}
	
	if (elementBackgroundEnabled) {
		setElementStatus(elementBackground, true);
	} else { 
		setElementStatus(elementBackground, false);
	}

	drawerContact.contactDrawer.contactInfo.text = searchAndReplace(_getValue("configuration.contactInfo"),"\\n","\n");
	
	// run set functions
	elementProgressBar.updateBar(progressPercent);
	setCurrentSection(currentSectionText);
	setSurveyTitle(surveyTitleText);
	loadLogo();
	// note: the setShellColor makes sure the data passed is valid
	setShellColor (shellRed, shellGreen, shellBlue, shellColorObject);
	setBackgroundColor (backRed, backGreen, backBlue, backColorObject);
	
	st("interface: initialization complete.")
}

function searchAndReplace (the_string, search_string, replace_string, occurrences, backward) {
   if (search_string == replace_string) {
      return the_string;
   }
   var found = 0;
   if (backward == true) {
      var pos = the_string.lastIndexOf(search_string);
      while (pos >= 0) {
         found++;
         var start_string = the_string.substr(0, pos);
         var end_string = the_string.substr(pos + search_string.length);
         the_string = start_string + replace_string + end_string;
         pos = the_string.lastIndexOf(search_string, start_string.length);
         if (found == occurrences) {
            pos = -1;
         }
      }
   }
   else {
      var pos = the_string.indexOf(search_string);
      while (pos >= 0) {
         found++;
         var start_string = the_string.substr(0, pos);
         var end_string = the_string.substr(pos + search_string.length);
         the_string = start_string + replace_string + end_string;
         pos = the_string.indexOf(search_string, pos + replace_string.length);
         if (found == occurrences) {
            pos = -1;
         }
      }
   }
   return the_string;
}