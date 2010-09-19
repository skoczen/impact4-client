// This is the ActionScript code for the HAQ.
// 
// 

// ---- Initializing Variables ----


	var arrItem = new Array;
	var arrSequence = new Array;
	var arrAnswers = new Array;
	var jointNames = new Array;
	var numQuestions = 29;
	var currentQuestion = 1;
	var itemAnswer = "";

// For Homunculus
	var numPainful = 0;
	var numSwollen = 0;
	var numPainAndSwelling = 0;
	var arrJointResponses = new Array;
	var numJoints;

	// Initialize Arrays
	for (j=0; j<=numQuestions; j++) {
			arrItem = [j,j];
			arrSequence[j] = arrItem;
			arrAnswers[j] = "";
		}	
	
	jointNames[0] = ""
	jointNames[1] = "Left Pinky Toe, 2nd Joint";
	jointNames[2] = "Left Ring Toe, 2nd Joint";
	jointNames[3] = "Left Middle Toe, 2nd Joint";
	jointNames[4] = "Left Index Toe, 2nd Joint";
	jointNames[5] = "Left Big Toe, 2nd Joint";
	jointNames[6] = "Right Big Toe, 2nd Joint";
	jointNames[7] = "Right Index Toe, 2nd Joint";
	jointNames[8] = "Right Middle Toe, 2nd Joint";
	jointNames[9] = "Right Ring Toe, 2nd Joint";
	jointNames[10] = "Right Pinky Toe, 2nd Joint";
	jointNames[11] = "Left Pinky Toe, Base Joint";
	jointNames[12] = "Left Ring Toe, Base Joint";
	jointNames[13] = "Left Middle Toe, Base Joint";
	jointNames[14] = "Left Index Toe, Base Joint";
	jointNames[15] = "Left Big Toe, Base Joint";
	jointNames[16] = "Right Big Toe, Base Joint";
	jointNames[17] = "Right Index Toe, Base Joint";
	jointNames[18] = "Right Middle Toe, Base Joint";
	jointNames[19] = "Right Ring Toe, Base Joint";
	jointNames[20] = "Right Pinky Toe, Base Joint";
	jointNames[21] = "Left Foot, Midfoot Joints";
	jointNames[22] = "Neck";
	jointNames[23] = "Right Foot, Midfoot Joints";
	jointNames[24] = "Left Ankle";
	jointNames[25] = "Upper Back";
	jointNames[26] = "Right Ankle";
	jointNames[27] = "Left Knee";
	jointNames[28] = "Lower Back";
	jointNames[29] = "Right Knee";
	jointNames[30] = "Left Hip";
	jointNames[31] = "Right Hip";
	jointNames[32] = "Left Elbow";
	jointNames[33] = "Right Elbow";
	jointNames[34] = "Left Breastbone Joint";
	jointNames[35] = "Right Breastbone Joint";
	jointNames[36] = "Left Shoulder";
	jointNames[37] = "Right Shoulder";
	jointNames[38] = "Left Jaw Joint";
	jointNames[39] = "Right Jaw Joint";
	jointNames[40] = "Left Pinky Finger, 2nd Joint";
	jointNames[41] = "Left Ring Finger, 2nd Joint";
	jointNames[42] = "Left Middle Finger, 2nd Joint";
	jointNames[43] = "Left Index Finger, 2nd Joint";
	jointNames[44] = "Left Thumb, 2nd Joint";
	jointNames[45] = "Right Thumb, 2nd Joint";
	jointNames[46] = "Right Index Finger, 2nd Joint";
	jointNames[47] = "Right Middle Finger, 2nd Joint";
	jointNames[48] = "Right Ring Finger, 2nd Joint";
	jointNames[49] = "Right Pinky Finger, 2nd Joint";
	jointNames[50] = "Left Pinky Finger, Middle Joint";
	jointNames[51] = "Left Ring Finger, Middle Joint";
	jointNames[52] = "Left Middle Finger, Middle Joint";
	jointNames[53] = "Left Index Finger, Middle Joint";
	jointNames[54] = "Left Thumb, Middle Joint";
	jointNames[55] = "Right Thumb, Middle Joint";
	jointNames[56] = "Right Index Finger, Middle Joint";
	jointNames[57] = "Right Middle Finger, Middle Joint";
	jointNames[58] = "Right Ring Finger, Middle Joint";
	jointNames[59] = "Right Pinky Finger, Middle Joint";
	jointNames[60] = "Left Pinky Finger, Knuckle Joint";
	jointNames[61] = "Left Ring Finger, Knuckle Joint";
	jointNames[62] = "Left Middle Finger, Knuckle Joint";
	jointNames[63] = "Left Index Finger, Knuckle Joint";
	jointNames[64] = "Left Thumb, Hand Joint";
	jointNames[65] = "Right Thumb, Hand Joint";
	jointNames[66] = "Right Index Finger, Knuckle Joint";
	jointNames[67] = "Right Middle Finger, Knuckle Joint";
	jointNames[68] = "Right Ring Finger, Knuckle Joint";
	jointNames[69] = "Right Pinky Finger, Knuckle Joint";
	jointNames[70] = "Left Wrist";
	jointNames[71] = "Right Wrist";


// End Data

// Begin Functions



function CompileJoints ()
{
	// The purpose of this function:
	// 1. Crunch the Joints into an array.
	// 2. Put that array in the main array.
	// 3. Count the number of Painful Joints.
	// 4. Count the number of Swollen Joints.
	// 5. Count the number of Joints with both pain and swelling.
	//
	// Legend:
	// 0 - No Pain, No Swelling
	// 1 - Swelling Only
	// 2 - Pain Only
	// 3 - Both Pain and Swelling
	//
  // Note: Some data structures are defined as global structures at the top.
	
	numJoints = jointNames.length;
	trace ("numJoints = " + numJoints);

	var tempResponse;

	for (j=1; J<numJoints; j++) 
	{
		// Fills the array
		var tempObj = "jointCountClip.homunculus.Joint" + j + ".symbols";
		//trace("tempObj = " + tempObj);
		var tempObj = eval (tempObj);
		//trace("tempObj = " + tempObj);
		tempResponse = tempObj._currentframe - 1;
		trace("tempResponse[" + j + "] = " + tempResponse);
		arrJointResponses[j] = tempResponse;
		if (tempResponse == 1) {
			numSwollen++;
		} else {
			if (tempResponse == 2) {
					numPainful++;
			} else {
				if (tempResponse == 3) {
					numPainAndSwelling++;
					numPainful++;
					numSwollen++;
				}// end both
			} // end two
		} // end one
	} // end loop

	trace("arrJointResponses = " + arrJointResponses);
	trace("numPainAndSwelling = " + numPainAndSwelling);
	trace("numPainful = " + numPainful);
	trace("numSwollen = " + numSwollen);

	
	// At the end of this function, we have an array called arrJointResponses to hand back to i4.

}

