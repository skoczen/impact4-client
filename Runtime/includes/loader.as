/* Loader -- this file supports loading and unloading of modules
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: loader.as,v 1.19 2003/10/04 22:51:02 abansod Exp $
 */ 

// Loads an I4 module
// toLoad -- module to load
// baseClip -- target to load into
// Requires that toLoad be a module in the XML
_global.i4Load = function(toLoad, baseClip)
{
	st("i4load: loading " + toLoad + " using " + baseClip + " as base, " + getTimer());
	var modemBuffer = _getValue("runtime.defaultModemBuffer");
	var isdnBuffer = _getValue("runtime.defaultIsdnBuffer");
	var cableBuffer = _getValue("runtime.defaultCableBuffer");
	var levelToLoad = allocNewLevel();
	var moduleFile;
	var lifeCycleState;
	var aliasedToLoad;
	var levelFromXML;
	var targetLocations = new Array();

	var needNoInterface = false;

	for(var i = 0; i < toLoad.length; i++)
	{
		var moduleType = _getValue("impact4." + toLoad[i] + ".moduleType");
		if(_getValue("impact4.modules." + toLoad[i] + ".type") == MODULE_TYPE_LIBRARY) // it probably isn't a conventional module then
		{
			moduleType = toLoad[i];
			// load libraries above everything
			levelToLoad = allocNewLevel(20000);
		}
		if(_internalModuleList[moduleType])
		{
			// DEBUG for CS3 only.
			moduleFile = "../Controls/" + _getValue("impact4.modules." + moduleType + ".filename")
//			moduleFile = "../Controls/" + _getValue("impact4.modules." + moduleType + ".filename")
		} else {
			moduleFile = _getValue("impact4.modules." + moduleType + ".filename")			
		}

		lifeCycleState = _getValue("impact4." + toLoad[i] + ".lifeCycleState")

		if(typeof(moduleType) != "undefined" && typeof(moduleFile) != "undefined")
		{
			// we can only load an unloaded movie
			if(	lifeCycleState == MODULE_LIFECYCLE_UNLOADED ||
				_getValue("impact4.modules." + moduleType + ".type") == MODULE_TYPE_LIBRARY)
			{

				// the database will automatially convert the XML names to database-space names
				aliasedToLoad = toLoad[i];//userModuleToSystem(toLoad[i]);

				// ensure the aliases for what is goign on the stage are correct
				_setValue("impact4." + aliasedToLoad + ".alias", toLoad[i]);

				// check the level vs the spec'd level
				levelFromXML = _getValue("impact4." + aliasedToLoad + ".level")
				if(typeof(levelFromXML) == "undefined")
				{
					newLevel = levelToLoad + i;
				} else {
					newLevel = levelToLoad + 100 + levelFromXML;					
				}

				

				// dupe the movie clip, giving the instance name that we want to load
				baseClip.duplicateMovieClip(aliasedToLoad, newLevel);

				var tempObject = eval(aliasedToLoad);

				var moduleHelp = _getValue("impact4.modules." + moduleType + ".help")
				if(typeof(moduleHelp) == "undefined")
				{
					st("i4load: NOTE: no help file found for " + moduleType);
					//interfaceClip.showDialogMessage("i4load: NOTE: no help file found for " + moduleType);
				}

				if(typeof(tempObject) == "undefined")
				{
					st("i4load: ERROR -- tempObject was undefined! Will attempt again in a few milliseconds. baseClip was " + typeof(baseClip));
					return EVENT_NAVIGATION_ERROR;
				}
				//tempObject.loadMovie(_getValue("runtime.loadingPrefix") + "../Resources/" + moduleFile, tempObject);

				// DEBUG for CS3
				trace("moduleFile = " + moduleFile);
				if(_global.loadedViaCore == true) {
					targetLocations.push(_getValue("runtime.loadingPrefix") + "../Resources/" + moduleFile);					
				} else {
					targetLocations.push(moduleFile);					
				}


				tempObject._visible = false;
				
				st("i4load: just loaded " + _getValue("runtime.loadingPrefix") + "../Resources/" + moduleFile + " into " + tempObject);

				// set it as loading
				_setValue("impact4." + toLoad[i] + ".lifeCycleState", MODULE_LIFECYCLE_LOADING);

				// if the module has requested no interface, set the flag
				if(_getValue("impact4." + toLoad[i] + ".noInterface"))
					needNoInterface = true;

				
				// ABANSOD: temp, needs to be wired up.
				// TODO scheduled for 0.0.14.14
				// Need to talk to Steven about this -- how are we going to handle defaults if the module
				// writer doesn't give us a value? Current, I'm going to hardcode values in Runtime,
				// all we need to do to enable this is is to change the _getValue("runtime... to _getValue(toLoad[i] + ".modemBufferPercent"), etc
				modemBuffer += _getValue("runtime.defaultModemBuffer")/2;
				isdnBuffer += _getValue("runtime.defaultIsdnBuffer")/2;
				cableBuffer += _getValue("runtime.defaultCableBuffer")/2;
			}
			else
			{
				st("i4load: module " + toLoad[i] + " not in unloaded state (" + lifeCycleState + ")");
				toLoad[i] = "";
			}
		}
		else
		{
			st("i4load: ERROR: either module (" + toLoad[i] + ") moduleType (" + moduleType + ") or moduleFileName (" + moduleFile + ") not found (check your XML)");
			toLoad[i] = "";
		}
	}

	// now take whatever we've succesfully loaded and pass it to the preloader
	var sendToPreLoader = new Array();
	for(var i = 0; i < toLoad.length; i++)
		if(toLoad[i] != "")
		{
			sendToPreLoader.push(toLoad[i]);
		}

	// now acutally send it out
	if(sendToPreLoader.length != 0)
	{
		//loadComponent.doLoad(arrURL, arrTgt);
		i4Preloader.loadComponent.doLoad(targetLocations, sendToPreLoader);
		//tempObject.loadMovie(_getValue("runtime.loadingPrefix") + "../Resources/" + moduleFile, tempObject);
		if(needNoInterface)
		{
			st("i4load: making interface invisible");
			interfaceClip._visible = false;
		}
	}

	// we've succeded if we've gotten this far, tell our caller that
	return EVENT_NAVIGATION_SUCCESS;

}

