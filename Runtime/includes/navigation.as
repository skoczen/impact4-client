/* Navigation -- Implementations of Simple Linear Nav and the Full Featured Nav
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: navigation.as,v 1.29 2004/03/04 00:03:06 abansod Exp $
 */ 


#include "includes/lifecycle.as"
#include "includes/loader.as"

// bootsrap the navigation
_global.initNavigation = function()
{
	// prep our list that we'll use throughout navigatin to track
	// what needs to be loaded at "startNavigation"
	_global.itemsToLoad = new Array();
	
	// full featured nav uses this object to track lots of things
	_global.ffnState = {};
	_global.ffnState.navStack = new Array();
	_global.ffnState.navPrediction = new Array();

	// keep track of our jumps
	_global.ffnState.jumpStack = new Array();

	// keep track of our custom tag handlers
	_global.tagHandlers = new Array();
}

// navigate the system
_global.navigate = function(event, text)
{
	// use this var to keep pusihing in depths of navigaton in (tom's idea -- push in the pointers to keep path)
	var currentModules = getCurrentModules();
	var direction;
	
	if(typeof(currentModules) != "undefined" && currentModules[0] != "runtime")
	{
		// 0.1.29: in the new event model, once we're in this method, we already know that we should
		// be navigating, it's just up to us to figure out where to. No need to check the user input
	
		
		if(/*(_getValue("runtime.nextClicked") || _getValue("runtime.backClicked")) ||
		    _getValue(currentModules[0] + ".autoAdvance")*/ true)
		{
			if(event == EVENT_NAVIGATION_ATTEMPTFORWARD && text != "AutoAdvance")
			{
				st("navigation: next button clicked, unloading current mods, " + getTimer());
				direction = +1;
			}
			else if(event == EVENT_NAVIGATION_ATTEMPTBACK)
			{
				st("navigation: back button clicked, unloading current mods, " + getTimer());
				direction = -1;
			}
			else
			{
				st("navigation: currentMod[0] was autoadvance, " + getTimer());
				direction = +1;
			}
				
			if(compositeFinalizable(currentModules) || event == EVENT_NAVIGATION_ATTEMPTBACK)
			{
				// 0.0.21: fake out a finalize so our navigation can have all the data written
				// 0.1.27: fake all the modules loaded, including libraries so that they know a nav changed occured
				i4Unload(getCurrentModules(true), true);
				
				var navigationSuccess;
				// 0.1.29: make sure to pass the direction into the two navigation implementations
				if(_getValue("configuration.navType") == "simple")
					navigationSuccess = simpleLinearNavigation(direction);
				else
					navigationSuccess = fullFeaturedNavigation(direction);
	
				// if we've put something in the toload queue, then unload what is currently loaded
				if(_global.itemsToLoad.length != 0)
				{
					st("navigation: i4unload being called because itemsToLoad != 0");
					i4Unload(currentModules);
				}
					
				// if the navigation found either end of the nav, we need to fake
				// whatever current modules there are into finalizing
				if(!navigationSuccess)
				{
					st("navigation: i4unload,fake being called because navSuccess = false");
					i4Unload(currentModules, true);
				}

				// In case it was cleared.
				_cacheManager.writeManifest();
				_cacheManager.fullCommit();

				// AJAX Data send hook
				trace("_root.lcID = " + _root.lcID);
				if (!isNaN(_root.lcID) && _root.lcID != undefined && lastScreenVar != "lastScreen" ) {
					ajax_postData();					
				}


			}
			else
			{
				st("navigation: attempted to move on, but a module was not ready yet, informing the modules");
				// 0.0.17 change: inform modules that advancment failed	

				sendEventToModules(currentModules, EVENT_NAVIGATION_ADVANCEFAILED, "compositeFinalizable failed");
			}
			_setValue("runtime.nextClicked", false);
			_setValue("runtime.backClicked", false);
		}
	}
	
}

// Method to register new tags
_global.registerNewTag = function(tagName, tagFunction)
{
	var bundle = {};
	bundle.tagName = tagName;
	bundle.tagFunction = tagFunction;

	st("registerNewTag: handler (" + typeof(tagFunction) + ") for '" + tagName + "' registered");

	_global.tagHandlers.push(bundle);
}

// Navigation's Event Handler
function eventHandler(event, text)
{
	st("navigationEventHandler: " + event + ", with text " + text);
	// 0.1.29: trap these two events and send it on forward to navigate
	if(	event == EVENT_NAVIGATION_ATTEMPTFORWARD || event == EVENT_NAVIGATION_ATTEMPTBACK) {
		// Hacking the ajax post in.
		navigate(event, text);

	}
}

