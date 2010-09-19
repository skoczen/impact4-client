/* UrlClient -- Simple HTTP GET based data saving client
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: urlclient.as,v 1.7 2003/06/26 04:56:31 abansod Exp $
 */ 

function UrlClient_Init(theURL, theOutputLayer)
{
	st("urlclient: Init with " + theURL + ", dal output " + theOutputLayer);
	_global._urlClient.URL = theURL;
	_global._urlClient.outputLayer = theOutputLayer;
}


// Sends this machine's manifest to the URL
// TODO: Need to cut down on the variable name representation
// perhaps do somethign like, varName1=vp=value1=ts=timestamp1|varNameN=vp=valueN=ts=timestampN
// e.g.: impact4_foo_fooValue=vp=3=ts=39488
function UrlClient_Send()
{
	
	if(typeof(_urlClient.URL) == "undefined" || _urlClient.URL == "")
		_urlClient.URL = "http://localhost/impact4archweb/collect.aspx";
	
	var theList = _cacheManager.getManifests();
	for(var i = 0; i < theList.length; i++)
	{
		var sendData = new LoadVars();

		var item = _cacheManager.getManifestItem(theList[i]);
		st("urlclient: sending " + item.UniqueName + " to " + _urlClient.URL);
		sendData.VersionNumber = item.VersionNumber;
		sendData.UniqueName = item.UniqueName;
		sendData.LoadHistory = item.LoadHistory;
		sendData.WriteTime = item.WriteTime;
		sendData.ProjectName = item.ProjectName;

		var vpTotal = "";
		var tsTotal = "";
		var namesTotal = "";
		var ctr = 0;
		for(var j in item.ValuePairs)
		{
			namesTotal += "|" + searchAndReplace(j, "impact4.", "");
			vpTotal += "|" + item.ValuePairs[j] + "|" + item.TimeStamp[j];
			//tsTotal += "|" + item.TimeStamp[j];
			ctr++;
		}

		sendData.VPTS = vpTotal;
		// sendData.TimeStamp = tsTotal;
		sendData.Names = namesTotal;

		sendData.send(_urlClient.URL, "_new", "POST");
	}

}