// function executes when the runtime/loader knows  the
// module has finished loading
_global.preLoaderDoneLoading = function()
{	
	if (!isNaN(_getValue("configuration.preloaderInterval")) ) {
		// wait the specified # of milisecsonds for flash to catchup
		_global.preloaderIntervalID = setInterval(preloaderInterval, _getValue("configuration.preloaderInterval"));
	} else {
		// wait 300 milisecsonds for flash to catchup
		_global.preloaderIntervalID = setInterval(preloaderInterval, 300);

	}
}

// called after the millisecond interval is over from preLoaderDoneLoading
_global.preloaderInterval = function()
{
	// clear the interval
	clearInterval(_global.preloaderIntervalID);
	delete _global.preloaderIntervalID;

	var moduleState;
	var moduleType;
	var moduleInstanceOf;
	var moduleName;

	var allLifeCycles = getKeyNames("lifeCycleState").reverse();
	st("preloaderInterval: called at " + getTimer());

	//0.0.23: blow away our currently loaded modules
	_global._currentLoadedModules = new Array();

	for(var i = 0; i < allLifeCycles.length; i++)
	{
		moduleState = _getValue(allLifeCycles[i]);
		moduleInstanceOf = _getValue(allLifeCycles[i].substring(0, allLifeCycles[i].length-".lifeCycleState".length) + ".moduleType");
		moduleType = _getValue("impact4.modules." + moduleInstanceOf + ".type");

		// to see if this is in a running state
		if(moduleState == MODULE_LIFECYCLE_LOADING)
		{
			st("preloaderInterval: module " + allLifeCycles[i] + " at state " + moduleState);

			moduleName = allLifeCycles[i].split(".")[1];

			var objectString = userModuleToSystem(moduleName);
			var tempObject = eval(objectString);

			// associate the module internals
			associateModuleFunctions(tempObject, moduleName);
			associateModuleVariables(tempObject, moduleName);

			tempObject.setValue("lifeCycleState", MODULE_LIFECYCLE_LOADED);

			// fire off the events
			sendEventToModules(moduleName, EVENT_MODULE_INITALIZE, "Init");
			tempObject.setValue("lifeCycleState", MODULE_LIFECYCLE_RUNNING);

			// 0.1.28: Set the X and Y if the values are not -1 and scale
			if(!IsNaN(tempObject.getValue("x")))
				tempObject._x = tempObject.getValue("x");
			if(!IsNaN(tempObject.getValue("y")))
				tempObject._y = tempObject.getValue("y");
			if(!IsNaN(tempObject.getValue("scale")))
				tempObject._xscale = tempObject.getValue("scale");
				tempObject._yscale = tempObject.getValue("scale");

			tempObject.gotoAndPlay(tempObject.getValue("startFrameLabel"));	
			
			// 0.0.23: set it to visible in case it was hiden due to refCounter > 1 and sets modules to visible.
			tempObject._visible = true;		
			
			// send paint to interface (so it hears)
			sendEventToModules(moduleName, EVENT_MODULE_PAINT, "Init Paint Layout");
			sendEventToModules("interface", EVENT_MODULE_PAINT);

			

			// only regular modules can be visible
			if(moduleType != MODULE_TYPE_MODULE)
			{
				tempObject._visible = false;
				// 0.1.28: make the library global, and add it to the loaded list
				set("_global." + moduleName, tempObject);
				_global._currentLoadedLibraries.push(eval("_global." + moduleName));
			}
			else
				_global._currentLoadedModules.push(tempObject);
		}
	}

	// hides the preloader
	i4Preloader.loadComponent._visible = false;


	// now re-push all the libraries as modules
	for(var i = 0; i < _global._currentLoadedLibraries; i++)
	{
		_global._currentLoadedModules.push(_global._currentLoadedLibrares[i]);
	}

	clearInterval(_global.preloaderIntervalID);
	delete _global.preloaderIntervalID;
}

