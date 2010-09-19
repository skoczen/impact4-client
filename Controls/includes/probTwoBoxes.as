// vars to set in XML
// option1Text
// option2Text
// riskOfDeath

//TODO: for v1.1 (if it ever happens):  add drag support.

var riskOfDeath;

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

var finalizableNow = false; // value loaded?

// below line was so that people didn't have to choose a value (could leave it at zero).
//this.selfFinalizable();


function initialize2 () {
	
	riskOfDeath = getValue("riskOfDeath");
	trace("**** riskOfDeath = " + riskOfDeath);
	// set initial vars
	if ( isNaN(riskOfDeath) || riskOfDeath == "" || typeof(riskOfDeath) == "undefined" || riskOfDeath == null) {
		riskOfDeath = 50;
	} else {
		finalizableNow = true;
	}
	riskOfLife = 100-riskOfDeath;
	
	updateRiskChanged();
	updateFaces();
	updateProportionsText();
	
	if (typeof(option1text) == "undefined")
		option1text = "Anna's Course (good course)";
	
	if (typeof(option2text) == "undefined")
		option2text = "Betty's Course (bad course)";
		
	// set up the screen
	
		// duplicate faces
		for (j=0; j<10; j++) 
		{
			for (k=1; k<=10; k++)
			{
				currentNum = (j*10) + k;
				if (currentNum != 1) {
				
					var tempObj = "faceClip_" + currentNum;
					
					faceClip_1.duplicateMovieClip(tempObj,2000 + currentNum);
					tempObj = eval(tempObj);
					
					tempObj._x +=  (k-1)* xOffset;
					tempObj._y += j * yOffset;
					
					
					tempObj = "faceClip2_" + ((j*10) + (k)) ;
					
					faceClip2_1.duplicateMovieClip(tempObj,3000 + currentNum);
					tempObj = eval(tempObj);
					
					tempObj._x +=  (k-1)* xOffset;
					tempObj._y -= j * yOffset;				
									
				}
			}
		}
	// run condition set functions
	updateFaces();
	updateProportionsText();
	
	
	
}

function finalize () {
	setValue("riskOfDeath", riskOfDeath);
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
	this.selfFinalizable();

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
	

	updateFaces();
	updateProportionsText();

}



function faceClicked ( faceClipReference ) {
	
	var clipName = faceClipReference + "";
	//trace("clipName = " + clipName);
	var underscorePos = clipName.indexOf("_", 10);
	clipNum = clipName.slice(underscorePos +1, clipName.length);
	clip1or2 = clipName.charAt(underscorePos-1);
	riskOfDeath = clipNum*1;
	if (clip1or2 != "2") {
		riskOfDeath--;
	}
	riskOfLife = 100-riskOfDeath;
	//facesArray[clipNum] = Math.abs(facesArray[clipNum] -1);
	//updateAliveAndDead(clipNum);
	//updateRiskValue();
	updateFaces();
	updateProportionsText();
	this.selfFinalizable();
	
}

function updateAliveAndDead( clipChangedNum ) {
	
}

function updateFaces () {
	
	for (j=1; j<=100; j++) {
		var tempObj = "faceClip_" + j;
		var tempObj2 = "faceClip2_" + j;
		tempObj = eval(tempObj);
		tempObj2 = eval(tempObj2);
		//trace("facesArray[" + j + "]=" + facesArray[j]);
		if (j > riskOfDeath)  {
			tempObj.gotoAndStop("alive");
			tempObj2.gotoAndStop("dead");
		} else {
			tempObj.gotoAndStop("dead");
			tempObj2.gotoAndStop("alive");
		}
	}
	
}



function updateProportionsText( ) {

	//trace("updating proportions.  riskOfDeath=" + riskOfDeath + " and riskOfLife=" + riskOfLife);
	
	option1prob = riskOfLife + "/100";
	option2prob = riskOfDeath + "/100";
	
	this.selfFinalizable();
	setValue("riskOfDeath", riskOfDeath);

}

function toggleInlineHelp () {
	inlineHelp.play();
}


