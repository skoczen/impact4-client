/* XmlSocketClient -- This file support the XMLSocket Client
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: xmlsocketclient.as,v 1.13 2004/01/25 03:18:54 abansod Exp $
 */ 

// inits the socket
function XmlSocketClient_init(theServer, thePort, theOutputLayer)
{
	st("xmlsocketclient: Init with " + theServer + ":" + thePort + " , dal output " + theOutputLayer);
	_XmlSocketClient.server = theServer;
	_XmlSocketClient.port = thePort;
	_XmlSocketClient.outputLayer = theOutputLayer;
}

// connect the socket up
function XmlSocketClient_connect(theServer, thePort)
{
	if(!_XmlSocketClient.isConnected)
	{
		st("xmlsocketclient: connecting to " + _XmlSocketClient.server + ", on port " + _XmlSocketClient.port + " using protocol version " + _XmlSocketClient.protocolVersion);
		// Create new XMLSocket object
		theSocket = new XMLSocket();
	
		// hook in the callbacks
		theSocket.onXML = XmlSocketClient_newXML;
		theSocket.onConnect = XmlSocketClient_newConnection;
		theSocket.onClose = XmlSocketClient_endConnection;

		// clear any per connection variables
		_XmlSocketClient.sendBuffer = "";
		_XmlSocketClient.sequenceNumber = 0;
		_XmlSocketClient.queryCallbacks = new Array();
	
		// Connect it up
		theSocket.connect(_XmlSocketClient.server, _XmlSocketClient.port);
		return true;
	}
	else
	{
		st("xmlsocketclient: already connected, disconnect first");
		return false;
	}
}

// disconnect the socket
function XmlSocketClient_disconnect()
{
	theSocket.close();
	isConnected = false;
}

// process any inbound xml
function XmlSocketClient_newXML(theXML)
{

	var doc = theXml.firstChild;
	if(doc.toString().trim().length != 0)
		st("newXML: " + doc.toString());

	if(doc.nodeName == "ack")
	{
		// remove the item from the needAck stack
		_XmlSocketClient.needAck.splice(0, 1);
		st("xmlsocketclient: needAck after removal is " + _XmlSocketClient.needAck.length);

		// if we recieved an ack for the hello, try the key exchange
		if(typeof(doc.attributes.protocol) != "undefined")
		{
			st("xmlsocketclient: sending public key");
			_XmlSocketClient.sendPublicKey();
		}
		// this was the ack by the server saying key setup went okay on its end
		else if(typeof(doc.attributes.publickey) != "undefined")
		{
			// foo bar nothing to do
		}
		// namespace && query means its the result of a <query>
		else if(typeof(doc.attributes.namespace) != "undefined" &&
			typeof(doc.attributes.query) != "undefined")
		{
			st("xmlsocketclient: xml has child nodes");
			_XmlSocketClient.recordSets[doc.attributes.sequenceNumber] = _XmlSocketClient.CreateRecordSet(doc);
			_XmlSocketClient.queryCallbacks[doc.attributes.sequenceNumber](_XmlSocketClient.recordSets[doc.attributes.sequenceNumber], doc.attributes.sequenceNumber);
		}
		// namespace && name mean the the ack of the <data> operation
		else if(typeof(doc.attributes.namespace) != "undefined" &&
			typeof(doc.attributes.name) != "undefined")
		{
			// foo bar nothing to do
		}

	}
	else if(doc.nodeName == "dh")
	{
		_XmlSocketClient.createKey(doc.attributes.publickey);
	}
	else if(doc.nodeName == "nak")
	{
		// big problem
		st("xmlsocketclient: NAK! " + doc.toString());
	}
}

// send a line, encrypted if secure
function XmlSocketClient_sendLine(s)
{
	//st("sending " + getTimer());
	//st("sending " + s);
	if(_XmlSocketClient.isSecure)
	{
		var sToSend = base64RC4Encrypt(s);

		if(_getValue("configuration.xmlSocketTraceSecure"))
			st("XmlSocketClient: sending " + s.length + " characters secure (" + s + ")");
		else
			st("XmlSocketClient: sending " + s.length + " characters secure");
		theSocket.send(sToSend + "\n");
	}
	else
	{
		st("XmlSocketClient: sending " + s.length + " in the clear: " + s);
		theSocket.send(s + "\n");	
	}
}

