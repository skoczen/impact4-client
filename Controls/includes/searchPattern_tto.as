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
function finalize()
{
	trace("wtp: finalize started");
	trace("wtp: my state is " + getValue("lifeCycleState"));
	setValue("finalBid",finalBid);
}



function initialize(forceInit) {

	
// The following parameters are are passed in by impact4:
// 		lowAnchor		- The lowest possible value
//								Default: 0
	lowAnchor = getValue("lowAnchor");
	if (lowAnchor == "" || lowAnchor == null || isNaN(lowAnchor))
		lowAnchor = 0;
//		highAnchor		- The highest possible value
//								Default: 10		
	highAnchor = getValue("highAnchor");
	if (highAnchor == "" || highAnchor == null || isNaN(highAnchor))
		highAnchor = 10;

//		resolutionType	- The type of resolution to use ('%'/'percent' or 'absolute')
//								Default: Percent
	resolutionType = getValue("resolutionType");
	if (resolutionType == "" || resolutionType == null)
		resolutionType = 'percent';

//		resolutionValue- The value of the required resolution
//								Default: 5
	resolutionValue = getValue("resolutionValue");
	if (resolutionValue == "" || resolutionValue == null || isNaN(resolutionValue))
		resolutionValue = 5;

//		questionStart	- The first part of the question, before the amount in question
//								Default: "Would you be willing to pay "
	questionStart = getValue("questionStart");
	if (questionStart == "" || questionStart == null)
		questionStart = "Would you be willing to pay ";
		
//		questionEnd		- The last part of the question, after the amount.
//								Default: " for this treatment?"
	questionEnd = getValue("questionEnd");
	if (questionEnd == "" || questionEnd == null)
		questionEnd = " for this treatment?";
		
//		currencyStart	- Any currency indicators before the number in question.
//								Default: "$"
	currencyStart = getValue("currencyStart");
	if (currencyStart == "" || currencyStart == null)
		currencyStart = "";
		
//		currencyEnd		- Any currency indicators after the number in question (i.e. USD, £, etc)
//								Default: ""
	currencyEnd = getValue("currencyEnd");
	if (currencyEnd == "" || currencyEnd == null)
		currencyEnd = "";
		
//		searchMethod	- The method to use when determining the next question. ('ping-pong','titrate up','titrate down', 'random','randomFullRange', bisection)
//								Default: "ping-pong"
	searchMethod = getValue("searchMethod");
	if (searchMethod == "" || searchMethod == null)
		searchMethod = "ping-pong";
		
//		startPoint		- The value to begin questioning on.  (an absolute number, defaults to random)
//								Default: depends on the searchMethod. ping-pong, titrade down: highAnchor; titrate up: lowAnchor; random: random; bisection: middle.
	startPoint = getValue("startPoint");
	if (startPoint == "" || startPoint == null || isNaN(startPoint)) {
		if (searchMethod == "ping-pong" || searchMethod == "titrate down") {
			startPoint = highAnchor;
		} else {
			if (searchMethod == "titrate up") {
				startPoint = lowAnchor;
			} else {
				if (searchMethod == "random") {
					startPoint = lowAnchor + (Math.random() * (highAnchor-lowAnchor));
				} else {
					startPoint = (lowAnchor+highAnchor) / 2
				}
			}
		}
		// clean up the number - either .0 or .5
		startPoint = Math.round(startPoint * roundingIncrement) / roundingIncrement;
	}
	
								
//		bidAdjustPercent- If in titration or pingpong modes, this indicates the percentage to adjust from the anchor for the next titration.
//								Default: 10 (percent)
	bidAdjustValue = getValue("bidAdjustValue");
	if (bidAdjustValue == "" || bidAdjustValue == null || isNaN(bidAdjustValue))
		bidAdjustValue = 10;

//		bidAdjustType- If in titration or pingpong modes, this indicates the type of adjustment ('%'/'percent' or 'absolute')
	bidAdjustType = getValue("bidAdjustType");
	if (bidAdjustType == "" || bidAdjustType == null)
		bidAdjustType = 'percent';

		
//		roundingIncrement- What the final number should be multiplied, rounded, then divided by.  (i.e. a value of 2 will round to n.0 or n.5 . 
//								A value of 1 will round to an int.)
//								Default: 2
	roundingIncrement = getValue("roundingIncrement");
	if (roundingIncrement == "" || roundingIncrement == null || isNaN(roundingIncrement))
		roundingIncrement = 2;

// Method-specific parameters:
//		numRandomTurns	- If in random searchMethod, this is the number of times you want to present a choice.  
//								Since it is random, reaching resolution may be difficult otherwise.
//								Default: 5
	numRandomTurns = getValue("numRandomTurns");
	if (searchMethod == "random" && (numRandomTurns == "" || numRandomTurns == null || isNaN(numRandomTurns)))
		numRandomTurns = 5;



	currentBid = startPoint * 1;
	if (bidAdjustType != 'absolute') {	
		bidAdjustPercent = bidAdjustValue/100; 
	}

	
	if (resolutionType == 'absolute') {
		resolutionTolerance = resolutionValue;
	} else {
		resolutionTolerance = (resolutionValue/100) * (highAnchor-lowAnchor);
	}


// VALUES:
//		finalBid		- This is the final result of user's responses.  Once their choices reach the specified resolution, 
//								the application returns the bisection of the high and low values
	finalBid = getValue("finalBid");
	if (finalBid == "" || finalBid == null || isNaN(finalBid) || forceInit===true) {
		if (forceInit != true) {
			finalBid = null;
		} 

		finalizeableNow = false;
		// Init vars
		currentHighAnchor = highAnchor * 1;
		currentLowAnchor = lowAnchor * 1;
		
	} else {
		finalizeableNow = true;
		currentHighAnchor = finalBid + resolutionTolerance;
		currentLowAnchor = finalBid - resolutionTolerance;
	}
	
	newBid._visible = false;
	confirmBox._visible = false;
	confirmed._visible = false;
		
    presentBid();
	play();
}



