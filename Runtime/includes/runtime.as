/* Runtime - Core for Imapct4
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: runtime.as,v 1.49 2004/03/01 18:56:11 abansod Exp $
 */

#include "includes/events.as"
#include "includes/version.as"
#include "includes/database.as"
#include "includes/lifecycle.as"
#include "includes/navigation.as"
#include "includes/cachemanager.as"
#include "includes/modulebootstrap.as"
#include "includes/loader.as"
#include "includes/encryption.as"
#include "includes/urlclient.as"
#include "includes/xmlsocketclient.as"
#include "includes/loaderclass.as"
#include "includes/admin.as"
#include "includes/ajaxClient.as"
#include "includes/md5.as"

// Temp for development.
System.security.allowDomain("file://");
System.security.allowInsecureDomain("file://");
System.security.allowDomain("127.0.0.1");
System.security.allowInsecureDomain("127.0.0.1");
trace ("System.security.sandboxType = " +System.security.sandboxType);

/*
The impact4 "runtime" module. This file sets up the universe in the following order:

Code Flows in these steps (all steps in the 'runtime' module):
	1. initImpact4Runtime
		Starts the DB, sets the magic number and our currentModule ('runtime')
	2. initImpact4Configuration
		Sets the xml onLoad handler, and loads the XML (we loose control here in this path)
	3. initImpact4ConfigXMLFileLoaded
		Process the <configuration> tag (parseConfigurationXML-->parseConfigureTag)
		Stores the <navigation> tag in the database (impact4.runtime.navigation)
	4. initImpact4Main
		Calls applyConfiguration to setup the scenes
		Runs the navigation, passes control to the first module
*/
_global.MODULE_TYPE_MODULE = 1;
_global.MODULE_TYPE_LIBRARY = 2;
_global.MAX_RUNTIME_LOAD_LOOP = 10;