// send the public key
function XmlSocketClient_sendPublicKey()
{
	var genedPK = GeneratePublicKey();
	_XmlSocketClient.sendLine("<dh publickey=\"" + genedPK + "\" />");
}

// Execute a query
function XmlSocketClient_query(dataSource, driverType, SQL, callback)
{
	_XmlSocketClient.sequenceNumber++;
	st("XmlSocketClient: executing " + SQL + " on " + dataSource + ", driverType=" + driverType + " seqNum " + _XmlSocketClient.sequenceNumber);
	_XmlSocketClient.sendLine("<query namespace=\"" + dataSource + "\" driverType=\"" + driverType + "\" query=\"" + SQL + "\" sequenceNumber=\"" + (_XmlSocketClient.sequenceNumber) + "\"/>");
	_XmlSocketClient.needAck.push("query");
	_XmlSocketClient.queryCallbacks[_XmlSocketClient.sequenceNumber] = callback;
}

// create a record set from a query
function XmlSocketClient_CreateRecordSet(xml)
{
	st("XmlSocketClient: creating record set");

	// create our recordset object
	var recordSet = new Object();
	recordSet.columnNames = new Array();
	recordSet.columnValues = new Array();
	recordSet.currentRecord = 0;
	recordSet.totalRecords = 0;
	recordSet.get = function(colName)
	{
		return this.columnValues[this.currentRecord][this.getOrdinal(colName)];
	}
	recordSet.getOrdinal = function(colName)
	{
		for(var i = 0; i < this.columnNames.length; i++)
			if(this.columnNames[i] == colName)
			{
				return i;
			}
	}
	recordSet.getColumns = function() { return this.columnNames; }
	recordSet.moveNext   = function() { if(this.currentRecord < this.totalRecords) this.currentRecord++; }
	recordSet.moveBack   = function() { if(this.currentRecord > 0) this.currentRecord--; }


	for(var i = 0; i < xml.childNodes.length; i++)
	{
		// put the headers together
		if(xml.childNodes[i].nodeName == "header")
		{
			var headers = xml.childNodes[i];
			for(var j = 0; j < headers.childNodes.length; j++)
				recordSet.columnNames[j] = headers.childNodes[j].attributes.value;

		}
		// grab all the data from the rows in rowcollection
		else if(xml.childNodes[i].nodeName == "rowcollection")
		{
			var rowCol = xml.childNodes[i];
			for(var j = 0; j < rowCol.childNodes.length; j++)
			{
				if(rowCol.childNodes[j].nodeName == "row")
				{
					recordSet.columnValues[recordSet.totalRecords] = new Array();
					var theRow = rowCol.childNodes[j];
					for(var k = 0; k < theRow.childNodes.length; k++)
					{
						// put the data points in the appropirate columns
						if(theRow.childNodes[k].nodeName == "col")
							recordSet.columnValues[recordSet.totalRecords][k] = theRow.childNodes[k].attributes.value;
					}
					recordSet.totalRecords++;
				}
			}
		}
		
	}

	return recordSet;
}

// create the encryption key based on the remote public key
function XmlSocketClient_createKey(remotePublicKey)
{
	if(CreateEncryptionKey(remotePublicKey))
	{
		_XmlSocketClient.isSecure = true;
		_XmlSocketClient.sendLine("<ack publickey=\"" + GetPublicKey() + "\" />");

	}
}

// send a variable to the socket
function XmlSocketClient_sendData(varName, namespace)
{
// <data namespace="[internaldb]" name="[impact4.foo.vasValue]" value="[33]" />

	_XmlSocketClient.sendLine("<data namespace=\"" + namespace + "\" name=\"" + varName + "\" value=\"" + _getValue(varName) + "\" datatype=\"" + mapFieldTypeToText(getFieldType(varName)) + "\" timestamp=\"" + _internalDB.TimeStamp[varName] + "\" sequenceNumber=\"" + (_XmlSocketClient.sequenceNumber++) + "\"/>");
}

