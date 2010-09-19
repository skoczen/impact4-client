_global.admin_viewDatasets = function () {
	var traceString = "";
 	traceString += _cacheManager.status();
	var fullManifest = _cacheManager.getManifests();
	traceString += fullManifest + "\n";
//	traceString += typeof(fullManifest);
//	fullManifest = fullManifest.split(",");
//	traceString += fullManifest + "\n";
//	trace("getManifests: " + fullManifest);	
	var dataObj:Array = new Array();
	for (j=0; j<fullManifest.length; j++) {
		currManifest = _cacheManager.getManifestItem(fullManifest[j]);
		dataObj.addItem({Project_Name:currManifest.ProjectName, Time:currManifest.writeTime, Unique_ID:currManifest.UniqueName, sesID:currManifest.lcID});
		traceString += "currManifest : " + currManifest;
		traceString += "\nProject " + j + " [ "+fullManifest[j]+" ]: \n" + currManifest.UniqueName + "\n" + currManifest.valuePairs + "\n" + typeof(currManifest.valuePairs) + "\n";
	}
	if (j==0) {
		dataObj.addItem({Error_Message:"No Datasets stored on this computer."});
	}
	
	//return fullManifest;
//	return traceString;
	return dataObj;
}

function SurveyObj (surveyName,surveyTimestamp) {
	this.surveyName = surveyName;
	this.surveyTimestamp = surveyTimestamp;
}

var currentSendNum = 0;
var currentCacheSet = new Array();
var textString = "";
var errorsSending = false;

function ajax_uploadDatasets (statusTextArea) {
	errorsSending = false;
	// hack because flash doesn't support pointers.
	_global.ajaxManifestStatusText = statusTextArea;
	ajaxManifestStatusText.text = "";


	currentSendNum = 0;
	currentCacheSet = _cacheManager.getManifests();
	
	_global.sendingManifest = true;
	// for each dataset:
	
	if (currentSendNum < currentCacheSet.length) {
		sendDataset(currentCacheSet[currentSendNum]);
		currentSendNum++;
	}
	
	// hands off to sendDataset.
	
}

function sendDataset(curDataSetNum) {
		var curDataSet = _cacheManager.getManifestItem(curDataSetNum);
		j=0;
		for(var i in curDataSet.ValuePairs) {
				postString += "f" + j + "n=" + escape(searchAndReplace(searchAndReplace(i,"impact4.",""),".","_")) + "&f" + j + "v=" + escape(curDataSet.ValuePairs[i]) + "&f" + j + "t=" + escape( returnManifestVarType(curDataSet.ValuePairs[i])) + "&";
				j++;
		}

		var sesID = 0;
		// add the database info, and password hash (hash should be what's put in the XML)
		if (isNaN(curDataSet.lcId) || curDataSet.lcId == null || curDataSet.lcId == undefined) {
			sesID = searchAndReplace(hex2dec(searchAndReplace(curDataSet.UniqueName,"-",""))," ","");s
		} else {
			sesID = curDataSet.lcId;
		}

		postString = "?sn=" + escape(curDataSet.ProjectName) + "&sp=" + escape(curDataSet.pass) + "&sesID=" + sesID + "&nv=" + j + "&" + postString + "complete=true";
	
	ajaxManifestStatusText.text += "Sending dataset " + curDataSet.sesID + ".   The set was recorded at " + curDataSet.writeTime + ", and it has " + j + " fields.\n";
//	ajaxManifestStatusText.text += postString + "\n";
	proxy.call("sendDataManifest",postString);
}

function manifestResponseRecieved (response) {
//	ajaxManifestStatusText.text += "Response Recieved from Server:\n" + response;
	if (response == 0) {
		ajaxManifestStatusText.text += "Save Successful.\n\n";
	} else {
		errorsSending = true;
		// TODO: parse and display these.
		ajaxManifestStatusText.text += "\nError Saving!!\n\n"
	}

	if (currentSendNum < currentCacheSet.length) {
		sendDataset(currentCacheSet[currentSendNum]);
		currentSendNum++;
	} else {
		if (errorsSending == false) {
			ajaxManifestStatusText += "\nAll datasets sent successfully.";
		} else {
			errorsSending = true;
			// TODO: parse and display these.
			ajaxManifestStatusText.text += "\nError Saving!!\n\n"
		}
		dataSaveComplete(errorsSending);
	}
	
}

_global.ajax_clearDatasets = function () {
	errorCode = false;
	errorCode = _cacheManager.killAll();
	return errorCode;
}