// ensures that the visistedconditions array contains conditions that matter
// Current is the module the user is seeing, toShow is the one that will be show once toLoad is cleared
// TODO: Use LoadHistory instead to know that path we're on
function fixupVisitedConditions(/*current, */toShow)
{
	// walk the parents of toShow and build the condition list
	var toShowPar = null;
	var leafName = "";
	var index = 0;
	var toShowStack = new Array();

	toShowPar = toShow.parentNode;
st("toShow is " + toShow.attributes.name + " parent is " + toShowPar.attributes.name);
	while(toShowPar != null)
	{
		if(toShowPar.nodeName == "condition")
		{
st("pushing toshowstack " + toShowPar.attributes.name + leafName);
			toShowStack.push(toShowPar.attributes.name + leafName);
		}
		else if(toShowPar.nodeName == "true" || toShowPar.nodeName == "false")
			leafName = toShowPar.nodeName.subString(0,1);
		toShowPar = toShowPar.parentNode;
	}

	toShowStack.reverse();
	_global.visitedConditions = new Array();

	// copy the values in to ensure we get a value copy and not a ref copy
	for(var i = 0; i < toShowStack.length; i++)
	{
		st("thshowstack " + i + " is " + toShowStack[i]);
		_global.visitedConditions[i] = toShowStack[i];
	}

	st("vis con len is " + visitedConditions.length);
	st("glo cis con lefn is " + _global.visitedConditions.length);
}

// updates the percent bar based upon loadHistory
function updatePercentBar()
{
	// 0.0.24: Update the % bar	
	var subCond = "";
	var denom = 0;
	// if there are no visited conditions, then use the longest path as the denom
	st("update % bar visitedcond is " + _global.visitedConditions.length);
	st("visited conds is " + _global.visitedConditions.toString());
	if(_global.visitedConditions.length == 0)
	{
		for(var i in _global.allSubConditions)
		{
			if(allSubConditions[i] > denom)
				denom = allSubConditions[i];
		}
	}
	// otherwise lookup this path's length
	// TODO: this is NOT 100% accurate. once you hit the first condition we 
	// will go to this, which will cause the % bar to jump back
	else
	{
		for (var i = 0; i < _global.visitedConditions.length; i ++)
		{
			st("updatePercentBar: visitedConditions[" + i + "] = " + visitedConditions[i]);
			subCond += _global.visitedConditions[i] + "_";
		}
		subCond = subCond.substring(0, subCond.length - 1);
		st("navigate: subCond is " + subCond);
		denom = allSubConditions[subCond];
	}
	st("updatePercentBar: " + _internalDB.LoadHistory.length + " over " + denom);
	// 0.2.34: updated to use event to pass data rather than direct invocation
	sendEventToModules("interface", EVENT_MODULE_PAINT, (Math.floor((_internalDB.LoadHistory.length  / _global.globalMax) * 100)));
}

// returns true or false depending if ALL the loaded mods are finalizable
function compositeFinalizable(listOfModules)
{
	var retVal = true;
	
	if(typeof(listOfModules) == "undefined")
		listOfModules = getCurrentModules();
	
	for(var i = 0; i < listOfModules.length; i++)
	{
		var currentState = _getValue(listOfModules[i] + ".lifeCycleState");
		
		if(currentState != MODULE_LIFECYCLE_RUNNINGFINALIZABLE &&
		   currentState != MODULE_LIFECYCLE_FINALIZED)
		{
			retVal = false;
			st("navigation[compositeFinalizable]: module " + listOfModules[i] + " was not finalizable at state " + currentState);
			break;
		}
	}
	return retVal;
}

// returns true if ALL of the modules are autoAdvance
function compositeAutoAdvance(listOfModules)
{
	var retVal = true;
	
	if(typeof(listOfModules) == "undefined")
		listOfModules = getCurrentModules();

	// the ALL condition
	for(var i = 0; i < listOfModules.length; i++)
	{
		var isAutoAdvance = _getValue(listOfModules[i] + ".autoAdvance");
		
		if(!isAutoAdvance)
			retVal = false;
	}
	return retVal;
}

