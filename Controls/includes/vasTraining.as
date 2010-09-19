
// test vars
/*
upButtonText = "Yay Up!";
downButtonText = "Yay Down!";
topAnchorText = "\rTop!"
bottomAnchorText = "Bottom!"
barLocked = false;
barDragging = true;
upAdjust = 10;
downAdjust = -5;
initialPercent = 35;
*/


// vars
var currentValue = -1; // current scale value


function initalize2()
{
	trace("vas: initalize started");
	trace("vas: this is " + new String(this));
	trace("vas: myName is " + this.myName);
	trace("vas: my state is " + getValue("lifeCycleState"));
	
	
	// Set default values
	if (startFrame == "" || startFrame == null)
		var startFrame = "start";
	
	trace("startFrame = " + startFrame);
	
	if (barLocked == "" || barLocked == null || isNaN(barLocked))
		barLocked = false;
	if (barDragging = "" || barDragging == null || isNaN(barDragging))
		barDragging = false;
	if (upAdjust == "" || upAdjust == null || isNaN(upAdjust))
		upAdjust = 5;
	if (downAdjust == "" || downAdjust == null || isNaN(downAdjust))
		downAdjust = -5;
	if (initialPercent == "" || initialPercent == null || isNaN(initialPercent))
		initialPercent = 50;
	
	//trace("vas: After Init:\nbarLocked = " + barLocked + "\nbarDragging = " + barDragging + "\nupAdjust = "  + upAdjust + "\ndownAdjust = " + downAdjust + "\ninitialPercent = " + initialPercent); 
	
	gotoAndPlay(startFrame);
	
	updateBarAndText (initialPercent, initialPercent);
	
	textfieldTopAnchor.autosize = "center";
	textfieldBottomAnchor.autosize = "center";
	//setTopAndBottomAnchors(topAnchor, bottomAnchor);
	
	
	setUpAndDownButtonText(upButtonText,downButtonText)
}

function finalize()
{	
	trace("vas: finalize started");
	trace("vas: my state is " + getValue("lifeCycleState"));
	//setValue("vasValue",vasScale.barScale);
}




// info
// vasScale.scaleBar is the bar.



function startBarDrag() {
	//
	if (barLocked == false)
		barDragging = true;
	
}



function stopBarDrag() {
	
	barDragging = false;
	
}




function barClick() {
	
	if (barLocked == false) {
		barLocked = true;
		barDragging = false;
	} else {
		barLocked = false;
		barDragging = true;
	}
	
	
}


function adjustPercent (amount) {
	
	newText = percentText + amount;
	newScalePos = vasScale.barScale + amount;
	
	newText = (newText > 100) ? 100 : newText;
	newText = (newText < 0) ? 0 : newText;
	
	newScalePos = (newScalePos > 100) ? 100 : newScalePos;
	newScalePos = (newScalePos < 0) ? 0 : newScalePos;
	
	

	
	updateBarAndText (newText, newScalePos);
	
}

function updateBarAndText (newText, newBarValue) {
	
		if (newText == "34" || newText == 34) {
			trace("calling finalize functions");
			this.selfFinalizable();
	} else {
			this.selfRunning();	
	}
	
		currentValue = newBarValue;
		
		percentText = newText;
		this.vasScale.barScale = newBarValue;
		this.vasScale.scaleBar._yscale = newBarValue;
		
}

function setUpAndDownButtonText (upText, downText) {
	// sets the text next to the up (plus) and down (minus) buttons
	
	upButtonText.autosize = "left";
	downButtonText.autosize = "left";
	
	
	if (typeof(upText) != "undefined" && upText != null)
		upButtonText = upText;
		
	if (typeof(downText) != "undefined" && downText != null)
		downButtonText = downText;
}


// vars used in the "press and hold" action
var minHoldDelay = 350; // milliseconds
var holdIncrementTime = 200; // milliseconds
var clickSpeed = 1;
var holdSpeed = 5; // speed that the faces appear/ disappear on a click or hold
var plus = false;
var minus = false;
var holding = false;
var valueChanged = false;

function plusOrMinusPressed( plusOrMinus ) {

	trace("plusOrMinusPressed called, plusOrMinus=" + plusOrMinus);

	if (plusOrMinus == "plus") {
		plus = true;
	} else {
		minus = true;
	}
	
	if ( valueChanged == false ) {
		clickNow = true;
		pressActions();
	} else {
		valueChanged = false;
	}



	trace("plus = " + plus);
	pressTimerStart = getTimer();
	lastHoldAdjustTime = pressTimerStart;

}

function plusOrMinusReleased( plusOrMinus ) {

	if (plusOrMinus == "plus") {
		plus = false;
	} else {
		minus = false;
	}
	
	holding = false;
}

function pressActions() {
	
	trace("pressActions Called");
	var adjustment = 0;
	
	now = getTimer();
	//trace("now = " + now + "  lastHoldAdjustTime = " + lastHoldAdjustTime);
	if (clickNow == true) {
		// adjust up or down at normal speed
		trace("clickAdjust Code Called, plus=" + plus + ",minus=" + minus);
		if (plus == true) {
			adjustment = clickSpeed;
		} else {
			adjustment = clickSpeed * -1;
		}
		clickNow = false;
	} else {
		if (  ( (now - lastHoldAdjustTime > minHoldDelay) && holding == false) || ( holding == true && ( now - lastHoldAdjustTime > holdIncrementTime) ) ) {
			// adjust up or down at hold speed
			trace("holdAdjust Code Called, plus=" + plus + ",minus=" + minus);
			holding = true;
			if (plus == true) {
				adjustment = holdSpeed;
			} else {
				adjustment = holdSpeed * -1;
			}
			valueChanged = true;
			
			lastHoldAdjustTime = getTimer();
		}
	}
	
	trace("adjustment = " + adjustment);
	adjustPercent(adjustment);

}

initalize2();


// ------------------- onClipEvent Code (on the vasScale instance) --------------------

