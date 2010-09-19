/* CacheManager -- This file supports our local cache
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: cachemanager.as,v 1.15 2003/10/20 18:01:48 abansod Exp $
 */ 

// init the cachemanager
function _cacheManager_init(internalDataStructure, namespace)
{
	namespaceString = namespace;
	st("namespaceString = " + namespaceString);
	_global.sharedData = SharedObject.getLocal(namespaceString + "/manifestList");
	// if the array isn't there, set it up
	st("cachemanager: init at " + getTimer() + " " + internalDataStructure + ", " + namespace);

	_global.manifestUserData = SharedObject.getLocal(namespaceString + "/" + _internalDB.UniqueName);

	
}

// returns true if something different is in the cache
function _cacheManager_different()
{
	if(	sharedData.data.dbUniqueName != _internalDB.UniqueName &&
		sharedData.data.dbUniqueName.length == 17)
		return true;
	else
		return false;
}

// a simple search and replace function, it's in cachemanager for no particular reason
_global.searchAndReplace =function (the_string, search_string, replace_string, occurrences, backward) {
   if (search_string == replace_string) {
      return the_string;
   }
   var found = 0;
   if (backward == true) {
      var pos = the_string.lastIndexOf(search_string);
      while (pos >= 0) {
         found++;
         var start_string = the_string.substr(0, pos);
         var end_string = the_string.substr(pos + search_string.length);
         the_string = start_string + replace_string + end_string;
         pos = the_string.lastIndexOf(search_string, start_string.length);
         if (found == occurrences) {
            pos = -1;
         }
      }
   }
   else {
      var pos = the_string.indexOf(search_string);
      while (pos >= 0) {
         found++;
         var start_string = the_string.substr(0, pos);
         var end_string = the_string.substr(pos + search_string.length);
         the_string = start_string + replace_string + end_string;
         pos = the_string.indexOf(search_string, pos + replace_string.length);
         if (found == occurrences) {
            pos = -1;
         }
      }
   }
   return the_string;
}

// recommits a fullcommit based upon the database's changelog
function _cacheManager_recommitFromChangeLog()
{
	if(this.firstCommit)
	{
		st("cachemanager: recommit started at " + getTimer());

		var dirtyKey = _global._internalDBChangeLog.pop();
		var newItem, counter;

		while(dirtyKey != null)
		{
			counter++;
			newItem = searchandreplace(dirtyKey, ".", "_");
			set("sharedData.data.dbValuePairs_" + newItem, _internalDB.ValuePairs[dirtyKey]);
			set("sharedData.data.dbFieldAccess_" + newItem, _internalDB.FieldAccess[dirtyKey]);
			set("sharedData.data.dbDataTypes_" + newItem, _internalDB.DataTypes[dirtyKey]);
			set("sharedData.data.dbTimeStamp_" + newItem, _internalDB.TimeStamp[dirtyKey]);
			dirtyKey = _global._internalDBChangeLog.pop();
		}

		var result = sharedData.flush()
		st("cachemanager: recommitFromChangeLog finished at " + getTimer() + ", with " + counter + " items (" + result + ")");	
		return result;
	}
	{
		st("cachemanager: must call fullCommit before recommitFromChangeLog");
		return false;
	}
}

