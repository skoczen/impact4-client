/*
	JavaScriptFlashGateway.as
	
	Part of the Flash / JavaScript Integration Kit
	http://www.macromedia.com/go/flashjavascript
	
	Created by:
	
	Mike Chambers
	http://weblogs.macromedia.com/mesh/
	mesh@macromedia.com
	
	Christian Cantrell
	http://weblogs.macromedia.com/cantrell/
	cantrell@macromedia.com
	
	----
	Macromedia(r) Flash(r)./ JavaScript Integration Kit License


	Copyright (c) 2005 Macromedia, inc. All rights reserved.

	Redistribution and use in source and binary forms, with or without modification,
	are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this 
	list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright notice, 
	this list of conditions and the following disclaimer in the documentation and/or
	other materials provided with the distribution.

	3. The end-user documentation included with the redistribution, if any, must 
	include the following acknowledgment:

    "This product includes software developed by Macromedia, Inc. 
    (http://www.macromedia.com)."

	Alternately, this acknowledgment may appear in the software itself, if and 
	wherever such third-party acknowledgments normally appear.

	4. The name Macromedia must not be used to endorse or promote products derived
	from this software without prior written permission. For written permission,
	please contact devrelations@macromedia.com.

	5. Products derived from this software may not be called "Macromedia" or 
	“Macromedia Flash”, nor may "Macromedia" or “Macromedia Flash” appear in their
	 name.

	THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, 
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL MACROMEDIA OR
	ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
	DAMAGE.
*/

/*
	Note, this is not a class file, but an include file of procedural code.
*/

import com.macromedia.javascript.JavaScriptSerializer;

// format of variables being sent in : d1, t1

/*
//this is used for debugging
function onStatus(eventObj:Object):Void
{
	trace("----------onStatus-----------");
	
	for(var x:String in eventObj)
	{
		trace(x + " : " + eventObj[x]);
	}
}
*/

/*
	Parses variables sent in via html / JavaScript
*/
function parseVars():Array
{
	
	if(_root.functionName == undefined)
	{
		trace("Warning : functionName not defined. Exiting.");
		return;
	}
	var outArray:Array = new Array();
	
	outArray.push(_root.functionName);
	
	var index:Number = 0;
	
	var type:String;
	var data:String;
	
	while((type = _root["t" + index]) != undefined)
	{
		data = _root["d" + index];
		
		//deserialize into native ActionScript types
		outArray.push(JavaScriptSerializer.deserializeItem(type, data));
        index++;
	}
	
	return outArray;
}

//LocalConnection object used to talk to JavaScriptProxy instance in main app / content
var sending_lc:LocalConnection;

//if lcId is not passed in via HTML, then we abort, since we can't do anything without
//it
if(_root.lcId != undefined)
{
	sending_lc = new LocalConnection();
	sending_lc.onStatus = onStatus; 
	
	//create the arguments array for the function call.
	var argsArray:Array = parseVars();
	
	if(argsArray != undefined && argsArray.length > 0)
	{
		//call the proxy function in the JavaScriptProxy instance in the main app / content
		sending_lc.send(_root.lcId, "callFlash", argsArray);
	}
	
	//close the connection
	sending_lc.close();
}