// Unloads a module. This should be called when we determine a module should be unloaded
// clipName -- optional, if specified unloads only that clip, otherwise unloads all
// 			getCurrentModules clips
// fakeUnload -- optional, does everything except the actual unload
_global.i4Unload = function(clipName, fakeUnload)
{
	var toUnload = _currentLoadedModules;
		 // getCurrentModules(true);
	var aboutToDie;
	var currentState;
	var currentType;
	var unloadingSuccess = true;
	var refCounter = 0;

	st("i4unload: currentMods = " + toUnload + ", clip given = " + clipName + ", fakeUnload = " + fakeUnload);

	if(typeof(clipName) != "undefined" && clipName != "")
		if(typeof(clipName) == "string") // we got a single module name
			toUnload = new Array(clipName);
		else // we got an array
			toUnload = clipName;

	if(typeof(fakeUnload) == "undefined" || fakeUnload == "")
		fakeUnload = false;

	for(var i = 0; i < toUnload.length; i++)
	{
		aboutToDie = eval(userModuleToSystem(toUnload[i])); 
		currentState = aboutToDie.getValue("lifeCycleState");
		currentType = _getValue("impact4.modules." + aboutToDie.getValue("moduleType") + ".type");
		refCounter = _getValue("impact4.modules." + aboutToDie.getValue("moduleType") + ".refCounter");


		st("i4unload: about to unload " + toUnload[i] + " at state " + currentState);

		// make sure we can ACTUALLY unload this module
		if(	(currentState == MODULE_LIFECYCLE_RUNNING ||
			currentState == MODULE_LIFECYCLE_RUNNINGFINALIZABLE ||
			currentState == MODULE_LIFECYCLE_FINALIZED) )
		{
			sendEventToModules(aboutToDie.myName.split('.')[1], EVENT_MODULE_FINALIZE, "Finalize " + (fakeUnload ? "fake unload" : "real unload"));

			if(!fakeUnload)
			{

				if(currentType == MODULE_TYPE_MODULE)
				{
					aboutToDie.setValue("lifeCycleState", MODULE_LIFECYCLE_UNLOADED);

					// 0.1.28: allow user to disable GC
					if(_getValue("impact4.configuration.enableGarbageCollection"))
					{
						// 0.0.23: don't unload modules we may use again
						if(refCounter == 1)
						{
							st("i4unload: refCounter == 1, and not fakeUnload, unloading mod");
							aboutToDie.removeMovieClip();
						}
						else
						{
							refCounter--;
							_setValue("impact4.modules." + aboutToDie.getValue("moduleType") + ".refCounter", refCounter);
							st("i4unload: refCounter != 1, and not fakeUnload, setting to invisible and dec'ing refCounter to " + refCounter);
							aboutToDie._visible = false;
						}
					}
					else
					{
						st("i4unload: not fakeUnload, unloading mod");
						aboutToDie.removeMovieClip();
					}
				}
			}
		}
		else
		{
			st("i4unload: ERROR: attempted to unload a module in state " + currentState);
			unloadingSuccess = false;
		}
	}


	if(unloadingSuccess)
		_parent.interfaceClip._visible = true;


}