// does a full commit
function _cacheManager_fullCommit(noFlush)
{
// i4 Server v2.0
//	_cacheManager_createManifestEntry();
	var result = sharedData.flush()
	st("cachemanager: commit finished at " + getTimer() + " (" + result + ")");	
	return result;

// i4 Server v2.0 - disabling.  None of the below are documented, nor can I make heads or tails on why they're needed 
// in addition to the values in the individual manifests.  Disabling.  - SS 8/14/07
/*
	if(noFlush != true)
	{
		st("cachemanager: being fullCommit at " + getTimer());

		this.firstCommit = true;

		var currentMods = getCurrentModules();

		// Fake an Unload so the module saves its data
		i4Unload(currentMods, true);

		var newItem, theItem;
		var lhStringArr = new Array();

		// make the XML in loadHistory into a string
		for(var i = 0; i < _internalDB.LoadHistory.length; i++)
		{
			lhStringArr[i] = (new XML(_internalDB.LoadHistory[i])).toString();
		}
		
		// we need to set the CURRENTLY loaded module's LifeCycleState to 0
		var savedStates = new Array();
		for(var i = 0; i < currentMods.length; i++)
		{
			var theModule = eval(userModuleToSystem(currentMods[i]));
			savedStates.push(theModule.getValue("lifeCycleState"));
			theModule.setValue("lifeCycleState", MODULE_LIFECYCLE_UNLOADED);
		}
		

		sharedData.data.dbLoadHistory = lhStringArr;
		sharedData.data.dbVersion = _internalDB.Version;
		sharedData.data.dbVersionNumber = _internalDB.VersionNumber;
		sharedData.data.dbUniqueName = _internalDB.UniqueName;
		sharedData.data.dbModuleAliasLookup = _internalDB.ModuleAliasLookup;

		for(theItem in _internalDB.ValuePairs)
		{
			newItem = searchandreplace(theItem, ".", "_");
			set("sharedData.data.dbValuePairs_" + newItem, _internalDB.ValuePairs[theItem]);
			set("sharedData.data.dbFieldAccess_" + newItem, _internalDB.FieldAccess[theItem]);
			set("sharedData.data.dbDataTypes_" + newItem, _internalDB.DataTypes[theItem]);
			set("sharedData.data.dbTimeStamp_" + newItem, _internalDB.TimeStamp[theItem]);
		}

		// restore the CURRENT modules lifecycle states
		for(var i = 0; i < currentMods.length; i++)
		{
			var theModule = eval(userModuleToSystem(currentMods[i]));
			theModule.setValue("lifeCycleState", savedStates.shift());
		}

		// make the XML for the navigation into a string
		set("sharedData.data.dbValuePairs_impact4_runtime_navigation", (new XML(_internalDB.ValuePairs["impact4.runtime.navigation"])).toString());

		var result = sharedData.flush()
		st("cachemanager: commit finished at " + getTimer() + " (" + result + ")");	
		return result;
	}*/

}

// writes the current database into a manifest
function _cacheManager_writeManifest()
{
	st("cachemanager: begining writeManifest at " + getTimer() + ", saving to user location + " + _internalDB.UniqueName);
	st("manifestUserData = " + manifestUserData);

	_cacheManager.createManifestEntry();
	var currentMods = getCurrentModules();

	// Fake an Unload so the module saves its data
	i4Unload(currentMods, true);

	var newItem, theItem;

	manifestUserData.data.lcId = _root.lcId;
	manifestUserData.data.pass = _getValue("configuration.surveyPass").toString();
	manifestUserData.data.dbVersion = _internalDB.Version;
	manifestUserData.data.dbVersionNumber = _internalDB.VersionNumber;
	manifestUserData.data.dbUniqueName = _internalDB.UniqueName;
	manifestUserData.data.writeTime = (new Date()).toString();
	manifestUserData.data.projectName = _getValue("configuration.surveyName").toString();

	manifestUserData.data.dbLoadHistory = new Array();

	var loadHistNames = new Array();
	for(var i = 0; i < _internalDB.LoadHistory.length; i++)
	{
		loadHistNames[i] = _internalDB.LoadHistory[i].attributes.name;
	}
	manifestUserData.data.dbLoadHistory = loadHistNames;

	var tempVP = new Array();
	var tempTS = new Array();
	for(theItem in _internalDB.ValuePairs)
	{
		if(_internalDB.FieldAccess[theItem] == DB_FIELDACCESS_READWRITE)
		{
			tempVP[theItem] = _internalDB.ValuePairs[theItem];;
			tempTS[theItem] = _internalDB.TimeStamp[theItem];

		}
	}

	manifestUserData.data.dbValuePairs = tempVP;
	manifestUserData.data.dbTimeStamp  = tempTS;

	st("cachemanager: writemanifest finished at " + getTimer() + " (" + _cacheManager.flushManifest() + ")");
	return result;
}

