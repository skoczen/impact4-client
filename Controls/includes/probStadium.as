function eventHandler(event, text)
{
	switch(event)
	{
		case EVENT_MODULE_INITALIZE:
			initialize();
			break;
		case EVENT_MODULE_FINALIZE:
			finalize();
			break;
		case EVENT_NAVIGATION_ADVANCEFAILED:
			trace(this.myName + " finalize failed on me " + text);
			userActions.currentState = 3;
			break;
	}
}



// values gathered manually from making a grid and using equal spacing.
var xOffset = faceClip_0._width;
var yOffset = faceClip_0._height;

// arrays and other important variables
var facesArray = new Array(100);

for (j=1; j<=100; j++) {
	facesArray[j] = 1;
	aliveArray[j] = j;

}

// vars used in the "press and hold" action
var minHoldDelay = 500; // milliseconds
var holdIncrementTime = 300; // milliseconds
var clickSpeed = 1;
var holdSpeed = 5; // speed that the faces appear/ disappear on a click or hold
var plus = false;
var minus = false;
var riskChanged = false;
var holding = false;

var finalizeableNow=false;// used to finalize if loading a previous value.

// vars for probability
var riskTotalSize; 		// total number in the crowd (i.e. 10,000)
var riskNumAffected;		// the number currently affected (i.e. 15)

var riskProbability;		// riskNumAffected/riskTotalSize.
var minRiskProb;			// minimum risk amount (absolute 0to1).  (i.e. 0.001)
var maxRiskProb;			// maximum risk amount (absolute 0to1).  (i.e. 0.5 = 50%)
var finalProb;				// finalProbability to save (absolute float, between 0 and 1)

var textMoreRisk;				// text to go by the plus button
var textLessRisk;				// text to go by the minus button
var questionText;			// text to go in the question space
var tintColor;				// color of the tint
var numIncrements;		// number of increments? or use log scale?
var stadiumSweep=false; // are we in the middle of a sweep?
var numFramesShown = 0; // how many frames in the sweep
var globalFacesArr = new Array(); // An array to track which faces we're showing where.
var globalFacesShown = 0;// How many faces we've shown.

var binocMaskOffsetX = maskCenter._x - binoculars._x;
var binocMaskOffsetY = maskCenter._y - binoculars._y;
var binocFace0OffsetX = faceClip_0._x - binoculars._x;
var binocFace0OffsetY = faceClip_0._y - binoculars._y;



function initialize() {

		
// The following parameters are are passed in by impact4:
//	riskTotalSize; 		// total number in the crowd (i.e. 10,000)
	riskTotalSize = getValue("riskTotalSize");
	if (riskTotalSize == "" || riskTotalSize == null || isNaN(riskTotalSize))
		riskTotalSize = 10000;
//	riskNumAffected;		// the number currently affected (i.e. 15)
	riskNumAffected = getValue("riskNumAffected");
	if (riskNumAffected == "" || riskNumAffected == null || isNaN(riskNumAffected))
		riskNumAffected = 0;

//	minRiskProb;			// minimum risk amount (absolute 0to1).  (i.e. 0.001)
	minRiskProb = getValue("minRiskProb");
	if (minRiskProb == "" || minRiskProb == null || isNaN(minRiskProb))
		minRiskProb = 0.0001;
//	maxRiskProb;			// maximum risk amount (absolute 0to1).  (i.e. 0.5 = 50%)
	maxRiskProb = getValue("maxRiskProb");
	if (maxRiskProb == "" || maxRiskProb == null || isNaN(maxRiskProb))
		maxRiskProb = 0.5;
		
//	finalProb;				// finalProbability to save (absolute float, between 0 and 1)
	finalProb = getValue("finalProb");
	if (finalProb == "" || finalProb == null || isNaN(finalProb)) {
		finalProb = null;		
		riskProbability = riskNumAffected/riskTotalSize;
		finalizeableNow = false;
	} else {
		finalizeableNow = true;
		riskProbability = finalProb;
		riskNumAffected = Math.round(riskProbability * riskTotalSize);
	}

//	textMoreRisk;				// text to go by the plus button
	textMoreRisk = getValue("textMoreRisk");
	if (textMoreRisk == "" || textMoreRisk == null) 
		textMoreRisk = "More Risk";		
	
//	textLessRisk;				// text to go by the minus button
	textLessRisk = getValue("textLessRisk");
	if (textLessRisk == "" || textLessRisk == null) 
		textLessRisk = "Less Risk";
			
//	questionText;			// text to go in the question space
	questionText = getValue("questionText");
	if (questionText == "" || questionText == null)
		questionText = "Please indicate the amount of risk you would be willing to take.";

//	numIncrements;			// number of increments
	numIncrements = getValue("numIncrements");
	if (numIncrements == "" || numIncrements == null || isNaN(numIncrements))
		numIncrements = 50;

// figure out the increment (in terms of people), set the click and holdSpeeds.
	totalPeopleVariance = ((riskTotalSize * maxRiskProb) - (riskTotalSize * minRiskProb));
	incrementAmount = Math.round( totalPeopleVariance / numIncrements);
	clickSpeed = incrementAmount;
	holdSpeed = incrementAmount*5;

// check the scale
	if (this.scale == "" || this.scale == null || isNaN(this.scale) ) {
		this.scale = 1;
	} else {
		this.scale = this.scale/100;
		stadium.fillMouseArea._xscale = 100* (1/this.scale);
		stadium.fillMouseArea._yscale = 100* (1/this.scale);
	}

// check to see if we're in tool mode or graphic mode
	moduleMode = getValue("mode");
	if (moduleMode == "" || moduleMode == null) 
		moduleMode = "tool";		
	
	if (moduleMode == 'graphic') {
		questionText = '';
		textLessRisk = '';
		textMoreRisk = '';
		plusButton._visible = false;
		minusButton._visible = false;
		instructionText.text = "Move the binoculars to see a closer view.";
		instructionText._y = instructionText._y - 10;
		instructionText._x = instructionText._x - 130;
		finalizeableNow = true;
	} else {
		instructionText.text = "Use the + and - buttons to change the amount of risk. Move the binoculars to see a closer view.";
	}


	stadium.crowdAffected._alpha = 0;

	
	// duplicate faces
	for (j=0; j<10; j++)
	{
		for (k=1; k<=10; k++)
		{
			currentNum = (j*10) + k;
				tempObj = "faceClip_" + currentNum;
				faceClip_0.duplicateMovieClip(tempObj,allocNewLevel());	
				tempObj = eval(tempObj);
				maskObj = "mask_" + currentNum;
				maskCenter.duplicateMovieClip(maskObj,allocNewLevel());
				maskObj= eval(maskObj);
				tempObj.setMask(maskObj);
				tempObj._x +=  (k-1)* xOffset;
				tempObj._y += j * yOffset;
		}
	}
	faceClip_0._visible = false;
	maskCenter._visible = false;

	// run condition set functions
	binocularMove();
	updateProportionsText();
	
	
	this.onEnterFrame = enterFrameActions;
	startSweep();
}


