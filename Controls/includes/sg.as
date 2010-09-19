/*
 userActions states
 0 - SG loaded, not initialized
 1 - SG loaded and initialized
 2 - User said no risk
 3 - User said no to risk, tried to advance.
 4 - User said yes to risk, on grid screen.
 5 - User has set the correct value, but not clicked next
 6 - Advance failed. User has not set the correct training value. on grid screen.
 7 - Advance success.
 8 - (added later) User tried to advance without yes/no answer.
 //*/

registerNewEvent("EVENT_SGTRAINING_USERACTION");
function trainingActions() {

	this.currentState = 0;
	this.currentState2 = 0;
	this.watch ("currentState", function(id, oldval, newval) {
		this.currentState = newval;
		currentState2 = newval;
		sendEventToModules(getCurrentModules(),EVENT_SGTRAINING_USERACTION,this);
	});


}

var userActions = new trainingActions();





wouldYouTakeAnyText = "Would you take any Risk of Death at all? ";



// values gathered manually from making a grid and using equal spacing.
var xOffset = 25.7
var yOffset = 25.8

// arrays and other important variables
var facesArray = new Array(100);
var aliveArray = new Array();
var deadArray = new Array();

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

var finalizeNow = false; // used to finalize if loading a previous value.
var forceAnswer = false;  // used if the module should for ce

// below line was so that people didn't have to choose a value (could leave it at zero).
//this.selfFinalizable();

function initialize() {
	riskOfDeath = null;
	riskOfDeath = getValue("riskOfDeath");
	trace("riskOfDeath = " + riskOfDeath);
	if (riskOfDeath != null && typeof(riskOfDeath) != "undefined" && riskOfDeath != "" && !isNaN(riskOfDeath) ) {
		gotoAndStop("sg");
		finalizeNow = true;
		this.selfFinalizable();
		userActions.currentState = 5;
	}

	userActions.currentState = 1;


}

function initialize2() {

	// set initial vars
	//riskOfDeath = getValue("riskOfDeath");
	if (finalizeNow == true) {
		this.selfFinalizable();
		userActions.currentState = 5;
	}
	updateRiskChanged();
	updateFaces();
	updateProportionsText();

	/*trace("typeof " + typeof(riskOfDeath));
	trace("tostri " + riskOfDeath.toString());
	trace("inte is Number.NaN " + (riskOfDeath == Number.NaN));
	trace("inte is NaN " + (riskOfDeath == NaN));
	trace("int is int.NaN " + (riskOfDeath == riskOfDeath.NaN));
	trace("int Nan " + riskOfDeath.NaN);*/

	option1text = getValue("option1text");
	option2text = getValue("option2text");

	topButtonLabel = getValue("topButtonLabel");
	bottomButtonLabel = getValue("bottomButtonLabel");

	forceAnswer = getValue("forceAnswer");

	buttonPrompt = getValue("buttonPrompt");



	if (typeof(riskOfDeath) == "undefined" || isNaN(riskOfDeath)) {
		riskOfDeath = 0;
		riskOfLife = 100;
	}

	if (typeof(option1text) == "undefined")
		option1text = "Are Completely Cured";

	if (typeof(option2text) == "undefined")
		option2text = "Die from the Procedure";

	if (typeof(topButtonLabel) == "undefined")
		topButtonLabel = "More Risk";

	if (typeof(bottomButtonLabel) == "undefined")
		bottomButtonLabel = "Less Risk";

	if (typeof(forceAnswer) == "undefined")
		forceAnswer = false;

	if (typeof(buttonPrompt) == "undefined")
		buttonPrompt = "Change\nRisk:";


	// set up the screen

		// duplicate faces
		for (j=0; j<10; j++)
		{
			for (k=1; k<=10; k++)
			{
				currentNum = (j*10) + k;
				if (currentNum != 1) {

					var tempObj = "faceClip_" + currentNum;

					faceClip_1.duplicateMovieClip(tempObj,allocNewLevel());
					tempObj = eval(tempObj);

					tempObj._x +=  (k-1)* xOffset;
					tempObj._y += j * yOffset;

				}
			}
		}
	// run condition set functions
	updateFaces();
	updateProportionsText();



}

function finalize () {
	if (riskOfDeath == 0) {
		for (j=0; j<10; j++)
		{
			for (k=1; k<=10; k++)
			{
				currentNum = (j*10) + k;
				if (currentNum != 1) {

					var tempObj = "faceClip_" + currentNum;
					tempObj = eval(tempObj);
					tempObj.removeMovieClip();

				}
			}
		}
		gotoAndStop("confirmNoRisk");
	} else {
		trace("riskOfDeath = " + riskOfDeath);
		setValue ("riskOfDeath", riskOfDeath);
	}

}