// removes linear tags from theXML
function removeLinearTags(theXML)
{
	var totalNodes = theXML.childNodes.length;

	for(var i = 0 ; i < totalNodes; i++)
	{
		// st(i + " / " + totalNodes + " is " + theXML.childNodes[i].attributes.name);
		var heldInnards = new Array();
		// if(theXML.childNodes[i].nodeName != "module" || theXML.childNodes[i].nodeName != "group")
			

		if(theXML.childNodes[i].nodeName == "linear")
		{
			var linearNode = theXML.childNodes[i];

			// st("linear node is " + linearNode);

			// st("the xml before " + theXML);

			heldInnards = theXML.childNodes[i].childNodes;

			var innardsCollection = new Array();

			for(var j = 0 ; j < heldInnards.length; j++)
			{
				// st(j + ": " + heldInnards[j].attributes.name);
				innardsCollection[j] = heldInnards[j];
			}

			for(var j = 0; j < innardsCollection.length; j++)
			{
				theXML.insertBefore(innardsCollection[j], linearNode);
			}

			heldInnards.reverse();
/*			var innardHolder;
			var removeAdjuster = 0;
			while((innardHolder = heldInnards.pop()) != null)
			{
				removeAdjuster++
				//var innardHolder = heldInnards[j];
				st(removeAdjuster + ": " + innardHolder.attributes.name);
				theXML.insertBefore(innardHolder, linearNode);
			}*/

			// st("removing node " + (i + j) + " " + theXML.childNodes[i+j]);
			theXML.childNodes[i+j].removeNode();


			// st("the xml after " + theXML);

			// st("child node i " + theXML.childNodes[i]);

			
			// reset total nodes and start the loop over again
			totalNodes = theXML.childNodes.length;
			i = 0;
			continue;
		}
		theXML.childNodes[i] = removeLinearTags(theXML.childNodes[i]);

	}


	return theXML;
}

// breaks down random tags, called from runtime.as
function resolveRandomTags(theXML)
{
	var numToSelect, selectSize;

	for(var i = 0; i < theXML.childNodes.length; i++)
	{
		var thisNode = theXML.childNodes[i];
		if(thisNode.childNodes.length > 0)
			var resolvedTags = resolveRandomTags(thisNode);

		if(thisNode.nodeName == "random")
		{
			// check to see if the XMl says to select N number of total in the random tag
			if(typeof(thisNode.attributes.select) != "undefined")
			{
				selectSize = Math.floor(thisNode.attributes.select);
			}
			else
			{
				selectSize = thisNode.childNodes.length;
			}

			st("navigation[resolveRandomNodes]: found random tag, selectSize = " + selectSize);

			// BUG: not sure it it will use select as an object or as an integer
			numToSelect = new Array(selectSize);
			var j = 0;
			var allowedToUse;
			var index;
			while(j < selectSize)
			{
				// TODO: replace random() with Math.random()
				// slate for 0.0.13.13
				var chosenNode = thisNode.childNodes[random(thisNode.childNodes.length)];
				st("navigation[resolveRandomNodes]: chose node " + chosenNode.nodeName + " for index " + j + "(/" + selectSize + ")");

				allowedToUse = true;
				for(index = 0; index < numToSelect.length; index++)
				{
					if(numToSelect[index].attributes.name == chosenNode.attributes.name)
					{
//						st("navigation[resolveRandomNodes]: 
						allowedToUse = false;
					}
				}

				if(allowedToUse)
				{
					if(	chosenNode.nodeName != "module" &&
						chosenNode.nodeName != "group" &&
						chosenNode.nodeName != "linear")
					{
						st("navigation[ffn/random]: may only have module, group or linear tags in random clause (found: " + chosenNode + ")");
						return EVENT_NAVIGATION_ERROR;
					}
					numToSelect[j] = chosenNode;
					j++;
				}
			}
			for(j = 0; j < selectSize; j++)
				theXML.insertBefore(numToSelect[j], theXML.childNodes[i]);


			theXML.childNodes[i+selectSize].removeNode();
		}
		else
		{
			theXML.childNodes[i] = thisNode;
		}
	}
	return theXML;
}


function calculateCodePaths(theXML, depth)
{
	trace("calculateCodePaths: " + theXml.nodeName + " " + theXml.attributes.name + " " + depth);
	if(theXML.childNodes.length == 0 || theXML.nodeName == "module")
	{
		trace("calculateCodePaths: ^^ was a leaf node");
		theXML.attributes.depth = depth + 1;
		return depth + 1;
	}
	var max = depth;
	for(var i = 0; i < theXML.childNodes.length; i++)
	{
		if(theXML.childNodes[i].nodeName == "module" || theXML.childNodes[i].nodeName == "group")
		{
			max += 1;
			trace("-- modgrp " + theXML.childNodes[i].attributes.name + " " + max);
theXML.childNodes[i].attributes.depth = max;
			_global.globalMax = max;

		}
	}
	for(var i = 0; i < theXML.childNodes.length; i++)
	{
		if(theXML.childNodes[i].nodeName == "condition")
		{
			trace("-- cond " + theXML.childNodes[i].attributes.name);
			var localMax0 = calculateCodePaths(theXML.childNodes[i].childNodes[0].firstChild, depth+max);
			var localMax1 = calculateCodePaths(theXML.childNodes[i].childNodes[1].firstChild, depth+max);
			trace("-- cond max0 " + localMax0);
			trace("-- cond max1 " + localMax1);
			if(localMax0 > max) max = localMax0;
			if(localMax1 > max) max = localMax1;
_global.globalMax = max;

			theXML.childNodes[i].childNodes[0].attributes.depth = max;
			theXML.childNodes[i].childNodes[1].attributes.depth = max;
		}
	}

	return depth;
}