tempLevel = 1000;


function allocNewLevel() {
	tempLevel++;
	return tempLevel;
}

function startSweep (){
	if (stadiumSweep == false) {
		gotoAndPlay("resetLoopStart");		
	} else {
		play();
	}
	stadiumSweep = true;
	numFramesShown = 0;
	this.onMouseMove = null;
}

function endSweep () {
	binocularMove();
	this.stop();
	stadiumSweep = false;
	this.onMouseMove = binocularMove;
}

function enterFrameActions () {
		if (stadiumSweep==true) {
			binocularMove();
			numFramesShown++;
		}
		if (this.plus || this.minus) {
			this.pressActions();		
		}
}

function binocularMove () {
		// if the mouse is over the fill area.
		if (stadium.fillMouseArea.hitTest(this._xmouse+this._x, this._ymouse+this._y, true) || stadiumSweep) {
			
			// move the binoculars clip
			if (!stadiumSweep) {
				newX = Math.floor(this._xmouse);
				newY = Math.floor(this._ymouse);				

				binoculars._x = newX;
				binoculars._y = newY;	
			}

			binocX = binoculars._x;
			binocY = binoculars._y;

			// move all the faces and masks. ouch.
			currentNum = 0;
			for (j=0; j<10; j++)
			{
				for (k=1; k<=10; k++)
				{
					currentNum++;
					tempObj = "faceClip_" + currentNum;
					tempObj = eval(tempObj);
					tempObj._x = binocX + binocFace0OffsetX + ((k-1)* xOffset);
					tempObj._y = binocY + binocFace0OffsetY + (j * yOffset);
					tempObj = "mask_" + currentNum;
					tempObj = eval(tempObj);
					tempObj._x = binocX + binocMaskOffsetX;
					tempObj._y = binocY + binocMaskOffsetY;
				}
			}
					
			// randomize the faces
			randomizeFaces(Math.floor(binocX), Math.floor(binocY));

			// update the faces		
			updateFaces();

		}
	}


function finalize () {
	if (moduleMode != 'graphic') {
		finalProb = riskProbability;
		setValue ("finalProb", finalProb);		
	}

}

function plusOrMinusPressed( plusOrMinus ) {
	if (plusOrMinus == "plus") {
		plus = true;
	} else {
		minus = true;
	}
	pressTimerStart = getTimer();
	lastHoldAdjustTime = pressTimerStart;
}


function plusOrMinusReleased( plusOrMinus ) {
	finalizeNow = false;
	if ( riskChanged == false ) {
		clickNow = true;
		pressActions();
	} else {
		riskChanged = false;
	}

	if (plusOrMinus == "plus") {
		plus = false;
	} else {
		minus = false;
	}
	holding = false;
}