function plusOrMinusPressed( plusOrMinus ) {

	//trace("plusOrMinusPressed called");

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

	//trace("pressActions Called");

	now = getTimer();
	//trace("now = " + now + "  lastHoldAdjustTime = " + lastHoldAdjustTime);
	if (clickNow == true) {
		// adjust up or down at normal speed
		//trace("clickAdjust Code Called, plus=" + plus + ",minus=" + minus);
		if (plus == true) {
			riskOfDeath += clickSpeed;
		} else {
			riskOfDeath -= clickSpeed;
		}
		clickNow = false;
	} else {
		if (  ( (now - lastHoldAdjustTime > minHoldDelay) && holding == false) || ( holding == true && ( now - lastHoldAdjustTime > holdIncrementTime) ) ) {
			// adjust up or down at hold speed
			//trace("holdAdjust Code Called, plus=" + plus + ",minus=" + minus);
			holding = true;
			if (plus == true) {
				riskOfDeath += holdSpeed;
			} else {
				riskOfDeath -= holdSpeed;
			}
			riskChanged = true;

			lastHoldAdjustTime = getTimer();
			//trace("riskOfDeath = " + riskOfDeath);
		}
	}

	//trace("riskOfDeath = " + riskOfDeath);

	// check boundraies
	if (riskOfDeath < 0) {
		riskOfDeath = 0;
	}

	if (riskOfDeath >100) {
		riskOfDeath = 100;
	}
	riskOfLife = 100-riskOfDeath;


	updateRiskChanged();
	updateFaces();
	updateProportionsText();

}



function faceClicked ( faceClipReference ) {
	finalizeNow = false;
	var clipName = faceClipReference + "";
	//trace("clipName = " + clipName);
	var underscorePos = clipName.indexOf("_", 10);
	clipNum = clipName.slice(underscorePos +1, clipName.length);

	facesArray[clipNum] = Math.abs(facesArray[clipNum] -1);
	updateAliveAndDead(clipNum);
	updateRiskValue();
	updateFaces();
	updateProportionsText();
	if (forceAnswer != false) {
		if (riskOfDeath != forceAnswer) {
			this.selfRunning();
			userActions.currentState = 4;
		} else {
			this.selfFinalizable();
			userActions.currentState = 5;
		}
	} else {
		if (riskOfDeath == 0) {
			//trace("switching back to running");
			this.selfRunning();
		} else {
			this.selfFinalizable();
		}
	}

}

function updateAliveAndDead( clipChangedNum ) {

}

function updateRiskValue() {
	riskOfLife=0;
	for (j=1; j<=100; j++) {
		riskOfLife+=facesArray[j];
	}
	riskOfDeath = 100 - riskOfLife;
}


function updateFaces () {

	for (j=1; j<=100; j++) {
		var tempObj = "faceClip_" + j;
		tempObj = eval(tempObj);
		//trace("facesArray[" + j + "]=" + facesArray[j]);
		if (facesArray[j] == 1) {
			tempObj.gotoAndStop("alive");
		} else {
			tempObj.gotoAndStop("dead");
		}
	}

}

function updateRiskChanged () {

	newRiskOfDeath = riskOfDeath;
	updateRiskValue(); // sets the numbers to their old values (based on facesArray)
	if (newRiskOfDeath >= riskOfDeath) {
		// need to change difference 1s to 0s
			numToChange = newRiskOfDeath - riskOfDeath;
			while (numToChange > 0) {
				tryThisNum = Math.round(Math.random() * 99) +1;
				if (facesArray[tryThisNum] == 1) {
					facesArray[tryThisNum] = 0;
					numToChange--;
				}
			}

	} else {
		// need to change x 0s to 1s.
			numToChange = riskOfDeath - newRiskOfDeath;
			while (numToChange > 0) {
				tryThisNum = Math.round(Math.random() * 99) +1;
				if (facesArray[tryThisNum] == 0) {
					facesArray[tryThisNum] = 1;
					numToChange--;
				}
			}

	}

	riskOfDeath = newRiskOfDeath;
	riskOfLife = 100 - riskOfDeath;


	if (forceAnswer != false) {
		if (riskOfDeath != forceAnswer) {
			this.selfRunning();
			userActions.currentState = 4;
		} else {
			this.selfFinalizable();
			userActions.currentState = 5;
		}
	} else {

		if (riskOfDeath == 0) {
			//trace("switching back to running");
			this.selfRunning();
		} else {
			this.selfFinalizable();
		}
	}
}

function updateProportionsText ( ) {

	//trace("updating proportions.  riskOfDeath=" + riskOfDeath + " and riskOfLife=" + riskOfLife);

	//option1prob = riskOfLife + "/100";
	//option2prob = riskOfDeath + "/100";
	option1prob = riskOfLife;
	option2prob = riskOfDeath;

}

function toggleInlineHelp () {
	inlineHelp.play();
}