// Calculate the variable code paths
// TODO: We don't know how (a) jump's and (b) only include the end leaf nodes
// (so we don't put in our list of path's that isn't fully complete)
function calculateCodePaths_old(theXML, delim, count, name)
{
	for(var i = 0; i < theXML.childNodes.length; i++)
	{
		var child = theXML.childNodes[i];

		if(child.nodeName == "module" || child.nodeName == "group")
			count ++;
		
		if(allSubConditions[name.slice(1)] < count)
		{
			var nameSlice = name.slice(1);
			if(nameSlice == "" || typeof(nameSlice) == "undefined")
				nameSlice = "root";
			//st(delim + child.attributes.name + ", count=" + count + ", name.slice=" + nameSlice);
			st("calculateCodePaths: " + delim + " allSubConditions[" + nameSlice + "] = " + count);
			allSubConditions[nameSlice] = count;
		}
	}
	for(var i = 0; i < theXML.childNodes.length; i++)
	{
		var child = theXML.childNodes[i];
		var childNN = child.nodeName;
	
		if(	childNN == "condition" ||
			childNN == "linear" ||
			childNN == "true" ||
			childNN == "false")
		{
			st("calculateCodePaths: nodename " + childNN + " " + child.attributes.name)
			if(childNN == "condition")
				calculateCodePaths(child, delim + "-", count, name + "_" + child.attributes.name);
			else if(childNN == "true" || childNN == "false")
				calculateCodePaths(child, delim + "-", count, name + child.attributes.name.substring(0,1));
			else
				calculateCodePaths(child, delim + "-", count, name);

		}
	}
}

// puts true and false in condition tags to ensure the navigation can process it correctly
function resolveConditionTags(theXML)
{
	var trueNode, falseNode;

	for(var i = 0; i < theXML.childNodes.length; i++)
	{
		var thisNode = theXML.childNodes[i];

		if(thisNode.childNodes.length > 0)
			var resolvedTags = resolveConditionTags(thisNode);

		if(thisNode.nodeName == "condition")
		{
			st("navigation[resolveConditionTags]: resolving " + thisNode.attributes.name);
			
			trueNode = false;
			falseNode = false;
			for(var j = 0; j < thisNode.childNodes.length; j++)
			{
				if(thisNode.childNodes[j].nodeName == "true")
					trueNode = thisNode.childNodes[j];
				else if(thisNode.childNodes[j].nodeName == "false")
					falseNode = thisNode.childNodes[j];
			}
			
			if(trueNode == null)
			{
				// we need to create a true node
				st("navigation[resolveConditionTags]: found no true leaf");
				thisNode.appendChild(theXML.createElement("true"));
			}
			
			if(falseNode == null)
			{
				// we need to create a false node
				st("navigation[resolveConditionTags]: found no false leaf");
				thisNode.appendChild(theXML.createElement("false"));
			}
			
			// now check to see the true/false node have something in them
			var noopNode = new XML("<noop />");
			noopNode.nodeName = "noop";
			
			if(trueNode.hasChildNodes() == false)
			{
				st("navigation[resolveConditionTags]: appending the noop node to true");
				trueNode.appendChild(noopNode);
			}
			if(falseNode.hasChildNodes() == false)
			{
				st("navigation[resolveConditionTags]: appending the noop node to false");
				falseNode.appendChild(noopNode);
			}
			
			var newXMLStr = "<condition lval=\"" + thisNode.attributes.lval + "\" rval=\"" + thisNode.attributes.rval + "\" operation=\"" + thisNode.attributes.operation + "\">";
			newXMLStr += trueNode.toString();
			newXMLStr += falseNode.toString();

			var newCondition = new XML(newXMLStr);
			
			theXML.insertBefore(newCondition, theXML.childNodes[i]);
			theXML.childNodes[i].removeNode();
			
		}
		else
		{
			theXML.childNodes[i] = thisNode;
		}
	}
	return theXML;
}

