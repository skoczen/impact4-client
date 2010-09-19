/*// Temp code for testing
foo = 1;
bar = "hooray bar!";
etc = false;

fooArr = new Array (foo,bar,etc);
varsArr = new Array ("foo","bar","ack");
typeArr = new Array("int","string","boolean")

surveyName = "test of AJAX";
// hash of "Test Password"
surveyPass = "VGVzdCBQYXNzd29yZA==";
*/

//sessionID = _root.lcId;

//encodeData();


// Flash - JS Connection

import com.macromedia.javascript.JavaScriptProxy;
var proxy:JavaScriptProxy = new JavaScriptProxy(_root.lcId, this);
_global.sendingManifest = false;


// Example call
//proxy.call("popit", "arg1", new Object());

// Example JS-Flash Call
/*function setFoo () {
	foo = "ack!";
}
*/





// Functions used in i4 Server 2.0+ for the AJAX connection to a database.



function ajax_encodeData() {
	// get the manifest
	var postString = "";
	
	// Constants for Translation
/*	
	_global.DB_FIELDACCESS_CONSTANT		= 0;
	_global.DB_FIELDACCESS_READWRITE	= 1;
	_global.DB_FIELDACCESS_SYSTEMWRITEONLY	= 2;

	_global.DB_TYPE_OBJECT		= 0;
	_global.DB_TYPE_STRING		= 1;
	_global.DB_TYPE_INTEGER		= 2;
	_global.DB_TYPE_FLOAT		= 3;
	_global.DB_TYPE_BOOLEAN		= 4;
	_global.DB_TYPE_COMPOSITE	= 5;
*/
	var j=0;
	for(var i in _global._internalDB.ValuePairs) {
		if(_global._internalDB.FieldAccess[i] == DB_FIELDACCESS_READWRITE) {
			postString += "f" + j + "n=" + escape(searchAndReplace(searchAndReplace(i,"impact4.",""),".","_")) + "&f" + j + "v=" + escape(_global._internalDB.ValuePairs[i]) + "&f" + j + "t=" + escape(	_global._internalDB.DataTypes[i]) + "&";
			j++;
		}
	}

	
	// add the database info, and password hash (hash should be what's put in the XML)
	postString = "?sn=" + escape(_getValue("configuration.surveyName")) + "&sp=" + escape(_getValue("configuration.surveyPass")) + "&sesID=" + _root.lcId + "&nv=" + j + "&" + postString + "complete=true";


	
	// return the string
//	trace(postString);
//	proxy.call("popit",postString);			
	return postString;
}

var timeoutInt;
var lastScreenVar = "";
function ajax_postData(encodedString,screenVar){
	// call JS function to post data
		lastScreenVar = screenVar;
		proxy.call("sendData",ajax_encodeData());
		
	// add a timeout handler - 60 seconds.	
		timeoutInt = setInterval(ajax_timeout,90000);
		
}

_global.ajax_timeout = function () {
	serverResponseRecieved(4);
	clearInterval(timeoutInt);
}


function serverResponseRecieved(feedbackString){
	// this is called after a successful AJAX save.  
	clearInterval(timeoutInt);
	
	
	/** 0 = no errors.
	* 1 = error saving.
	* 2 = database not created
	* 3 = password doesn't match
	* 4 = timeout
	*/
	// Currently, we don't do anything with the error codes.  Probably best for security.
	trace("serverResponseRecieved");
	if (lastScreenVar=="lastScreen") {
		lastScreenResponse(feedbackString);
	}
	lastScreenVar = "";
	
}