function presentBid () {
	newBid._visible = true;
	confirmBox._visible = false;
	confirmed._visible = false;
	scale.currentTab._visible = true;
	newBid.showBid(currentBid);
}	


function confirmBid (finalBid) {
	newBid._visible = false;
	confirmBox._visible = true;
	confirmed._visible = false;
	confirmBox.confirmBid(finalBid)
}

function bidConfirmed () {
	newBid._visible = false;
	confirmBox._visible = false;
	confirmed._visible = true;
	confirmed.confirm(finalBid);
	selfFinalizable();
	setValue("finalBid",finalBid);
}








// Last Code Revision: 6-15-2005
// By: Steven Skoczen - steven@quantumimagery.com

// The following parameters are are passed in by impact4:
var lowAnchor;			// The lowest possible value
							//		Default: 0
var highAnchor;		// The highest possible value
							// 	Default: 10		
var resolutionType;	// The type of resolution to use ('%'/'percent' or 'absolute')
							// 	Default: Percent
var resolutionValue;	// The value of the required resolution
							// 	Default: 5
var questionStart; 	// The first part of the question, before the amount in question
							// 	Default: "Would you be willing to pay "
var questionEnd;	 	// The last part of the question, after the amount.
							// 	Default: " for this treatment?"
var currencyStart; 	// Any currency indicators before the number in question.
							// 	Default: "$"
var currencyEnd;	 	// Any currency indicators after the number in question (i.e. USD, £, etc)
							// 	Default: ""
var searchMethod; 	// The method to use when determining the next question. ('ping-pong','titrate up','titrate down', 'random', bisection)
	 					 	// 	Default: "ping-pong"
var startPoint; 		// The value to begin questioning on.  (an absolute number, defaults to random)
							//		Default: depends on the searchMethod. ping-pong, titrade down: highAnchor; 
							//					titrate up: lowAnchor; random: random; bisection: middle.							
var bidAdjustType;	// If in titration or pingpong modes, this indicates the type of adjustment to make ('%','percent' or 'absolute')
							// 	Default: "percent"
var bidAdjustValue;	// If in titration or pingpong modes, this indicates the amount to adjust from the anchor for the next titration.
							// 	Default: 10
var roundingIncrement;// What the final number should be multiplied, rounded, then divided by.  (i.e. a value of 2 will round to n.0 or n.5 . 
							// A value of 1 will round to an int.)
							// Default: 2

// Method-specific parameters:
var numRandomTurns;	// If in random searchMethod, this is the number of times you want to present a choice.  
							// Since it is random, reaching resolution may be difficult otherwise.
							// Default: 5

// VALUES:
var finalBid;			// This is the final result of user's responses.  Once their choices reach the specified resolution, 
							// the application returns the bisection of the high and low values


// To be defined in the movie:
// function presentBid () {}	
// function confirmBid () {}

// Vars
	var currentHighAnchor;
	var currentLowAnchor;
	var currentBid;
	var numSearches = 1;	
	var resolutionTolerance;


function bidAnswered (response) {
	// Called on Yes or No click


	if (response == 'Yes') {
		currentLowAnchor = currentBid
	} else {
		currentHighAnchor = currentBid;
	}
	
	
	// see if we are within resolution tolerances
	if (currentLowAnchor>=currentHighAnchor || (currentHighAnchor-currentLowAnchor) <= resolutionTolerance || (searchMethod == 'random' && numSearches>=numRandomTurns ) ) {
		// if so, confirm with the user.
		// final Bid (cleaned up)
		finalBid = (currentHighAnchor+currentLowAnchor)/2;
		finalBid = (Math.round(finalBid * roundingIncrement*2)) / (roundingIncrement*2);
		confirmBid(finalBid);	
	} else {
		// if not, calculate the next bid value
		currentBid = nextBidValue();
		numSearches++;
		presentBid();

	}
	
}


function nextBidValue () {
	// based on currentHighAnchor and currentLowAnchor, make a new value and return it.
	
	var newBid;
	
	if (bidAdjustType == 'absolute') {
		bidAdjustAmount = bidAdjustValue
	} else {
		bidAdjustAmount = ((currentHighAnchor-currentLowAnchor)*bidAdjustPercent);
	}
	if (bidAdjustAmount < resolutionTolerance) {
		bidAdjustAmount = resolutionTolerance;
	}
	
	switch (searchMethod) {
		case "ping-pong":
			if ( (currentBid-currentLowAnchor) > (currentHighAnchor-currentBid) ) { 
				// we just asked a high question
				newBid = currentLowAnchor + bidAdjustAmount;
			} else {
				newBid = currentHighAnchor - bidAdjustAmount;
			}
		break;
		
		case "titrate up":
			newBid = currentLowAnchor + bidAdjustAmount;
		break;
		
		case "titrate down":
			newBid = currentHighAnchor - bidAdjustAmount;
		break;
		
		case "random":
			newBid = currentLowAnchor + (Math.random() * (currentHighAnchor-currentLowAnchor));
		break;
		case "randomFullRange":
			newBid = lowAnchor + (Math.random() * (highAnchor-lowAnchor));
		break;
		case "bisection":
			newBid = ((currentHighAnchor+currentLowAnchor) /2 );
		break;
	}
	// clean up the number - either .0 or .5
	newBid = (Math.round(newBid * roundingIncrement)) / roundingIncrement;
	// make sure we don't have more than 2 decimal places.
	newBid = (Math.round (newBid*100)) / 100;
	
	return newBid;
}