// full navigation, for more complex XMLs
// returns false if we're at the end/begining of the nav
function fullFeaturedNavigation(direction)
{
	var currentModules = getCurrentModules();
	var aboutToSee;

	// find the next module
	_global.ffnState.navStack = new Array();
	_global.ffnState.foundTarget = false;

	var retVal;
	st("navigation[ffn]: moving in dir = " + direction + ", _global._internalDB.LoadHistory.length = " + _global._internalDB.LoadHistory.length + ", top of it = " + _global._internalDB.LoadHistory[_global._internalDB.LoadHistory.length]);
	if(direction == 1 || _global._internalDB.LoadHistory.length == 0)
	{
		// 0.0.22.22: Added prediction code
		st("navigation[ffn]: navPrediction's length is " + _global.ffnState.navPrediction.length);
		if(_global.ffnState.navPrediction.length != 0)
		{
			// we have a prediction, let's go for it
			retVal = processNode(_global.ffnState.navPrediction.shift());
		}
		else
			retVal = findNextElement(_getValue("runtime.navigation"), userModuleToSystem(currentModules[0]), direction, 1);
	}
	else
	{
		// if there's only 1 item in the load history, don't pop it off, in fact, do nothing
		if(_global._internalDB.LoadHistory.length != 1)
		{
			// pop off the first element because this is what the user is currently seeing
			_global._internalDB.LoadHistory.pop();
	
			// invalidate the prediction path
			// NOTE: This is not a really good way to do this, what we should do is invalidated up to where we navigated back
			_global.ffnState.navPrediction = new Array();
	
			// now pop it again to see the last screen
			aboutToSee = _global._internalDB.LoadHistory.pop();

			// if the aboutToSee is skiponback, pop again and
			if(aboutToSee.getValue("autoAdvance") == "skiponback" && _global._internalDB.LoadHistory.length != 1)
			{
				aboutToSee = _global.internalDB.LoadHistory.pop()
				retVal = processNode(aboutToSee);
			}
			else
				retVal = processNode(aboutToSee);
		}
	}

	// 0.0.24: fixup the visitedCondition list if we went backwards
	if(direction == -1)
		fixupVisitedConditions(aboutToSee);

	// 0.2.34: checking the property to see if this enabled
	if (_getValue("configuration.calculateProgressBar"))
	{
		// 0.0.24: then update the bar
		updatePercentBar();
	}

	return retVal;
}

// the general node switchboard, route a node to it's correct processor
function processNode(nextNode)
{
	var retVal;
	st("navigation[processNode]: nextNode is " + nextNode + ", name " + nextNode.nodeName);

	switch(nextNode.nodeName)
	{
		case "condition":
			retVal = processCondition(nextNode);
			break;
		case "group":
			retVal = processGroup(nextNode);
			break;
		case "module":
			retVal = processModule(nextNode);
			break;
		case "linear":
			retVal = processLinear(nextNode);
			break;
		case "random":
			st("navigation[ffn]: recieved a random tag, which should have been resolved earlier. Ignoring");
			break;
		case "noop":
			retVal = EVENT_NAVIGATION_RENAVIGATE;
			break;
		case "set":
			retVal = processSet(nextNode);
			break;
		case "true":
			retVal = processNode(nextNode.firstChild);
			break;
		case "false":
			retVal = processNode(nextNode.firstChild);
			break;
		case "navigation":
			retVal = processNode(nextNode.firstChild);
			break;
		case "jump":
			retVal = processJump(nextNode);
			break;
		case "jumplabel":
			retVal = processJumpLabel(nextNode);
			break;
		case "jumpreturn":
			retVal = processJumpReturn(nextNode);
			break;
		case "stop":
			retVal = processStop(nextNode);
			break;
		case "event":
			retVal = processEvent(nextNode);
			break;
		default:
			// search all the custom tag handlers
			for(var i = 0; i < tagHandlers.length; i++)
			{
				if(tagHandlers[i].tagName == nextNode.nodeName)
				{
					retVal = tagHandlers[i].tagFunction(nextNode);
					break;
				}
			}
			if(i != tagHandlers.length)
				st("navigation[ffn]: processNode returned garbage: " + nextNode.nodeName);
	}
	return retVal;
}

// process a linear tag (take the first contained node)
function processLinear(nextNode)
{
	return processNode(nextNode.firstChild);
}

// process a set, by firing a event
function processSet(nextNode)
{
	if(nextNode.attributes.name != "" && nextNode.attributes.value != "")
	{
		_setValue(nextNode.attributes.name, nextNode.attributes.value);
		// 0.0.24: Call the SetHandler to see if anything needs to be done when this var is set
		sendEventToModules("runtime", EVENT_NAVIGATION_SET, scopeVariable(nextNode.attributes.name));
		return EVENT_NAVIGATION_RENAVIGATE; // continue navigation
	}
	else
	{
		st("navigation[ffn]: error in set tag " + nextNode);
		return EVENT_NAVIGATION_ERROR;
	}
}

// validate and process the event tag
function processEvent(nextNode)
{
	var target, type, args;
	target = nextNode.attributes.target;
	type = nextNode.attributes.type;
	args = nextNode.attributes.arguments;

	if(	target != "" &&
		type != "" &&
		args != "")
	{
		// validate the event is legit
		if(typeof(eval(type)) == "undefined")
		{
			st("navigation[ffn]: unknown event type given " + type);
			return EVENT_NAVIGATION_ERROR;		
		}

		if(target == "*")
			target = getCurrentModules();

		sendEventToModules(target, type, args);

		return EVENT_NAVIGATION_RENAVIGATE; // continue navigation
	}
	else
	{
		st("navigation[ffn]: error in event tag " + nextNode);
		return EVENT_NAVIGATION_ERROR;
	}
}