function pressActions() {
	oldRiskNumAffected = riskNumAffected;
	now = getTimer();
	// exponential adjusts
	if (plus == true) {
		midAdjust = (tempClickSpeed/2);
	} else {
		midAdjust = -1*(tempClickSpeed/2);
	}
	tempClickSpeed = clickSpeed * (40*(riskNumAffected+midAdjust)/totalPeopleVariance);
	if (tempClickSpeed>clickSpeed) {
		tempClickSpeed = clickSpeed;
	}


	tempClickSpeed = Math.floor(tempClickSpeed);
	if (tempClickSpeed < 2) {
		tempClickSpeed = 1;
	}
		
	if (clickNow == true) {
		// adjust up or down at normal speed
		if (plus == true) {
			riskNumAffected += tempClickSpeed;
		} else {
			riskNumAffected -= tempClickSpeed;
		}
		// do rounding
		if (riskNumAffected > (minRiskProb*riskTotalSize) ) {
			riskNumAffected = Math.round(riskNumAffected / tempClickSpeed )*tempClickSpeed;
		}
		clickNow = false;
	} else {
		if (  ( (now - lastHoldAdjustTime > minHoldDelay) && holding == false) || ( holding == true && ( now - lastHoldAdjustTime > holdIncrementTime) ) ) {
			// adjust up or down at hold speed
			//trace("holdAdjust Code Called, plus=" + plus + ",minus=" + minus);
			holding = true;
			if (plus == true) {
				riskNumAffected += holdSpeed;
			} else {
				riskNumAffected -= holdSpeed;
			}
			riskChanged = true;

			lastHoldAdjustTime = getTimer();
		}
	}

	// check boundraies
	if (riskNumAffected < (minRiskProb*riskTotalSize)) {
		riskNumAffected = (minRiskProb*riskTotalSize);
	}

	if (riskNumAffected > (maxRiskProb*riskTotalSize)) {
		riskNumAffected = (maxRiskProb*riskTotalSize);
	}
	riskNumAffected = Math.round(riskNumAffected);

	updateRiskChanged();
	updateFaces();
	updateProportionsText();
	startSweep();
}

var pixelBlockSize = 20;
function randomizeFaces (xCoord, yCoord) {
	
	// This function *now* needs to do a couple of things:
	// Track which faces have been shown, and where
	// Show the same set again if we have a record
	facesArray = new Array();

	// If there's a new risk, reset the list.	
	if (riskChanged) {
		globalFacesArr = new Array();
		globalFacesArr[0] = new Array();
		globalFacesShown = 0;
	}
	
	// round off the coords to sets of 5? 10?
	xCoord = (Math.floor(xCoord / pixelBlockSize)*pixelBlockSize);
	yCoord = (Math.floor(yCoord / pixelBlockSize)*pixelBlockSize);

	if (globalFacesArr[xCoord][yCoord] !== undefined) {
		facesArray = globalFacesArr[xCoord][yCoord];
	} else {
		numMatchesThisSet = 0;
		for (j=1; j<=100; j++){
			if (globalFacesShown >= riskNumAffected || Math.random()  > riskProbability ) {
				facesArray[j] = 1;
			} else {
				facesArray[j] = 0;
				globalFacesShown++;
				numMatchesThisSet ++;
			}
		}	
		if (globalFacesArr[xCoord] == undefined) {
			globalFacesArr[xCoord] = new Array();
		}	
		globalFacesArr[xCoord][yCoord] = facesArray;

	} 
}


function updateFaces () {

	for (j=1; j<=100; j++) {
		var tempObj = "faceClip_" + j;
		tempObj = eval(tempObj);
		if (facesArray[j] == 1) {
			tempObj.gotoAndStop("alive");
		} else {
			tempObj.gotoAndStop("dead");
		}
	}
	stadium.crowdAffected._alpha = riskProbability*200;

}

function updateRiskChanged () {
	
	riskProbability = riskNumAffected / riskTotalSize;
	oldRiskOfDeath = riskOfDeath;
	riskOfDeath = Math.round(riskProbability * 100);
	maxAttempts = 500;
	numAttempts = 0;

	if (riskOfDeath >= oldRiskOfDeath) {
		// need to change difference 1s to 0s
			numToChange = riskOfDeath - oldRiskOfDeath;
			while (numToChange > 0 && numAttempts<maxAttempts) {
				tryThisNum = Math.round(Math.random() * 99) +1;
				if (facesArray[tryThisNum] == 1) {
					facesArray[tryThisNum] = 0;
					numToChange--;
				}
				numAttempts++;
			}

	} else {
		// need to change x 0s to 1s.
			numToChange = oldRiskOfDeath - riskOfDeath;
			while (numToChange > 0 && numAttempts<maxAttempts) {
				tryThisNum = Math.round(Math.random() * 99) +1;
				if (facesArray[tryThisNum] == 0) {
					facesArray[tryThisNum] = 1;
					numToChange--;
				}
				numAttempts++;
			}

	}

	this.selfFinalizable();
}

function updateProportionsText () {
	percentText = Math.round(riskProbability * 100 * riskTotalSize) / riskTotalSize;
	probabilityText = riskNumAffected + " out of " + riskTotalSize + " chance.  (" + percentText + "%)";
}