// loader's event handler
_global.loaderEventHandler = function(event, text)
{
	if(event == EVENT_LOADER_FILENOTFOUND)
	{
		var dialogText = "Error Occured: Unable to load module.\n("

		st("loaderEventHandler: unable to load SWFs, stopping");
		var allLifeCycles = getKeyNames("lifeCycleState");
		for(var i = 0; i < allLifeCycles.length; i++)
		{
			var moduleState = _getValue(allLifeCycles[i]);
			var moduleInstanceOf = _getValue(allLifeCycles[i].substring(0, allLifeCycles[i].length-".lifeCycleState".length) + ".moduleType");
	
			// to see if this is in a running state
			if(moduleState == MODULE_LIFECYCLE_LOADING)
			{
				dialogText += moduleInstanceOf + ", ";
			}
		}
		showDialogMessage(dialogText.substring(0, dialogText.length - 2) + ")");

		stop();
	}
	else if(event == EVENT_LOADER_SUCCESS)
	{
		preLoaderDoneLoading();
	}
}

// Loads any modules if needed, called from navigation.fla
_global.loadIfNecessary = function(targetToLoad)
{
	// make sure we're in a state that we're allowed to do this
	if(_getValue("runtime.initFinished"))
	{
		//load what's been put on the stack
		if(_global.itemsToLoad.length != 0)
		{
			st("loader: about to load " + _global.itemsToLoad);
			if(i4load(_global.itemsToLoad, targetToLoad) == EVENT_NAVIGATION_SUCCESS)
				// and then blow away the list
				_global.itemsToLoad = new Array();
			else
				st("loader: i4load failed, itemsToLoad not cleared");
		}
	}
}


// load the first module, called from the navigation.fla
_global.loadFirstModule = function()
{	
	// dump the database if set to do so
	if(_getValue("configuration.dumpDatabaseBeforeNavigation"))
		dumpNameValuePairs();
	st("navigation: initNav at " + getTimer());
	
	var index = 0;
	while(processNode(_getValue("runtime.navigation").childNodes[index]) != EVENT_NAVIGATION_SUCCESS)
		index++;

	_global.itemsToLoad.reverse();

}