// process a jump label (nothign to do)
function processJumpLabel(nextNode)
{
	// nothing to do
	// st("processJumpLabel: nothing to do");
	return EVENT_NAVIGATION_RENAVIGATE;
}

// process the jump tag
function processJump(nextNode, navXML, searchLabel)
{

	if(typeof(navXML) == "undefined")
	{
		navXML = _getValue("runtime.navigation");
		searchLabel = nextNode.attributes.label;
		_global.ffnState.jumpStack.push(nextNode);
		st("processJump: jumping to " + searchLabel);
	}

	for(var i = 0; i < navXML.childNodes.length; i++)
	{
		var theChild = navXML.childNodes[i];
		//st(theChild.nodeName + " " + theChild.attributes.name);
		if(theChild.nodeName == "jumplabel" && theChild.attributes.name == searchLabel)
		{
			// st("processJump: found target! " + theChild.attributes.name);
			var theSub = theChild.nextSibling;
			var retVal = EVENT_NAVIGATION_ERROR;
			while(retVal != EVENT_NAVIGATION_SUCCESS)
			{
				st("processJump: next sib is " + theSub.attributes.name);
				retVal = processNode(theSub);
				st("processJump: retval from processNode is " + retVal);

				theSub = theSub.nextSibling;
			}
			return retVal;
		}
		if(theChild.hasChildNodes())
		{
			if(processJump(nextNode, theChild, searchLabel) == EVENT_NAVIGATION_SUCCESS)
				return EVENT_NAVIGATION_SUCCESS;
		}
	}
}

// return from the last jump tag
function processJumpReturn(nextNode)
{
	var lastJump = _global.ffnState.jumpStack.pop();
	st("processJumpLabel: returning, poped " + lastJump);
	if(lastJump == null)
		return EVENT_NAVIGATION_RENAVIGATE;
	var theSub = lastJump.nextSibling;
	var retVal = EVENT_NAVIGATION_ERROR;
	while(retVal != EVENT_NAVIGATION_SUCCESS)
	{
		retVal = processNode(theSub);
		theSub = theSub.nextSibling;
	}
	return retVal;	
}

// halt the navigation
function processStop(nextNode)
{
	st("navigation: stop tag encountered, navigation halted");
	return EVENT_NAVIGATION_SUCCESS;
}