function exportCSV (textBox) {
	var csvString = "";
	
	currentCacheSet = _cacheManager.getManifests();
	var headerRow:Array = new Array();
	var dataRows:Array = new Array();

	headerRow.push("surveyName");
	headerRow.push("sesID");
	headerRow.push("time")

	// get header row
	for (curDataSetNum; curDataSetNum<currentCacheSet.length; curDataSetNum++) {
		var curDataSet = _cacheManager.getManifestItem(currentCacheSet[curDataSetNum]);
		for(var i in curDataSet.ValuePairs) {
			if (!inArray(i,headerRow)) {
				headerRow.push(i);
			}
		}
	}
	csvString += headerRow.join() + "\n";

	// write below rows.
	for (curDataSetNum=0; curDataSetNum<currentCacheSet.length; curDataSetNum++) {
		curDataSet = _cacheManager.getManifestItem(currentCacheSet[curDataSetNum]);
		dataRows[curDataSetNum] = new Array();
		curRow = dataRows[curDataSetNum];
		
		var sesID = 0;
		if (isNaN(curDataSet.lcId) || curDataSet.lcId == null || curDataSet.lcId == undefined) {
			sesID = searchAndReplace(hex2dec(searchAndReplace(curDataSet.UniqueName,"-",""))," ","");
		} else {
			sesID = curDataSet.lcId;
		}
		
		curRow[0] = curDataSet.ProjectName;
		curRow[1] =	sesID;
		curRow[2] = curDataSet.writeTime;		

		j=0;
		for(var i in curDataSet.ValuePairs) {
				// check if j lines up.
				if (headerRow[j+3] == i) {
					// hooray. lines up.
					curRow[j+3] = curDataSet.ValuePairs[i];
				} else {
					// find where the header is.
					tempCol = posInArray(i,headerRow);
					curRow[tempCol] = curDataSet.ValuePairs[i];
				}
				j++;
		}


		csvString += curRow.join() + "\n";
	}
	
//	ajaxManifestStatusText.text += postString + "\n";
//	proxy.call("sendDataManifest",postString);

	trace("csvString:\n" + csvString);
//	proxy.call("passCSVFile", csvString);
	textBox.text = csvString;
}
		
_global.checkDataComplete = function () {
	trace("Last Screen!  Checking for save!");
	
	// See if we're online
	offlineVar = _getValue("configuration.runsOffline");
	if (offlineVar !== true) {
		// send the data.
		i4Admin.swapDepths(1999999);
		i4Admin._visible = true;
		i4Admin.gotoAndPlay("finalScreenConfirm");
		
		i4Admin.dataSaveSheet.responseText.text = "Contacting server, sending data...\n";
		
		ajax_postData("","lastScreen");
		// show the dialog (6 sec later - if response recieved by then, then it never shows.)
		
		// wait for feeback.
		// dataSaveSheet.responseText.
		
		// on error, show retry button.
		
		// on success, show close button.
	}
}

_global.lastScreenResponse = function (responseCode) {
	trace("lastScreenResponse called.  ResponseCode=" + responseCode);
//	i4Admin.dataSaveSheet.responseText.text += "\n\nresponseCode=" + responseCode + "\n\n";	
	if (i4Admin.interfaceVisible === true || responseCode != 0) {
		i4Admin.responseCode = responseCode;
		if (responseCode==0) {
			i4Admin.dataSaveSheet.responseText.text += "Save Successful.\n\nYou can now close this window safely.";
			// delete manifest?
			i4Admin.dataSaveSheet.gotoAndStop("close");
		} else {
			i4Admin.dataSaveSheet.responseText.text += "Save Unsuccessful.\n\nPlease check your internet connection, and click 'Send Again'.";
			i4Admin.dataSaveSheet.gotoAndStop("retry");
		}

	} else {
		i4Admin.stop();
		i4Admin._visible = false;
	}
}

function dataSaveComplete (errorCode) {
	// The save is done.  Either give a retry button if there were errors, or allow them to delete all the local sets.
	if (errorCode == false) {
		i4Admin.gotoAndPlay("uploadSuccess");
	} else {
		i4Admin.gotoAndPlay("uploadFailed");
	}
	
}


function returnManifestVarType ( val ) {
	valType = typeof(val);
	//var typeArray = new Array({Object:0,String:1,Integer:2,Float:3,Boolean:4});	
	switch (valType) {
		case "number":
			if(val%1 == 0) {
				valType = 2;
			} else {
				valType = 3;
			}
			break;
		case "string":
			valType = 1;
			break;
		case "boolean":
			valType = 4;
			break;
	}
	return valType;
}

function hex2dec( hex:String ) : String {
	var bytes:Array = [];
	while( hex.length > 2 ) {
		var byte:String = hex.substr( -2 );
		hex = hex.substr(0, hex.length-2 );
		bytes.splice( 0, 0, int("0x"+byte) );
	}
	return bytes.join(" ");
}