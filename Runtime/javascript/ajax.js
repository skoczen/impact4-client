var xmlHttp;
var caller;
var loc = this.location + "";
loc = loc.substring(0,loc.indexOf(":"));
if (loc.charAt(loc.length) == "s" || loc.charAt(loc.length) == "S") {
	var httpsStatus = true;
} else {
	var httpsStatus = false;
}
function sendData(str,callPoint)
{ 
	xmlHttp=GetXmlHttpObject()
	if (xmlHttp==null)
	 {
	 alert ("Browser does not support HTTP Request")
	 return
	 }

	if (httpsStatus || secureOverride) {
		var url="https://quantumimagery.com/i4Server/i4Server.php"		
	} else {
		var url="http://quantumimagery.com/i4Server/i4Server.php"
	}

	
//	url=url+"?q="+str
	url=url+str
	caller = callPoint;
//	url=url+"&sid="+Math.random()
	xmlHttp.onreadystatechange=stateChanged 
	xmlHttp.open("GET",url,true)
	xmlHttp.send(null)
}
function stateChanged() 
{ 
	if (xmlHttp.readyState==4 || xmlHttp.readyState=="complete")
	 { 
	// put into hidden div
	 document.getElementById("serverResponse").innerHTML=xmlHttp.responseText 
	// also call flash
	flashProxy.call('serverResponseRecieved', xmlHttp.responseText);		


//	alert("Response Recieved.\n"+xmlHttp.responseText);
 	} 
}
function sendDataManifest(str)
{ 
	xmlHttp=GetXmlHttpObject()
	if (xmlHttp==null)
	 {
	 alert ("Browser does not support HTTP Request")
	 return
	 }
	if (httpsStatus || secureOverride) {
		var url="https://quantumimagery.com/i4Server/i4Server.php"		
	} else {
		var url="http://quantumimagery.com/i4Server/i4Server.php"
	}
	url=url+str
	xmlHttp.onreadystatechange=stateChangedManifest 
	xmlHttp.open("GET",url,true)
	xmlHttp.send(null)
}
function stateChangedManifest() 
{ 
	if (xmlHttp.readyState==4 || xmlHttp.readyState=="complete")
	 { 
	// put into hidden div
	 document.getElementById("serverResponse").innerHTML=xmlHttp.responseText 
	// also call flash
	flashProxy.call('manifestResponseRecieved', xmlHttp.responseText);
//	alert("Response Recieved.\n"+xmlHttp.responseText);
 	} 
}
function passCSVFile(csvString) {
	alert("About to pass");
	newPage = open("","displayWindow","width=300,height=200,left=10,top=10");
	newPage.document.open();
	newPage.document.write(csvString);
	newPage.document.close();
}
function GetXmlHttpObject()
{
	var xmlHttp=null;
	try
	 {
	 // Firefox, Opera 8.0+, Safari
	 xmlHttp=new XMLHttpRequest();
	 }
	catch (e)
	 {
	 //Internet Explorer
	 try
	  {
	  xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");
	  }
	 catch (e)
	  {
	  xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
	  }
	 }
	return xmlHttp;
}