// if the connection succeeded, begin the protocol negoiation
function XmlSocketClient_newConnection(success)
{
	if (success)
	{
		st("xmlsocketclient: connected at " + (new Date()));

		// now try and negoiate the connection
		_XmlSocketClient.sendLine("<hello version=\"" + _internalDB.VersionNumber + "\" protocol=\"" + _XmlSocketClient.protocolVersion + "\" description=\"" + _internalDB.version + "\" uniquename=\"" + _internalDB.UniqueName + "\"/>");
		_XmlSocketClient.needAck.push("hello");
		_XmlSocketClient.isConnected = true;
	}
	else
	{
		st("xmlsocketclient: unable to connect");
	}
}

// called if the connection is disconnected (???)
function XmlSocketClient_endConnection()
{
	st("xmlsocketclient: disconnected at " + (new Date()));
	_XmlSocketClient.isConnected = false;
	_XmlSocketClient.isSecure = false;
	_XmlSocketClient.needAck = new Array();
	_XmlSocketClient.recordSets = new Array();
	_XmlSocketClient.queryCallbacks = new Array();
}

// send a specific set of data
function XmlSocketClient_sendDataSpecific(varName, namespace, varValue, varDataType, varTimeStamp)
{
	//_XmlSocketClient.sendBuffer += "<data namespace=\"" + namespace + "\" name=\"" + varName + "\" value=\"" + varValue + "\" datatype=\"" + varDataType + "\" timestamp=\"" + varTimeStamp + "\" />";
	_XmlSocketClient.needAck.push("data");
	_XmlSocketClient.sendLine("<data namespace=\"" + namespace + "\" name=\"" + varName + "\" value=\"" + varValue + "\" datatype=\"" + varDataType + "\" timestamp=\"" + varTimeStamp + "\" sequenceNumber=\"" + (_XmlSocketClient.sequenceNumber++) + "\"/>");
}

// flush any buffers
function XmlSocketClient_flushBuffer()
{
	var toSend = "";
	_XmlSocketClient.sendLine(_XmlSocketClient.sendBuffer);
	_XmlSocketClient.sendBuffer = "";//new Array();
}


// Sends this machine's manifest over the socket
function XmlSocketClient_sendManifest()
{

	/* pseudo code:
	1. iterate thru the manifests
	2. send a new data namespace=metadata, varname=uniquename, value=the new un
	3. send new namespace=metadata, varname=versionnumber, value=duh
	4. send the load history
	4. send the variables
	*/

	var theList = _cacheManager.getManifests();
	st("xmlsocketclient: sending " + theList.length + " manifest(s)");

	for(var i = 0; i < theList.length; i++)
	{

		var item = _cacheManager.getManifestItem(theList[i]);
		st("xmlsocketclient: sending " + item.UniqueName);
		_XmlSocketClient.sendDataSpecific("UniqueName", "metadata", item.UniqueName, "string", 0);
		_XmlSocketClient.sendDataSpecific("VersionNumber", "metadata", item.VersionNumber, "string", 0);
		_XmlSocketClient.sendDataSpecific("LoadHistory", "metadata", item.LoadHistory, "string", 0);
		_XmlSocketClient.sendDataSpecific("WriteTime", "metadata", item.WriteTime, "string", 0);
		_XmlSocketClient.sendDataSpecific("ProjectName", "metadata", item.ProjectName, "string", 0);



		var ctr = 0;
		for(var j in item.ValuePairs)
		{
			var theName = searchAndReplace(j, "impact4.", "");
			_XmlSocketClient.sendDataSpecific(theName, "internaldb", item.ValuePairs[j], "", item.TimeStamp[j]);
			ctr++;
		}

		st("xmlsocketclient: sent " + ctr + " items for this UniqueName " + item.UniqueName);

	}

	_XmlSocketClient.flushBuffer();

}