// process the condition tag, normalize the input parameters and move around
function processCondition(nextNode)
{
	// condition causes even more headaches
	var lval, rval;
	var coersionDataType = null;

	if(typeof(_getValue(nextNode.attributes.lval)) != "undefined")
	{
		lval = _getValue(nextNode.attributes.lval);
		coersionDataType = getFieldType(nextNode.attributes.lval);
	}
	else
	{
		lval = nextNode.attributes.lval;
	}

	if(typeof(_getValue(nextNode.attributes.rval)) != "undefined")
	{
		rval = _getValue(nextNode.attributes.rval);
		coersionDataType = getFieldType(nextNode.attributes.rval);
	}
	else
	{
		rval = nextNode.attributes.rval;
	}

	var operation = new String(nextNode.attributes.operation);

	st("navigation[ffn]: testing " + nextNode.attributes.lval + " " + nextNode.attributes.operation + " " + nextNode.attributes.rval);	
	st("navigation[ffn]: testing " + lval + " " + operation + " " + rval);


	// we have to coerse both ends of the operation to this datatype
	if(coersionDataType != null)
	{
		// this code roughly from database.as/castObject()
		if (coersionDataType == DB_TYPE_OBJECT)
		{
			lval = lval;
			rval = rval;
		}
		else if (coersionDataType == DB_TYPE_INTEGER)
		{
			lval = (new Number(lval)).valueOf();
			rval = (new Number(rval)).valueOf();
		}
		else if (coersionDataType == DB_TYPE_STRING)
		{
			lval = (new String(lval)).valueOf();
			rval = (new String(rval)).valueOf();
		}
		else if (coersionDataType == DB_TYPE_BOOLEAN)
		{
			if(typeof(variableValue) == "string") // probably came from XML
			{
				lval = (lval=="true") ? true : false;
				rval = (rval=="true") ? true : false;
			}
			else
			{
				lval = (new Boolean(lval)).valueOf();
				rval = (new Boolean(rval)).valueOf();
			}
		}
		else if (coersionDataType == DB_TYPE_FLOAT)
		{
			lval = parseFloat(lval).valueOf();
			rval = parseFloat(rval).valueOf();
		}
	}
	else // default to make them strings
	{
		lval = (new String(lval)).toString();
		rval = (new String(rval)).toString();
	}

	st("navigation[ffn]: lval type = " + typeof(lval) + ", rval type = " + typeof(rval));
	if(typeof(lval) == "undefined" || typeof(rval) == "undefined")
	{
		st("navigation[ffn]: either lval or rval was garbage");
		return;
	}
	
	// test this operation
	var result;
	
	if(operation == "equals")
		result = (lval == rval);
	else if(operation == "notequal")
		result = (lval != rval);
	else if(operation == "lessthanequal")
		result = (lval <= rval);
	else if(operation == "lessthan")
		result = (lval < rval);
	else if(operation == "greaterthan")
		result = (lval > rval);
	else if(operation == "greaterthanequal")
		result = (lval >= rval);
	else
		st("navigation[ffn]: operation not valid (" + operation + ")");
	
	var trueLeaf, falseLeaf;
	for(var i = 0; i < nextNode.childNodes.length; i++)
	{
		if(nextNode.childNodes[i].nodeName == "true")
			trueLeaf = nextNode.childNodes[i];
		else if(nextNode.childNodes[i].nodeName == "false")
			falseLeaf = nextNode.childNodes[i];
	}
	st("navigation[ffn]: we decided on conditioning " + result);
		
	st("navigation[ffn]: falseLeaf = " + falseLeaf + (result?"":"*"));
	st("navigation[ffn]: trueLeaf = " + trueLeaf + (result?"*":""));
	
	var retVal, leafToProcess;
	if(result)
	{
		leafToProcess = trueLeaf;
		st("navigation[ffn]: true to process firstChild = " + trueLeaf.firstChild.nodeName);
	}
	else
	{
		leafToProcess = falseLeaf;
		st("navigation[ffn]: false to process firstChild = " + falseLeaf.firstChild.nodeName);
	}
	
	if(leafToProcess.firstChild.nodeName == "noop" || leafToProcess.firstChild.nodeName == null)
		retVal = EVENT_NAVIGATION_RENAVIGATE;
	else
	{
		st("processCondition: pushing to visitedConditions " + nextNode.attributes.name + (result?"t":"f"));
		_global.visitedConditions.push(nextNode.attributes.name + (result?"t":"f"));

		trace("%BAR-C -- " + _internalDB.LoadHistory.length + "/" + _global.globalMax + " = " + (_internalDB.LoadHistory.length/_global.globalMax));

		var theSub = leafToProcess.firstChild;
		var navAttempt = EVENT_NAVIGATION_ERROR;
		while(navAttempt != EVENT_NAVIGATION_SUCCESS)
		{
			navAttempt = processNode(theSub);
			theSub = theSub.nextSibling;
		}	

		return navAttempt;
	}
	
	if(typeof(retVal) != "undefined")
	{
		st("navigation[ffn]: error process " + result + " node leaf on condition");
		return EVENT_NAVIGATION_RENAVIGATE;
	}
		
	return retVal;
}

// Loads a Group (uses processModule)
function processGroup(nextNode)
{
	for(var i = 0; i < nextNode.childNodes.length; i++)
	{
		if(nextNode.childNodes[i].nodeName == "module")
		{
			processModule(nextNode.childNodes[i], true);
		}
		else
		{
			st("navigation[ffn]: group cannot contain tag " + nextNode.childNodes[i].nodeName);
			return EVENT_NAVIGATION_ERROR;
		}
	}

	_global._internalDB.LoadHistory.push(nextNode);

	return EVENT_NAVIGATION_SUCCESS;
}

// Pushes nextNode onto the toLoad stack and flags it as visited
// doNotAdd -- optional, tells the function not to add this module to the history list
function processModule(nextNode, doNotAdd)
{
	st("navigation[processModule]: nextNode was " + nextNode.attributes.name);

	if(doNotAdd != true)
		_global._internalDB.LoadHistory.push(nextNode);

	_global.itemsToLoad.push(nextNode.attributes.name);

	if(typeof(_getValue("impact4." + nextNode.attributes.name + ".moduleType")) == "undefined")
		loadMetadataFromXml(nextNode, false, true);
	else
		loadMetadataFromXml(nextNode, true, true);


	trace("%BAR-M -- " + _internalDB.LoadHistory.length + "/" + _global.globalMax + " = " + (_internalDB.LoadHistory.length/_global.globalMax));

	st("navigation[processModule]: loadHistory is " +  _global._internalDB.LoadHistory.length + " items long");

	return EVENT_NAVIGATION_SUCCESS;
}

