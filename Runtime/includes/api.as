/* API -- This file holds all the public api hooks, etc
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: api.as,v 1.10 2004/03/30 01:43:41 abansod Exp $
 */

if(typeof(_global._runtime) == "undefined")
{
	_global._runtime = new Object();

	_global._runtime.getCurrentModules = getCurrentModules; 
	_global._runtime.userModuleToSystem = userModuleToSystem;
	_global._runtime.sendEventToModules = sendEventToModules;
	_global._runtime.allocNewLevel = allocNewLevel;
	_global._runtime.registerNewEvent = registerNewEvent;
	_global._runtime.status = runtimeStatus;
	_global._runtime.createDataField = createDataField;
}

if(typeof(_global._navigation) == "undefined")
{
	_global._navigation = new Object();
	
	_global._navigation.registerNewTag = registerNewTag;
}

if(typeof(_global._loader) == "undefined")
{
	_global._loader = new Object();
	
	_global._loader.load = i4Load;
	_global._loader.unload = i4Unload;
}

if(typeof(_global._encryption) == "undefined")
{
	_global._encryption = new Object();
	
	_global._encryption.random = LERandom.nextInt;
	_global._encryption.base64Encode = base64Encode;
	_global._encryption.base64Decode = base64Decode;
}

if(typeof(_global._database) == "undefined")
{
	_global._database = new Object();
	
	_global._database.setValue = _setValue;
	_global._database.getValue = _getValue;
	_global._database.getKeyNames = getKeyNames;
	_global._database.getFieldAccess = getFieldAccess;
	_global._database.getFieldType = getFieldType;
}

if(typeof(_global._urlClient) == "undefined")
{
	_global._urlClient = new Object();

	// Methods
	_global._urlClient.Init = UrlClient_Init;
	_global._urlClient.Send = UrlClient_Send;
	
	_global._urlClient.URL = "";
	_global._urlClient.outputLayer = "";
}

if(typeof(_global._XmlSocketClient) == "undefined")
{
	_global._XmlSocketClient = new Object();

	// Methods
	_global._XmlSocketClient.init = XmlSocketClient_init;
	_global._XmlSocketClient.connect = XmlSocketClient_connect;
	_global._XmlSocketClient.disconnect = XmlSocketClient_disconnect;
	_global._XmlSocketClient.sendPublicKey = XmlSocketClient_sendPublicKey;
	_global._XmlSocketClient.sendLine = XmlSocketClient_sendLine;
	_global._XmlSocketClient.createKey = XmlSocketClient_createKey;
	_global._XmlSocketClient.sendData = XmlSocketClient_sendData;
	_global._XmlSocketClient.sendDataSpecific = XmlSocketClient_sendDataSpecific;
	_global._XmlSocketClient.sendManifest = XmlSocketClient_sendManifest;
	_global._XmlSocketClient.createRecordSet = XmlSocketClient_createRecordSet;
	_global._XmlSocketClient.flushBuffer = XmlSocketClient_flushBuffer;
	_global._XmlSocketClient.query = XmlSocketClient_query;

	_global._XmlSocketClient.theSocket = new XMLSocket();
	_global._XmlSocketClient.protocolVersion = "0.0.4";
	_global._XmlSocketClient.isSecure = false;
	_global._XmlSocketClient.isConnected = false;
	_global._XmlSocketClient.needAck = new Array();
	_global._XmlSocketClient.recordSets = new Array();
	_global._XmlSocketClient.queryCallbacks = new Array();
	_global._XmlSocketClient.server = "localhost";
	_global._XmlSocketClient.port = 8080;
	_global._XmlSocketClient.outputLayer = "";
	_global._XmlSocketClient.sendBuffer = "";
	_global._XmlSocketClient.sequenceNumber = 0;
}

// only one instance of the cacheManager allowed
if(typeof(_global._cacheManager) == "undefined")
{
	_global._cacheManager = new Object(); 
	_global._cacheManager.init = _cacheManager_init;
	_global._cacheManager.fullCommit = _cacheManager_fullCommit;
	_global._cacheManager.loadFromFullCommit = _cacheManager_loadFromFullCommit;

	_global._cacheManager.writeManifest = _cacheManager_writeManifest;
	_global._cacheManager.getManifests = _cacheManager_getManifests;
	_global._cacheManager.getManifestItem = _cacheManager_getManifestItem;
	_global._cacheManager.deleteManifest = _cacheManager_deleteManifest;
	_global._cacheManager.restoreFromManifest = _cacheManager_restoreFromManifest;
	_global._cacheManager.writeToManifest = _cacheManager_writeToManifest;
	_global._cacheManager.createManifestEntry = _cacheManager_createManifestEntry;
	_global._cacheManager.flushManifest = _cacheManager_flushManifest;
	_global._cacheManager.status = _cacheManager_status;
	_global._cacheManager.manifestUserData = null;

	_global._cacheManager.kill = _cacheManager_kill;
	_global._cacheManager.killAll = _cacheManager_killAll;
	_global._cacheManager.send = _cacheManager_send;
	_global._cacheManager.deactivateIfNeeded = _cacheManager_deactivateIfNeeded;
	_global._cacheManager.different = _cacheManager_different;
	_global._cacheManager.recommitFromChangeLog = _cacheManager_recommitFromChangeLog;
	_global._cacheManager.sharedData = null;
	_global._cacheManager.namespaceString = null;
	
}