/****** GLOBALLY EXPORTED FUNCTIONS ******/
_global.initImpact4Runtime = function()
{
	if(	!_getValue("impact4.runtime.initFinished") &&
		!_getValue("impact4.runtime.xmlLoaded"))
	{
		// Setup our Internal Key Value Pair DB
		this._internalDB = {};
		this._internalDB.VersionNumber = _global._versionNumber;
			this._internalDB.Version = "Impact4 Version " + this._internalDB.VersionNumber + " Alpha";
		this._internalDB.ValuePairs = new Array();
		this._internalDB.FieldAccess = new Array();
		this._internalDB.DataTypes = new Array();
		this._internalDB.TimeStamp = new Array();

		// Very first thing, set any flash overrides we might have
		// because we need st to trace values	
		setOverrides();

		st(_internalDB.Version + " (" + _internalDB.VersionNumber + ")");
		st("runtime: Init started at " + getTimer());

		// 0.0.25: Seed the L'Ecuyer randomization
		SeedRandomization((new Date()).getTime());
		this._internalDB.UniqueName = makeGUID();
		st("runtime: UniqueName for this instance is " + _internalDB.UniqueName);

		// 0.0.24: All the code paths
		_global.allSubConditions = new Array();
		// 0.0.24: All the conditions that have been visisted
		_global.visitedConditions = new Array();

		// Set up our module Alias table
		this._internalDB.ModuleAliasLookup = new Array();

		// Set our loadingHistory List
		this._internalDB.LoadHistory = new Array();

		// Set our namespace, 0.1.30: removed the version specific namespace element
		this._internalDB.Namespace = "quantumimagery/impact4";// + _internalDB.VersionNumber;

		// Create our database changelog
		this._internalDBChangeLog = new Array();

		// 0.0.23: Create our "CurrentModules" list
		this._currentLoadedModules = new Array();
		
		// 0.1.28: Create our "CurrentLibraries" list
		this._currentLoadedLibraries = new Array();

		// 0.1.27: Our Level New Level Counter
		this._internalDBLevelCounter = 15000;

		// 0.1.30: 
		this._internalModuleList = new Array();

		// Create our SharedObject
		// NOTE: we don't create this in the _internalDB namespace because we don't
		// we save that ENTIRE structure
		_cacheManager.init("_global._internalDB", this._internalDB.Namespace);
	
		// Now we set our init flag to false
		_setValueUnchecked("impact4.runtime.initFinished", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

		// And set our xmlLoaded flag to false
		_setValueUnchecked("impact4.runtime.xmlLoaded", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);
	
		// Set the magic number for no good reason
		_setValueUnchecked("impact4.configuration.magicNumber", 3405691582, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);

		// Setup the current section text variable (YUCK! Why should runtime care about this?!? Interface should be setting this up!)
		_setValueUnchecked("impact4.runtime.currentSection", false, true, DB_FIELDACCESS_READWRITE, DB_TYPE_STRING);

		// If we loaded via the core module, then we need to prepend the correct directory string
		if(_global.loadedViaCore == true)
			_setValueUnchecked("impact4.runtime.loadingPrefix", "Runtime/", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
		else {
			// DEBUG MODE
//			_setValueUnchecked("impact4.runtime.loadingPrefix", "http://127.0.0.1/i4%20Server/i4Client/Runtime/", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
			_setValueUnchecked("impact4.runtime.loadingPrefix", "", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
		}

		
		// Create the values for the back/front buttons
		_setValueUnchecked("impact4.runtime.nextClicked", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);
		_setValueUnchecked("impact4.runtime.backClicked", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

		// set the defaults
		setRuntimeDefaults();

		// Load the interface
		interfaceClip.loadMovie(_getValue("runtime.loadingPrefix") + "interface.swf");
		interfaceClip._alpha = 0;
		
		// Load the preloader
		i4Preloader.loadMovie(_getValue("runtime.loadingPrefix") + "i4preloader.swf");

		// Load the navigation
		navigation.loadMovie(_getValue("runtime.loadingPrefix") + "navigation.swf");

		// Set i4Admin Depth and Listener.
		i4Admin.swapDepths(_level9999996);
		
		
		keysDownArray = new Array();
		var i4AdminKeyListener:Object = new Object();
		i4AdminKeyListener.onKeyDown = function () {
			currentKeyDown = Key.getAscii();
			currentKeyDown = String.fromCharCode(currentKeyDown.toString());
			if (currentKeyDown=="i" || currentKeyDown=="I") {
				keysDownArray.push("i");
			}
			if (currentKeyDown=="4") {
				keysDownArray.push("4");
			}
			if (currentKeyDown=="a" || currentKeyDown=="A")  {
				keysDownArray.push("a");
			}
			
			if ( inArray("i",keysDownArray) && inArray("4",keysDownArray) && inArray("a",keysDownArray) ) {
				i4Admin.swapDepths(1999999);
				i4Admin._visible = true;
				i4Admin.gotoAndPlay(1);
				
			}
		}
		i4AdminKeyListener.onKeyUp = function () {
			keysDownArray = null;
			keysDownArray = new Array();
		}
		Key.addListener(i4AdminKeyListener);

		// now perform the second part of the init
		// Note: Flash AS truely lacks some necessary functionaly (e.g. sleeping, mutlithreading)
		// and also XML.load is an asynchronous method, which means that I can't wait for the load
		// to finish, so what the result is, our code path jumps into the XML load handler

		// Why is this bad? It's really a issue in design, because now we don't have all of our
		// Init code in a good and nice place; now it's jumping between threads, etc.
		initImpact4Configuration("configuration");
	}
}

function inArray (searchKey, searchArray) {
	found = false;
	for (j=0; j<searchArray.length; j++) {
		if (searchArray[j] == searchKey) {
			found = true;
			break;
		}
	}
	return found;
}

function posInArray (searchKey, searchArray) {
	found = false;
	for (j=0; j<searchArray.length; j++) {
		if (searchArray[j] == searchKey) {
			found = j;
			break;
		}
	}
	return found;
}

// sets up a bunch of default properties that are user overrideable
function setRuntimeDefaults()
{
	// Create the default preloader buffering percentages
	_setValueUnchecked("impact4.configuration.defaultModemBuffer", 100, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);
	_setValueUnchecked("impact4.configuration.defaultIsdnBuffer" , 100, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);
	_setValueUnchecked("impact4.configuration.defaultCableBuffer", 100, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);

	// by default we don't validate the XML
	_setValueUnchecked("impact4.configuration.checkXMLValidity", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we do not trace every setValue
	_setValueUnchecked("impact4.configuration.traceSetValue", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we do not dump the database at the end of init
	_setValueUnchecked("impact4.configuration.dumpDatabaseBeforeNavigation", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we have garbage collection on
	_setValueUnchecked("impact4.configuration.enableGarbageCollection", true, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we predict/cache navigation (NOT ENFORCED)
	_setValueUnchecked("impact4.configuration.enableNavigationCache", true, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we create 64 bit UniqueNames
	_setValueUnchecked("impact4.configuration.uniqueNameSize", 64, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);

	// by default we remove linear tags after random tags are resolved
	_setValueUnchecked("impact4.configuration.enableLinearRemoval", true, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we don't preload metadata
	_setValueUnchecked("impact4.configuration.preloadMetadata", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default a blank section text
	_setValueUnchecked("impact4.runtime.sectionText", "", true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_STRING);

	// by default we have the system volumes at 100
	_setValueUnchecked("impact4.configuration.currentVolume", 100, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);
	_setValueUnchecked("impact4.configuration.systemVolume", 100, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);

	// by default we don't trace to console
	_setValueUnchecked("impact4.configuration.traceToConsole", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we enable the progress bar
	_setValueUnchecked("impact4.configuration.showProgressBar", true, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default we enable the auto progress bar update
	_setValueUnchecked("impact4.configuration.calculateProgressBar", true, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

	// by default the preloader interval is 250ms
	_setValueUnchecked("impact4.configuration.preloaderInterval", 250, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_STRING);

	// by default we don't display secure socket commands to the console
	_setValueUnchecked("impact4.configuration.xmlSocketTraceSecure", false, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_BOOLEAN);

}

// sets any overrides that we may have
function setOverrides()
{
	// Thanks to FlashCoders wiki for this one: http://chattyfig.figleaf.com/flashcoders-wiki/index.php?onLoad
	// defining a function to store handlers in our global list
	MovieClip.prototype.addOnLoadHandler = function(path, func)
	{
		if (MovieClip._onLoadHandler_ == undefined)
		{
			MovieClip._onLoadHandler_ = {};
		}	
		MovieClip._onLoadHandler_[path] = func;	
	}

	//hide it
	ASSetPropFlags(MovieClip, ["addOnLoadHandler"], 1);

	 //define getter/setter functions for onLoad
	sol = function (func) { addOnLoadHandler(this, func);};
	gol = function () { return MovieClip._onLoadHandler_[this];};
	MovieClip.prototype.addProperty("onLoad", gol, sol);

	// give a generic st function so that all ST's will
	// work regardless if console is loaded or not
	if(typeof(_global.st) == "undefined")
	{
		_global.st=function(s){trace(s);};
	}
}

_global.st=function(s){trace(s);};

// Gets an array of all the running modules (i.e. currentModules)
// includeNonModules -- boolean, optional, weather or not to include modules other than MODULE_TYPE_MODULE
_global.getCurrentModules = function(includeNonModules)
{
	var allKeys = getKeyNames("lifeCycleState");
	var currentModules = new Array(); //runtime is always there
	var moduleState;
	var moduleInstanceOf;
	var moduleType;

	if(includeNonModules == "" || includeNonModules == null || typeof(includeNonModules) == "undefined")
		includeNonModules = false;

	for(var i = 0; i < allKeys.length; i++)
	{
		moduleState = _getValue(allKeys[i]);
		moduleInstanceOf = _getValue(allKeys[i].substring(0, allKeys[i].length-".lifeCycleState".length) + ".moduleType");
		moduleType = _getValue("impact4.modules." + moduleInstanceOf + ".type");

		// to see if this is in a running state and it is MODULE_TYPE_MODULE
		if(moduleState == MODULE_LIFECYCLE_RUNNING ||
		   moduleState == MODULE_LIFECYCLE_RUNNINGFINALIZABLE)
		{
			if(includeNonModules || moduleType == MODULE_TYPE_MODULE)
				currentModules.push(allKeys[i].split(".")[1]);
		}
	}

	// there were no current modules, thus the only thing left is the runtime
	if(currentModules.length == 0)
		currentModules.push("runtime");

	return currentModules;
}

// transforms a XML module name into it's systemlevel name
// you should only need to use this if you're interacting with the XML directly
_global.userModuleToSystem = function(module)
{
	var newName = _getValue("impact4." + module + ".alias");
	//st("userModuleToSystem: passed " + module + " to " + newName);
	return newName;
}

// 0.0.24: the event handler for the runtime
_global.runtimeEventHandler = function(event, text)
{
	st("runtime: received event number " + event + " with data " + text);
	if(event == EVENT_NAVIGATION_SET)
	{
		if(text == "impact4.runtime.sectionText")
		{
			// to be the most correct, we should forward this event to interface and let it deal with it
			// that way interface can expose a nice and clean layer that is interface neutral
			/*st("runtime: interface type is " + typeof(interface));
			st("lasjf " + typeof(interfaceClip.setCurrentSection));
			interfaceClip.setCurrentSection(_getValue(text));*/

			// 0.0.25: There seems to be a bug in Flash that lets it resolve
			// the interface clip correctly, but the function setCurrentSection
			// disappears after the 1st call or in some context
			// thus, we directly set the text
			interfaceClip.currentSectionText = _getValue(text);
		}
	}
}

// send an event to modules (either a single module or an array)
// set modules[0]="runtime" to raise a runtime event
// set modules[0]="navigation" to raise a navigation event
// changed from "text" to "passedObject", since text is a reserved word.
_global.sendEventToModules = function(modules, event, passedObject)
{
	var thisModule;
	var i;

	if(typeof(modules) == "string")
		modules = new Array(modules);

	for(i = 0; i < modules.length; i++)
	{
		st("sendEventToModules: sending " + modules[i] + " event " + event + " " + passedObject);

		if(modules[i] == "runtime")
		{
			runtimeEventHandler(event, passedObject);
		}
		else if(modules[i] == "navigation")
		{
			navigation.eventHandler(event, passedObject);
		}
		else if(modules[i] == "loader")
		{
			loaderEventHandler(event, passedObject);
		}
		else if(modules[i] == "interface")
		{
			interfaceEventHandler(event, passedObject);
		}
		else
		{
			thisModule = eval(userModuleToSystem(modules[i]));
			if(typeof(thisModule) != "undefined")
			{
				thisModule.eventHandler(event, passedObject);
			}
		}
	}
	
	// 0.1.28: now send the events to all libraries
	for(i = 0; i < _currentLoadedLibraries.length; i++)
	{
		_currentLoadedLibraries[i].eventHandler(event, passedObject, modules);
	}
	// 0.2.34: treat interface like a library
	interfaceClip.eventHandler(event, passedObject, modules);

}

// registers a new system level event
_global.registerNewEvent = function(name)
{
	// first validate the event's name
	var nameSplit = name.split("_");
	if(nameSplit.length != 3)
		return false;
	if(nameSplit[0] != "EVENT")
		return false;

	// make sure we don't re-reg the same event
	if(typeof(eval("_global." + name)) != "undefined")
		return false;

	set("_global." + name, ++EVENT_BASE_LASTNUMBER);
	st("registerNewEvent: " + name + " registered with number " + EVENT_BASE_LASTNUMBER);
	return true;
}

// allocate a new safe Flash level
_global.allocNewLevel = function(base)
{
	if(typeof(base) == "undefined")
		base = 0;
	
	return (_global._internalDBLevelCounter++) + base;
}

// spits back a string of system status info
_global.runtimeStatus = function(traceStatus)
{
	var retVal = "";
	
	retVal += _internalDB.Version + "\n";
	retVal += "MAL: " + _global._internalDB.ModuleAliasLookup + "\n";
	retVal += "LH: " + _global._internalDB.LoadHistory + "\n";
	retVal += "VC: " + _global.visitedConditions + "\n";
	retVal += "CLM: " + _global._currentLoadedModules + "\n";
	retVal += "CLL: " + _global._currentLoadedLibraries + "\n";
	retVal += "LC: " + _global._internalDBLevelCounter + "\n";
	retVal += "IML: " + _global._internalModuleList + "\n";
	retVal += "EBLN: " + EVENT_BASE_LASTNUMBER + "\n";
	retVal += "XmlSocket CXN: " + _XmlSocketClient.isConnected;


	st(retVal);

	return retVal;
}

/****** LOCAL SUPPORT WORK ******/

// Inits the console and adds in any support functions needed
function initConsole()
{
	console.initConsole();
/*	console.addFunction("sendurlmanifest", urlClient, "Sends manifests to a URL.", "Sends all the CacheManager manifests to a URL specified in the Xml.");
	console.addFunction("xmlsocketconnect", XmlSocketClient.Connect, "Connect to a socket.", "Connects the XmlSocketClient to the parameters specified in the Xml.");
	console.addFunction("xmlsocketdisconnect", XmlSocketClient.Disconnect, "Disconnect from a socket.", "Disconnects from a previously connected socket.");
	console.addFunction("sendxmlsocketmanifest", XmlSocketClient.SendManifest, "Sends manifests to a socket.", "Sends all the CacheManager to an open socket.");
	console.addFunction("writemanifest", _cacheManager.writeManifest, "Write the data to disk", "Calls the CacheManager to write the entire in-memory database to disk.");
*/	
}

// Makes a n - bit unique number number
function makeGUID()
{
	make32Bits = function()
	{
		/*var theDate = new Date();
		var rand = Math.random(		theDate.getUTCMilliseconds()*
						(SharedObject.getSize()+1)  *
						(theDate.getUTCMonth+1)     *
						theDate.getUTCDate()        *
						theDate.getUTCMinutes()     *
						theDate.getUTCHours()       *
						theDate.getUTCFullYear());
		var theValue = rand*Math.pow(2,31)+theDate.getUTCMilliseconds();
		var theGUID = theValue.toString(16).toUpperCase();*/

		var theGUID = LERandom.nextInt(2147483648).toString(16).toUpperCase();

		// Need to Have a 32 bits filled
		// Need to have a Postive value
		if(theGUID.length != 8 /*|| theValue <= 0*/)
			return make32Bits();
		else
			return theGUID;
	}
	var guidSize = _getValue("configuration.uniqueNameSize");
	if(guidSize == 32)
		return make32Bits();
	else if(guidSize == 96)
		return make32Bits() + "-" + make32Bits() + "-" + make32Bits();
	else if(guidSize == 128)
		return make32Bits() + "-" + make32Bits() + "-" + make32Bits() + "-" + make32Bits();
	else
		return make32Bits() + "-" + make32Bits();
}

// parses the configuration XML
function parseConfigurationXML()
{
	var i4XML = null;
	var configXML = null;
	var navigationXML = null;
	var i = 0;
	
	// first we need to find our impact4 tag to start from
	for(i = 0; i < this.configXML.childNodes.length; i++)
		if(this.configXML.childNodes[i].nodeName == "impact4")
		{
			i4XML = new XML();
			i4XML = this.configXML.childNodes[i];
		}
	if(i4XML == null)
	{
		st("runtime[parseConfigurationXML]: ERROR -- impact4 tag not found in configuration.xml");
		return;
	}
	
	// now we'll break it down into the config and navigation tags
	for (i = 0; i < i4XML.childNodes.length; i++)
	{
		if(i4XML.childNodes[i].nodeName == "configuration")
		{
			configXML = new XML();
			configXML = i4XML.childNodes[i];
		}
		else if(i4XML.childNodes[i].nodeName == "navigation")
		{
			navigationXML = new XML();
			navigationXML = i4XML.childNodes[i];
		}
	}
	
	if(configXML == null)
	{
		st("runtime[parseConfigurationXML]: ERROR -- impact4/configuration tag not found in configuration.xml");
		return;
	}
	else if(navigationXML == null)
	{
		st("runtime[parseConfigurationXML]: ERROR -- impact4/navigation tag not found in configuration.xml");
		return;
	}

	// However, we do care about configuration, so let's pass it along to a helper function
	parseConfigureTag(configXML);
	st("runtime: parseConfigureTag finished at " + getTimer());

	// Load any modules if we found any
	var modulesMetaData = getKeyNames(".modules.");
	var libsToLoad = new Array();
	for(i = 0; i < modulesMetaData.length; i++)
	{
		if(modulesMetaData[i].indexOf(".type") > 0)
		{
			if(_getValue(modulesMetaData[i]) == MODULE_TYPE_LIBRARY)
			{

				libsToLoad.push(modulesMetaData[i].split(".")[2]);
			}
		}
	}
	st("runtime: queuing " + libsToLoad.length + " libraries to load");

	// 0.1.27: changed library load behavior to be lazy
	//if(libsToLoad.length > 0)
		//i4Load(libsToLoad, loadingTarget);
	for(i = 0; i < libsToLoad.length; i++)
		itemsToLoad[i] = libsToLoad[i];


	// Pre-process the navigation tag
	// Get the return value because parseNavigationTag will have named things for us and perhaps resolved random's
	navigationXML = parseNavigationTag(navigationXML);
	
	// Since we don't care about nav right now we're gonna stuff the navigation xml into the DB
	_setValueUnchecked("impact4.runtime.navigation", navigationXML, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_OBJECT);
}


// Recursivly finds all the modules we need and sets up their basics
// xml -- the xml to parse
// setOnlyConstants -- will only parse constants
// parseThisTag -- will parse what's given in XML, but not its children
_global.loadMetadataFromXml = function (xml, setOnlyConstants, parseThisTag)
{
	var i = 0;
	var j = 0;
	var k = 0;

	var retStr = "";
	var fieldList;
	for(i = 0; (i < xml.childNodes.length) || parseThisTag; i++)
	{
		// if we're only parsing this tag, XML is what to load, otherwise use the childnodes
		if(parseThisTag)
			fieldList = xml;
		else
			fieldList = xml.childNodes[i];

		if(fieldList.nodeName == "module")
		{
			moduleName = fieldList.attributes.name;
			
			// set all constants
			for(j = 0; j < fieldList.childNodes.length; j++)
				if(fieldList.childNodes[j].nodeName == "const")
				{
					if(fieldList.childNodes[j].attributes.type != "composite")
					{
						if(fieldList.childNodes[j].attributes.type == "cdata")
							_setValueUnchecked("impact4." + moduleName +
								 "." + fieldList.childNodes[j].attributes.name,
								 fieldList.childNodes[j].firstChild.nodeValue,
								 true,
								 DB_FIELDACCESS_CONSTANT,
								 mapTextToFieldType("string"));

						else
							_setValueUnchecked("impact4." + moduleName +
								 "." + fieldList.childNodes[j].attributes.name,
								 fieldList.childNodes[j].attributes.value,
								 true,
								 DB_FIELDACCESS_CONSTANT,
								 mapTextToFieldType(fieldList.childNodes[j].attributes.type));
					}
					else
					{
						// 0.2.34: added composite top level placeholder var
						_setValueUnchecked("impact4." + moduleName +
							 "." + fieldList.childNodes[j].attributes.name,
							 null,
							 true,
							 DB_FIELDACCESS_CONSTANT,
							 mapTextToFieldType(fieldList.childNodes[j].attributes.type));

						for(element in fieldList.childNodes[j].childNodes)
						{
							_setValueUnchecked("impact4." + moduleName +
								 "." + fieldList.childNodes[j].attributes.name + "." + fieldList.childNodes[j].childNodes[element].attributes.name,
								 fieldList.childNodes[j].childNodes[element].attributes.value,
								 true,
								 DB_FIELDACCESS_CONSTANT,
								 mapTextToFieldType(fieldList.childNodes[j].childNodes[element].attributes.type));
						}
					}
				}
				// add the user writable datatypes
				else if(fieldList.childNodes[j].nodeName == "field" && ! setOnlyConstants)
				{
					// Add the data fields for each of the modules
					createDataField(	moduleName + "." +  fieldList.childNodes[j].attributes.name,
								fieldList.childNodes[j].attributes.initialValue,
								fieldList.childNodes[j].attributes.type);
								
					/*_setValueUnchecked("impact4." + moduleName + "." +  fieldList.childNodes[j].attributes.name,
							(typeof(fieldList.childNodes[j].attributes.initialValue) == "undefined") ? "" : fieldList.childNodes[j].attributes.initialValue,
							true,
							DB_FIELDACCESS_READWRITE,
							mapTextToFieldType(fieldList.childNodes[j].attributes.type));*/
				}

			// set the module type
			_setValueUnchecked("impact4." + moduleName + ".moduleType", fieldList.attributes.type, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);

			if(! setOnlyConstants)
			{
				// if the module wants to autoadvance, set it's flag to allow it to
				if(fieldList.attributes.autoAdvance == "true")
					_setValueUnchecked("impact4." + moduleName + ".autoAdvance", "true", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
				else if(fieldList.attributes.autoAdvance == "skiponback")
					_setValueUnchecked("impact4." + moduleName + ".autoAdvance", "skiponback", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
				else
					_setValueUnchecked("impact4." + moduleName + ".autoAdvance", "false", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
	
				// if the module wants not to have the interface show
				if(fieldList.attributes.noInterface == "true")
					_setValueUnchecked("impact4." + moduleName + ".noInterface", true, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);
				else
					_setValueUnchecked("impact4." + moduleName + ".noInterface", false, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);
	
				// 0.1.28 get the x and y values
				// 0.1.40? (ss) get the scale and layer values
				if(typeof(fieldList.attributes.x) != "undefined")
					_setValueUnchecked("impact4." + moduleName + ".x", fieldList.attributes.x, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);
				if(typeof(fieldList.attributes.y) != "undefined")
					_setValueUnchecked("impact4." + moduleName + ".y", fieldList.attributes.y, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);
				if(typeof(fieldList.attributes.scale) != "undefined")
					_setValueUnchecked("impact4." + moduleName + ".scale", fieldList.attributes.scale, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);
				if(typeof(fieldList.attributes.level) != "undefined")
					_setValueUnchecked("impact4." + moduleName + ".level", fieldList.attributes.level, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);
	
	
				// set the module's "i'm done" flag to calse
				_setValueUnchecked("impact4." + moduleName + ".lifeCycleState", MODULE_LIFECYCLE_UNLOADED, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);
				
				// sets the default frame target label			
				if(typeof(fieldList.attributes.startLabel) != "undefined")
					_setValueUnchecked("impact4." + moduleName + ".startLabel", fieldList.attributes.startFrameLabel, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
				else
					_setValueUnchecked("impact4." + moduleName + ".startLabel", "start", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
	
				// add a property to the module saying that what it's link name is
				_setValueUnchecked("impact4." + moduleName + ".alias", moduleName, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_STRING);
	
				// write it to the metadata if it doens't exist already
				if(typeof(_getValue("impact4.modules." + fieldList.attributes.type + ".type")) == "undefined")
				{
					_setValueUnchecked("impact4.modules." + fieldList.attributes.type + ".type",
						 MODULE_TYPE_MODULE,
						 true,
						 DB_FIELDACCESS_CONSTANT,
						 DB_TYPE_INTEGER);
					_setValueUnchecked("impact4.modules." + fieldList.attributes.type + ".fileName",
						 fieldList.attributes.type + ".swf",
						 true,
						 DB_FIELDACCESS_CONSTANT,
						 DB_TYPE_STRING);
					// 0.1.28: allow disabling of GC
					if(_getValue("impact4.configuration.enableGarbageCollection"))
						_setValueUnchecked("impact4.modules." + fieldList.attributes.type + ".refCounter",
							 0,
							 true,
							 DB_FIELDACCESS_SYSTEMWRITEONLY,
							 DB_TYPE_INTEGER);
	
					// update the manifest with this unique module, and save it
					var manifest = _getValue("runtime.moduleManifest");
					manifest.push(fieldList.attributes.type);
					_setValue("runtime.moduleManifest", manifest);
				}
	
				// 0.1.28: allow disabling of GC
				if(_getValue("impact4.configuration.enableGarbageCollection"))
					// 0.0.23: increment the usage counter on the module type
					_setValue("impact4.modules." + fieldList.attributes.type + ".refCounter", _getValue("modules." + fieldList.attributes.type + ".refCounter") + 1);
			}
	
			// parse only this tag if needed
			if(parseThisTag)
				break;

			if(fieldList.childNodes.length > 0)
				loadMetadataFromXml(fieldList);

		}
		else if(fieldList.nodeType == 1)
			if(fieldList.childNodes.length > 0)
				loadMetadataFromXml(fieldList);
	}
}


function createDataField(unscopedName, initialValue, dataType)
{
	_setValueUnchecked("impact4." + unscopedName,
			(typeof(initialValue) == "undefined") ? "" : initialValue,
			true,
			DB_FIELDACCESS_READWRITE,
			mapTextToFieldType(dataType));
}

// decides which navigatin to use, uses user set configuratin.navType as priority
// NOTE: this does not stop a user from making a mistake, e.g. setting simple in a complex nav
function decideNavigation(theXML)
{
	var setNav = _getValue("configuration.navType");
	var useSimple = true;
	if(setNav != "simple" && setNav != "full")
	{
		for(var i = 0; i < theXML.childNodes.length; i++)
			if(theXML.childNodes[i].nodeName != "module" || theXML.childNodes[i].nodeName != "group")
			{
				useSimple = false;
				break;
			}
		if(useSimple)
			_setValueUnchecked("impact4.configuration.navType", "simple", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);			
		else
			_setValueUnchecked("impact4.configuration.navType", "full", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
	}
}

// Pre-parses the navigation tag
function parseNavigationTag(navXML)
{
	st("runtime: entered parseNavigationTag at " + getTimer());

	// decide which navigation to use
	decideNavigation(navXML);

	// name any anonymous modules and name all <condition> tags
	st("runtime: calling nameAnonymousTags at " + getTimer());
	_global.nameAnonymousTagsCounter = 0;
	navXML = nameAnonymousTags(navXML);
	delete _global.nameAnonymousTagsCounter;

	// resolve any random tags if we need to
	if(_getValue("configuration.navType") == "full")
	{
		st("runtime: since navType == full, attempted resolveRandomTags at " + getTimer());
		navXML = resolveRandomTags(navXML); // a function in navigation.as

		if(_getValue("configuration.enableLinearRemoval"))
		{
			st("runtime: removing linear tags at " + getTimer());
			navXML = removeLinearTags(navXML); // a function in navigation.as
		}

		st("runtime: since navType == full, attempted resolveConditionTags at " + getTimer());
		navXML = resolveConditionTags(navXML); // a function in navigation.as

		// 0.2.34: check the property
		if (_getValue("configuration.calculateProgressBar"))
		{		
			st("runtime: calculateCodePaths beign called at "+ getTimer());
			calculateCodePaths(navXML);
		}
	}

	// create our manifest variable
	_setValueUnchecked("impact4.runtime.moduleManifest", new Array(), true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_OBJECT);

	// parse the module tags and build the module manifest
	if(_getValue("configuration.preloadMetadata") == true)
		loadMetadataFromXml(navXML);

	return navXML;
}

// names all anonymous module,condition, group, and linear tags
function nameAnonymousTags(nameXML, depthLevel)
{
	var i = 0, j = 0;
	var retStr = "";
	var newName;
	var instanceType, instanceName;
	var linkFound = false;

	// to ensure we have unique names at all depths of the recursion
	if(typeof(depthLevel) == "undefined")
		depthLevel = 1;

	for(i = 0; i < nameXML.childNodes.length; i++)
	{
		if(	nameXML.childNodes[i].nodeName == "module" ||
			nameXML.childNodes[i].nodeName == "condition" ||
			nameXML.childNodes[i].nodeName == "group" ||
			nameXML.childNodes[i].nodeName == "linear" ||
			nameXML.childNodes[i].nodeName == "true" ||
			nameXML.childNodes[i].nodeName == "false" )
		{
			instanceType = nameXML.childNodes[i].attributes.type;
			instanceName = nameXML.childNodes[i].attributes.name;
//			newName = nameXML.childNodes[i].nodeName + depthLevel + (getTimer() * (i+1));
			newName = nameXML.childNodes[i].nodeName + nameAnonymousTagsCounter;
			nameAnonymousTagsCounter++;

			// 0.0.20: if it's a module (and not anonymous), then add it to the alias table
			if(nameXML.childNodes[i].nodeName == "module" && typeof(instanceName) != "undefined") 
			{
				// create the link lookup
				_global._internalDB.ModuleAliasLookup[newName] = instanceName;
				nameXML.childNodes[i].attributes.alias = instanceName;

				// now give it a unique name
				nameXML.childNodes[i].attributes.name = newName;
			}
			else // otherwise just name it 
			{
				// name this tag
				nameXML.childNodes[i].attributes.name = newName;
			}
			nameXML.childNodes[i] = nameAnonymousTags(nameXML.childNodes[i], depthLevel++);
		}
		else if(nameXML.childNodes[i].nodeType == 1)
			nameXML.childNodes[i] = nameAnonymousTags(nameXML.childNodes[i], depthLevel++);
	}

	return nameXML;
}

// Parse the data tag from the configuration xml
function parseConfigureDataTag(xml)
{
	if(xml.attributes.writeToManifest == "true")
	{
		_setValueUnchecked("impact4.configuration.writeToManifest", true, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);
		
		// if the XML says to write to the manifest, we need to make sure to update the manifest table
		_cacheManager.createManifestEntry();
	}
	else
		_setValueUnchecked("impact4.configuration.writeToManifest", false, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);

	// Disabled since i4Server 1.0 has been shut down.  Hard-wired for i4Server 2.0.
/*	if(xml.firstChild.nodeName == "xmlsocketclient")
	{
		_XmlSocketClient.init(xml.firstChild.attributes.server, xml.firstChild.attributes.port, xml.firstChild.attributes.outputLayer);
		if(xml.firstChild.attributes.connectNow == "true")
			_XmlSocketClient.connect();

		// if you specify to have the XmlSocketclient, the connect is implicit
		_setValueUnchecked("impact4.configuration.dataClient", "xmlsocket", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
	}
	else if(xml.firstChild.nodeName == "urlclient")
	{
		_UrlClient.Init(xml.firstChild.attributes.targetUrl, xml.firstChild.attributes.outputLayer);
		_setValueUnchecked("impact4.configuration.dataClient", "url", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
	}
*/	
	_UrlClient.Init(xml.firstChild.attributes.targetUrl, xml.firstChild.attributes.outputLayer);
	_setValueUnchecked("impact4.configuration.dataClient", "url", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);	
//	_setValueUnchecked("impact4.configuration.dataClient", "ajax", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);			
	// TODO: AJAX init

	// see if any field tags are explicitly present
	for(var i = 0; i < xml.childNodes.length; i++)
	{
		if(xml.childNodes[i].nodeName == "field")
			// Add the data fields for each of the modules
			createDataField(	xml.childNodes[i].attributes.name,
						xml.childNodes[i].attributes.initalValue,
						xml.childNodes[i].attributes.type);

	}

	// they've supplied us with a project name, cachemanager will want to know
	if(typeof(xml.attributes.projectName) != "undefined")
	{
		_setValueUnchecked("impact4.configuration.projectName", xml.attributes.projectName, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
	}
}

// Reads out the configuration data to the DB
function parseConfigureTag(xml)
{
	var i = 0;
	var j = 0;
	
	for(i = 0; i < xml.childNodes.length; i++)
	{
		var theNodesName = xml.childNodes[i].nodeName;
		// the data section 
		if(theNodesName == "data")
		{
			parseConfigureDataTag(xml.childNodes[i]);
		}
		// description of avaliable help files
		else if(theNodesName == "help")
		{
			_setValueUnchecked("impact4.modules." + xml.childNodes[i].attributes.module + ".help", xml.childNodes[i].attributes.filename, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
		}
		// any libarires that the config wants to load
		else if(theNodesName == "library")
		{
			_setValueUnchecked("impact4.modules." + xml.childNodes[i].attributes.name + ".fileName", xml.childNodes[i].attributes.name + ".swf", true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
			_setValueUnchecked("impact4.modules." + xml.childNodes[i].attributes.name + ".type", MODULE_TYPE_LIBRARY, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);

			// a library also get's ONE default field that it can write to
			_setValueUnchecked("impact4." + xml.childNodes[i].attributes.name + ".libraryData", new Object(), true, DB_FIELDACCESS_READWRITE, DB_TYPE_OBJECT);

			// it also has a lifeCycleState, that nobody should really care about
			// we keep it for consistancy's sake with a regular module
			_setValueUnchecked("impact4." + xml.childNodes[i].attributes.name + ".lifeCycleState", MODULE_LIFECYCLE_UNLOADED, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_INTEGER);

			// also give it a .type in the instance namespace so we have a
			// pointer back to the metadata if we treat it like a regualr module
			_setValueUnchecked("impact4." + xml.childNodes[i].attributes.name + ".moduleType", xml.childNodes[i].attributes.name, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_STRING);

			// we also give it an alias variable
			_setValueUnchecked("impact4." + xml.childNodes[i].attributes.name + ".alias", xml.childNodes[i].attributes.name, true, DB_FIELDACCESS_SYSTEMWRITEONLY, DB_TYPE_STRING);
		}
		// process the different properites
		else if(theNodesName == "property")
		{
			var oldValue = _getValue("configuration." + xml.childNodes[i].attributes.name);
			st("runtime[parseConfigureTag] setting " + xml.childNodes[i].attributes.name + " to " + xml.childNodes[i].attributes.value);

			if(typeof(oldValue) == "undefined")
				_setValueUnchecked(	"impact4.configuration." + xml.childNodes[i].attributes.name,
						xml.childNodes[i].attributes.value,
						true,
						DB_FIELDACCESS_SYSTEMWRITEONLY,
						mapTextToFieldType(xml.childNodes[i].attributes.type));
			else // means somebody set this earlier, so we have to overwrite it with the other setval
				_setValue(	"configuration." + xml.childNodes[i].attributes.name,
						xml.childNodes[i].attributes.value);
		}
		// the display options
		else if(theNodesName == "display")
		{
			if(typeof(xml.childNodes[i].attributes.allowBack) != "undefined")
				_setValueUnchecked("impact4.configuration.allowBack", xml.childNodes[i].attributes.allowBack, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);
			else
				_setValueUnchecked("impact4.configuration.allowBack", true, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);

			if(typeof(xml.childNodes[i].attributes.allowQuit) != "undefined")
				_setValueUnchecked("impact4.configuration.allowQuit", xml.childNodes[i].attributes.allowQuit, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);
			else
				_setValueUnchecked("impact4.configuration.allowQuit", true, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_BOOLEAN);

			fieldList = new XML();
			fieldList = xml.childNodes[i];
			for(j = 0; j < fieldList.childNodes.length; j++)
			{
				if(fieldList.childNodes[j].nodeName == "font")
				{
					_setValueUnchecked("impact4.configuration.font.size", fieldList.childNodes[j].attributes.size, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
					_setValueUnchecked("impact4.configuration.font.face", fieldList.childNodes[j].attributes.face, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
				}
				else if(fieldList.childNodes[j].nodeName == "screen")
				{
					_setValueUnchecked("impact4.configuration.screen.height", fieldList.childNodes[j].attributes.height, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);
					_setValueUnchecked("impact4.configuration.screen.width", fieldList.childNodes[j].attributes.width, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_INTEGER);
				}
				else if(fieldList.childNodes[j].nodeName == "titlebar")
					_setValueUnchecked("impact4.configuration.titlebar", fieldList.childNodes[j].attributes.text, true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
			}
		}
	}
}

/*
Does some basic checks to make sure of things, such as:
1. Every i4.data.field.instanceOwner matches a module.instance
2. Every i4.modules.*.filename exists
3. Every i4.modules.*.help has a i4.modules.*.filename
	(e.g. make sure there is no tag for a help module that doesn't have a module instansiated)
4. Ensure every module name is less than 32 characters (Flash limit)
5. Ensure all tags have their proper containing tags
*/
function validateConfiguration()
{
	var i;
	var middleLevel;
	// 1. Validate Instance Owners
	moduleKeys = getKeyNames("impact4.");
	for(i = 0; i < moduleKeys.length; i++)
	{
		middleLevel = moduleKeys[i].split(".")[1];
		// trap the system namespaces
		if(middleLevel != "configuration" &&
		   middleLevel != "runtime" &&
		   middleLevel != "modules")
			// trap system added data fields
			if(moduleKeys[i].indexOf("autoAdvance") == -1 && moduleKeys[i].indexOf("moduleType") == -1)
				// we're a user <field>, now we need to check i4.moduleName.moduleType
				if(typeof(_getValue(middleLevel + ".moduleType")) == "undefined")
					st("runtime[validateConfiguration]: ERROR -- Field tag in impact4/configuration/data defined that does not have a matching module instance (" + middleLevel + ")");
	}
	
	// 2. Check the help tags
	moduleKeys = getKeyNames("impact4.modules");
	for(i = 0; i < moduleKeys.length; i++)
	{
		if(moduleKeys[i].substring(moduleKeys[i].length-5) == ".help")
			// we found a help, now check to make sure this module has been used
			if(typeof(_getValue(moduleKeys[i].substring(0,moduleKeys[i].length-5) + ".fileName")) == "undefined")
				st("runtime[validateConfiguration]: ERROR -- Help tag in impact4/configuration without instance of module in navigation (" + moduleKeys[i] + ")");
	}

	// 4. Ensure modName < 32
	moduleKeys = getKeyNames("impact4.");
	for(i = 0; i < moduleKeys.length; i++)
	{
		middleLevel = moduleKeys[i].split(".")[1];
		if(middleLevel.length >= 32)
			st("runtime[validateConfiguration]: WARNING -- " + middleLevel + " is larger than 32 characters. This may cause errors in some FLash Players");
	}

	// 5. Ensure all tags have their proper containing tags
	validateTagOwnership(_getValue("runtime.navigation"));
}

// tag validator checks 
function validateTagOwnership(theXML)
{
	for(var i = 0; i < theXML.childNodes.length; i++)
	{
		var theChild = theXML.childNodes[i];
		var j;
		for(j = 0; j< theChild.childNodes.length; j++)
		{
			var childName = theChild.childNodes[j].nodeName;
			var error = false;
			switch(theChild.nodeName)
			{
				case "condition":
					if(childName != "true" && childName != "false")
						error = true;
					break;
				case "group":
					if(childName != "module")
						error = true;
					break;
				case "module":
					if(childName != "field" && childName != "const")
						error = true;
					break;
				case "random":
					if(childName != "module" && childName != "group" && childName != "linear")
						error = true;
					break;
				case "navigation":
				case "linear":
				case "true":
				case "false":
					if(	childName != "group" && childName != "module"
						&& childName != "random" && childName != "linear"
						&& childName != "noop" && childName != "condition"
						&& childName != "jump" && childName != "jumplabel"
						&& childName != "jumpreturn" && childName != "stop")
						error = true;
					break;
				case "const":
					if(theChild.attributes.type != "composite")
						error = true;
					break;
				case "noop":
				case "set":
				case "jump":
				case "jumplabel":
				case "jumpreturn":
				case "field":
				case "stop":
				case "event":
					error = true;
					break;
				default:
					st("runtime[validateTagOwnership]: unknown tag " + theChild.nodeName);
			}

			if(error)
				st("runtime[validateTagOwnership]: ERROR -- " + theChild.nodeName + " cannot contain " + childName);
		}

		if(theChild.hasChildNodes())
			validateTagOwnership(theChild);
	}	
}

// This is a bit of a hack, but any way we do this, it's going to be a bit of a hack.
function loadAlternateInterface() {
	// load the user-specified interface, if there is one.
		st("runtime: loading user specified interface: " + _getValue("runtime.loadingPrefix") + "../Resources/" +  _getValue("configuration.externalInterfaceURL"));
		interfaceClip.unloadMovie();
		interfaceClip.loadMovie(_getValue("runtime.loadingPrefix") + "../Resources/" +  _getValue("configuration.externalInterfaceURL"));
}

// Takes the impact4.configuration.* data and makes it visible on the scene
function applyConfiguration()
{
	// the late load here means that any alternate interfaces have to be able to handle
	// their init on the first paint (theirs or a module's) that they recieve. 
	if ( _getValue("configuration.externalInterfaceURL")+ "" != "" ) {
		loadAlternateInterface();
	}
	interfaceClip._alpha = 100;

	// this is the super-duper init function for the interface
	st("runtime: the title should be " + _getValue("configuration.titlebar"));
	interfaceClip.initialize(false, // elementTooltipEnabled
			     _getValue("configuration.showProgressBar"), // elementProgressBarEnabled
			     true, // elementBackArrowEnabled,
			     true, // elementNextArrowEnabled,
			     true, // elementLogoClipEnabled
			     elementShellFaceEnabled,
			     false, //elementBackgroundEnabled,
			     0, // progressPercent
			     " ", // currentSectionText
			     _getValue("configuration.titlebar"), // surveyTitleText
			     shellRed,
			     shellGreen,
			     shellBlue,
			     shellColorObject,
			     backRed,
			     backGreen,
			     backBlue,
			     backColorObject);

	// 0.2.34: sending an event to interface instead of a direct call for %bar updates
	sentEventToModules("interface", EVENT_MODULE_PAINT, 0);
	
	sendEventToModules("interface", EVENT_MODULE_PAINT, (Math.floor((_internalDB.LoadHistory.length  / _global.globalMax) * 100)));
	
}

// Read through the configuration and load it in
function initImpact4ConfigXMLFileLoaded(success)
{
	if(success)
	{
		_setValue("runtime.xmlLoaded", true);
		initImpact4ConfigModulesLoad();
	}
	else
	{
		st("ERROR: XML LOAD FAILED. IMPACT4 ATTEMPTING REGRESSION.");
		initImpact4Configuration("../Controls/configuration-regression");
	}
}

// Read through the regression and load it in
function initImpact4RegressionXMLFileLoaded(success)
{
	if(success)
	{
		_setValue("runtime.xmlLoaded", true);
		initImpact4ConfigModulesLoad();
	}
	else
	{
		st("ERROR: XML REGRESSION LOAD FAILED. IMPACT4 STOPPING.");
	}
}

// Common place that gets called to load the modules.xml file
function initImpact4ConfigModulesLoad()
{
	// load the internal modules list
	modulesXML = new XML();
	modulesXML.onLoad = initImpact4ConfigModulesXMLFileLoaded;
	modulesXML.ignoreWhite = true;
	modulesXML.load(_getValue("runtime.loadingPrefix") + "../Controls/modules.xml");
}

// Read through the modules list and load it in
function initImpact4ConfigModulesXMLFileLoaded(success)
{
	if(success)
	{
		var modList = modulesXML.firstChild;
		st("runtime[ModulesXmlFileLoaded]: successfully loaded internal module list with " + modList.childNodes.length + " mods");
		for(var i = 0; i < modList.childNodes.length; i++)
		{
			_global._internalModuleList[modList.childNodes[i].attributes.name] = true;
		}
	}
	else
	{
		st("ERROR: XML MODULE LIST LOAD FAILED. IMPACT4 STOPPING.");
		_setValue("runtime.xmlLoaded", false);
	}
}

// Processes the config file via helper functions
_global.initImpact4ProcessConfig = function()
{
	st("runtime[initImpact4ProcessConfig]: called at " + getTimer());

	// parse the configuration
	parseConfigurationXML();

	// Load the console: we do it here because now the configuration is loaded
	console.loadMovie(_getValue("runtime.loadingPrefix") + "console.swf");
	initConsole();

	// Validate the configuration
	if(_getValue("configuration.checkXMLValidity"))
		validateConfiguration();

	// flag that we've finished the initing
	_setValue("runtime.initFinished", true);

	st("runtime: Init finished at " + getTimer());
}

// Function loads our event handler so we can work when the XML is loaded
// as well as loading any parameters from a querystring
function initImpact4Configuration(xmlToLoad)
{
	if(typeof(_root.i4data) != "undefined" && _root.i4data != "" && _root.i4data != null)
	{
		var rootData = _root.i4data.split("|");
		if(rootData.length % 2 != 0)
		{
			st("runtime[initImpact4Configuration]: _root.i4Data had an odd number of name versus values");
		}
		else
		{
			for(var i = 0; i < rootData.length; i = i + 2)
			{
				_setValueUnchecked("impact4.configuration.querystring." + rootData[i], rootData[i+1], true, DB_FIELDACCESS_CONSTANT, DB_TYPE_STRING);
			}
		}
	}

	configXML = new XML();	
	if(xmlToLoad == "../Controls/configuration-regression")
		configXML.onLoad = initImpact4RegressionXMLFileLoaded;
	else
		configXML.onLoad = initImpact4ConfigXMLFileLoaded;
	configXML.ignoreWhite = true;
	configXML.load(_getValue("runtime.loadingPrefix") + "../Resources/" + xmlToLoad + ".xml");
}


// The main function that is called after all of our init is done
// Loads the navigation and gets the driver frameloop going
function initImpact4Main(startNavigation)
{
	st("runtime: entered initImpact4Main at " + getTimer() + ", startNav = " + startNavigation);
	
	// Now apply the new configuration
	applyConfiguration();

	// Connect the XML socket if we need to do so	
	if(_getValue("impact4.configuration.dataClient") == "xmlsocket")
		XmlSocketClient.connect();
		
	if(startNavigation == "start")
	{
		// we should do something more fun here! :-)
		navigation.gotoAndPlay("startNavigation");
	}
	else if(startNavigation == "init")
	{
		navigation.gotoAndPlay("initNavigation");
	}
}

// takes a string based load history and a navXML and converts
// the strings to XML objects
function fixupCachedLoadHistory(navXML, lh)
{
	for(var i = 0; i < navXML.childNodes.length; i++)
	{
		var theChild = navXML.childNodes[i];
		if(theChild.nodeName == "module" || theChild.nodeName == "group")
		{
			for(var j = 0; j < lh.length; j++)
			{
				if(theChild.attributes.name == lh[j])
				{
					lh[j] = theChild;
				}
			}
		}
		if(theChild.hasChildNodes())
		{
			lh = fixupCachedLoadHistory(theChild, lh);
		}
	}
	return lh;
}
		
// now that the all the functions have been inited and read by Flash
// include the API wrapper AS file

#include "includes/api.as"