// sets up the _global.ffnState.navStack
function findNextElement(theXML, theModule, direction, numberOfSteps)
{
	st("navigation[ffn]: findNextElement begins, dir = " + direction + ", numSteps = " + numberOfSteps + ", theModule = " + theModule);
//	var heldPop = _internalDB.LoadHistory.pop();
//	st("lh len " + _internalDB.LoadHistory.length);

	for(var i = _internalDB.LoadHistory.length - 1; i >= 0; i--)
	{
		var iNode = _internalDB.LoadHistory[i]
//		st("loop " + i + " " + iNode) ;
//		st("next sib " + iNode.nextSibling);
		var tempNode = iNode;

		while(true)
		{
			if(	tempNode.nextSibling == null &&
				tempNode.parentNode == null)
			{
				st("navigation[ffn]: findNextElement: hit the end of the nav, no nav action taken");
				// server v2.0 hook in for data check.
				checkDataComplete();
				return EVENT_NAVIGATION_ERROR;
			}
			if(tempNode.nextSibling == null)
			{
				tempNode = tempNode.parentNode;
				continue;
			}
			if(tempNode.nextSibling.nodeName == "set")
			{
				processSet(tempNode.nextSibling);
				tempNode = tempNode.nextSibling;
				continue;
			}
			if(	tempNode.nextSibling.nodeName == "true" ||
				tempNode.nextSibling.nodeName == "false")
			{
				tempNode = tempNode.parentNode;
				continue;
			}
			if(processNode(tempNode.nextSibling) != EVENT_NAVIGATION_SUCCESS)
			{
				if(tempNode.nextSibling != null)
					tempNode = tempNode.nextSibling;
				else
					tempNode = tempNode.parentNode;
				continue;
			}
			return EVENT_NAVIGATION_SUCCESS;
		}
	}
}

// a simple, fast, linear only navigation
// returns false if we're at the end/begining of the nav
function simpleLinearNavigation(direction)
{
	// ------ START 0010 CODE ------
	// 0.0.10.10 Version of the navigatin
	// only supports simple module list only linear navigation

	var theNavigation = _getValue("runtime.navigation");
	var currentModules = getCurrentModules();
				
	// This is a two pass process (this is the SIMPLE linear)
	// Pass 1: First pass isolates where in the XML we are
	// Pass 2: The second pass determins where we should go next
	for(var modIndex = 0; modIndex < currentModules.length; modIndex++)
	{
		for(var navIndex = 0; navIndex < theNavigation.childNodes.length; navIndex ++)
		{
			if(theNavigation.childNodes[navIndex].nodeName == "group")
			{
				for(var groupIndex = 0; groupIndex < theNavigation.childNodes[navIndex].childNodes.length; groupIndex++)
				{
					if(currentModules[modIndex] == theNavigation.childNodes[navIndex].childNodes[groupIndex].attributes.name)
					{
						st("navigation[sln]: group " + theNavigation.childNodes[navIndex].childNodes[groupIndex].attributes.name + ", child nodes = " + i + ", modIndex = " + modIndex);
						break;
					}
				}
			}
			else if(currentModules[modIndex] == theNavigation.childNodes[navIndex].attributes.name)
			{
				st("navigation[sln]: found instance " + theNavigation.childNodes[navIndex].attributes.name + ", child nodes = " + navIndex + ", modIndex = " + modIndex);
				break;
			}
		}
	}
	
	// 0.1.29: navIndex is derived from the new event based navigation model,
	// thus we don't need to caculate it, just use the direction var that is passed in
	if(direction == 1 /*_getValue("runtime.nextClicked") || compositeAutoAdvance(currentModules)*/)
		navIndex++;
	else
		navIndex--;
	
	if(navIndex < 0)
	{
		st("navigation[sln]: hit the front end of the nav, no nav action taken");
		return EVENT_NAVIGATION_ERROR;
	}
	else if(navIndex >= theNavigation.childNodes.length)
	{
		st("navigation[sln]: hit the back end of the nav, no nav action taken");
		// server v2.0:  hook in for data check.
		checkDataComplete();
		return EVENT_NAVIGATION_ERROR;
	}
	else
		st("navigation[sln]: now navigating to = " + navIndex);
	
	// Pass 2 -- execute the navigation command set
	// {module, group, set, random, condition}
	var navNode = theNavigation.childNodes[navIndex];
	if(navNode.nodeName == "module")
	{
		st("navigation[sln]: pushing to loadstack " + navNode.attributes.name);
		_global.itemsToLoad.push(navNode.attributes.name);
	}
	else if(navNode.nodeName == "group")
	{
		st("navigation[sln]: doing a group load")
		for(var i = 0; i < navNode.childNodes.length; i++)
		{
			if(navNode.childNodes.nodeName == "module")
				_global.itemsToLoad.push(navNode.childNodes[i].name);
		}
	}
	else
		st("navigation[sln]: ERROR -- unknown navigation verb " + navNode.nodeName);
	return EVENT_NAVIGATION_SUCCESS;
	
// ------ END 0010 CODE ------ 
}