// sts the status of manifests
function _cacheManager_status()
{
	st("cachemanager: local cache status report");
	var theList = _cacheManager.getManifests();
	st("cachemanager: " + theList.length + " items in the manifest");
	for(var i = 0; i < theList.length; i++)
	{
		var sendData = new LoadVars();

		var item = _cacheManager.getManifestItem(theList[i]);
		st("cachemanager: entry[" + i + "] " + item.UniqueName + " @ " + item.WriteTime);
	}
}

// writes varName from internalDB to current manifest
function _cacheManager_writeToManifest(varName)
{
	var tempVP = manifestUserData.data.dbValuePairs;
	var tempTS = manifestUserData.data.dbTimeStamp;
		
	tempVP[varName] = _internalDB.ValuePairs[varName];
	tempTS[varName] = _internalDB.TimeStamp[varName];

	manifestUserData.data.dbValuePairs = tempVP;
	manifestUserData.data.dbTimeStamp  = tempTS;
	trace("flushing manifest.");
	_cacheManager.flushManifest();
}

// flushes the cachemanager
function _cacheManager_flushManifest()
{
	var result = manifestUserData.flush();
	st("cachemanager: flush manifest " + (result ? "success" : "failure"));
	return result;
}

// Restores a manifest and process it
function _cacheManager_restoreFromManifest(item)
{
	var theMan = _cacheManager.getManifestItem(typeof(item) != "undefined" ? item : _cacheManager.getManifests()[0]);
	
	var fixedLH = fixupCachedLoadHistory(_getValue("runtime.navigation"),theMan.LoadHistory);
	_internalDB.LoadHistory = fixedLH;
	_internalDB.ValuePairs = theMan.ValuePairs;
	_internalDB.TimeStamp = theMan.TimeStamp;
	_internalDB.UniqueName = theMan.UniqueName;
	
	var topOfLH = fixedLH.pop();
	processNode(topOfLH);
}


// returns ITEM from the manifest
function _cacheManager_getManifestItem(item)
{
	var retVal = {};

	var thisDataOnly = SharedObject.getLocal(namespaceString + "/" + item);
	retVal.Version = thisDataOnly.data.dbVersion;
	retVal.VersionNumber = thisDataOnly.data.dbVersionNumber;
	retVal.UniqueName = thisDataOnly.data.dbUniqueName;
	retVal.LoadHistory = thisDataOnly.data.dbLoadHistory;
	retVal.ProjectName = thisDataOnly.data.ProjectName;
	retVal.lcId = thisDataOnly.data.lcId;
	retVal.pass = thisDataOnly.data.pass;	

	retVal.ValuePairs = thisDataonly.data.dbValuePairs;
	retVal.TimeStamp  = thisDataOnly.data.dbTimeStamp;
	
	retVal.WriteTime = thisDataOnly.data.writeTime;

	return retVal;
}

// gets the whole manifest (the list of inidvidual manifests)
function _cacheManager_getManifests()
{
//  debugging
//	_global.dataManifest = SharedObject.getLocal(namespaceString + "/dataManifest");
//	_global.dataManifest = SharedObject.getLocal(namespaceString);
	trace("sharedData.manifestList = " + sharedData.manifestList);
	var currentList = sharedData.data.manifestList;
	if(currentList == null || typeof(currentList) == "undefined")
	{
		st("cachemanager[getManifests]: there was no manifest in the dataManifest to retrieve");
		return null;
		//"cachemanager[getManifests]: there was no manifest in the dataManifest to retrieve";
	}
	else
	{
		return currentList;
	}
}

// adds this UniqueName to the manifest
function _cacheManager_createManifestEntry()
{
//	var dataManifest = SharedObject.getLocal(namespaceString + "/dataManifest");

	var currentList = sharedData.data.manifestList;
	if(currentList == null || typeof(currentList) == "undefined")
	{
		st("cachemanager[createManifestEntry]: there was no manifest in the dataManifest");
		currentList = new Array();
	}
	else
	{
		st("cachemanager[createManifestEntry]: the dataManifest contains " + currentList.length + " items");
	}
	var notInList = true;
	for(var i = 0; i <= currentList.length; i++) {
		if(currentList[i] == _internalDB.UniqueName)
		{
			st("cachemanager[createManifestEntry]: the dataManifest already contains this UniqueName");
			notInList = false;
		}
	}
	if (notInList) { 
		currentList.push(_internalDB.UniqueName);			
	}
	st("cachemanager: the Manifest is " + currentList);
	sharedData.data.manifestList = currentList;
	st("cachemanager[createManifestEntry]: flushing dataManifest (" + sharedData.flush() + ")");

}

// deletes everything in the manifest
function _cacheManager_deleteManifest()
{
//	var dataManifest = SharedObject.getLocal(namespaceString + "/dataManifest");
	var currentList = sharedData.data.manifestList;
	if(currentList == null || typeof(currentList) == "undefined")
	{
		st("cachemanager: there was no manifest in the dataManifest to delete from");
		currentList = new Array();
	}
	else
	{
		for(var i = 0 ; i < currentList.length; i++)
		{
			var thisDataOnly = SharedObject.getLocal(namespaceString + "/" + currentList.pop());
			thisDataOnly.data = null;
			thisDataOnly.flush();
		}
	}
	sharedData.data.manifestList = null;
	sharedData.flush();
}

// loads data from a full commit
function _cacheManager_loadFromFullCommit()
{

	st("cachemanager: loading data in at " + getTimer());

	var newItem, theItem;
	var arrayLessItem;

	var xmlStrings = sharedData.dbLoadHistory;
	for(var i = 0; i < xmlStrings.length; i++)
	{
		var a = new XML(xmlStrings[i]);
		a = a.firstChild;
		_internalDB.LoadHistory[i] = a;
	}
	_internalDB.Version = sharedData.dbVersion;
	_internalDB.VersionNumber = sharedData.dbVersionNumber;
	_internalDB.UniqueName = sharedData.dbUniqueName;
	_internalDB.ModuleAliasLookup = sharedData.dbModuleAliasLookup;

	for(theItem in sharedData.data)
	{
		if(theItem.indexOf("dbValuePairs_") != -1)
		{
			arrayLessItem = searchandreplace(theItem, "dbValuePairs_", "");
			newItem = searchandreplace(arrayLessItem, "_", ".");

			_internalDB.ValuePairs[newItem] = eval("sharedData.dbValuePairs_" + arrayLessItem);
			_internalDB.FieldAccess[newItem] = eval("sharedData.dbFieldAccess_" + arrayLessItem);
			_internalDB.DataTypes[newItem] = eval("sharedData.dbDataTypes_" + arrayLessItem);
			_internalDB.TimeStamp[newItem] = eval("sharedData.dbTimeStamp_" + arrayLessItem);
		}
	}

	_internalDB.ValuePairs["impact4.runtime.navigation"] = (new XML(sharedData.dbValuePairs_impact4_runtime_navigation)).firstChild;

	st("cachemanager: done loading data at " + getTimer());


}

// destroys the fullcommit stuff
function _cacheManager_kill()
{
	sharedData=null;
	sharedData.flush();
	st("cachemanager: DataSets size is now " + sharedData.getSize());
}

function _cacheManager_killAll() {

	sharedData.clear();
	manifestUserData.clear();
	return true;
	
}

function _cacheManager_send()
{
	st("cachemanager: not implemented");
	return;
	if(this.sendComplete == null)
	{
		st("cachemanager: must set sendComplete before attemping call");
		return false;
	}
}
