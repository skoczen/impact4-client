/* ModuleBootstrap -- This file supports the bootstraping of a module's internals
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: modulebootstrap.as,v 1.8 2003/07/24 12:45:21 abansod Exp $
 */ 

// Associates an object with the built in functions
function associateModuleFunctions(moduleObject, instanceName)
{
	moduleObject.getValue = moduleGetValue;
	moduleObject.setValue = moduleSetValue;
	moduleObject.layoutManager = layoutManager;
	moduleObject.selfFinalize = selfFinalize;
	moduleObject.selfFinalizable = selfFinalizable;
	moduleObject.selfRunning = selfRunning;
	moduleObject.getXml = moduleGetXml;
}

// Auto associates an object with it's properties
function associateModuleVariables(moduleObject, instanceName)
{

	var dbFields;

	// since we're dealing with a low level, XML-ish case, we need this name converted
	//instanceName = userModuleToSystem(instanceName);

	dbFields = getKeyNames("impact4." + instanceName + ".");
	for(var i = 0; i < dbFields.length; i++)
	{
		if(getFieldAccess(dbFields[i]) == DB_FIELDACCESS_CONSTANT)
		{
			// we need to see how many parts this field has
			fieldParts = dbFields[i].split(".");
			
			// if it has 3 parts, we can make a direct association
			// e.g. impact4.eduMovie.text
			if(fieldParts.length == 3)
			{
				// st("associateModuleVars[" + i + "]: " + moduleObject._name + "." + fieldParts[2] + " = " + _getValue(dbFields[i]) + ", typeof = " + typeof(_getValue(dbFields[i])));
				set(moduleObject._name + "." + fieldParts[2], _getValue(dbFields[i]));
			}
			
			// if it has 4 parts, we need to determine if it's a composite object, or a sub module
			// e.g. impact4.eduMovie.layout.xpos vs impact4.eduMovie.question1.text
			// we make this determination by knowning that all modules have the "moduleType" field
			// so if it has a moduleType field, then we ignore it, otherwise associate it
			else if (fieldParts.length == 4)		
			{
				firstThree = fieldParts[0] + "." + fieldParts[1] + "." + fieldParts[2];
				
				// it's a composite
	
				// NOTE: since we are now using the <GROUP> tag instead of nesting modules
				// this check may be irrelevent
				if(typeof(_getValue(firstThree + ".moduleType")) == "undefined")
				{
					var tempObject = eval(moduleObject._name + "." + fieldParts[2]);
					if (typeof(tempObject) == "undefined")
					{
						set(moduleObject._name + "." + fieldParts[2], {});
					}
					set(moduleObject._name + "." + fieldParts[2] + "." + fieldParts[3], _getValue(dbFields[i]));
				}			
			}
		}
	}

	// give its name, also
	moduleObject.myName = "impact4." + instanceName;
}

/*********** These functions are assigned in i4Load to a loaded module ***********/

// The module's custom getValue
function moduleGetValue(variableName)
{
	if (typeof(this.myName) != "undefined")
		return _global._getValue(this.myName + "." + variableName);
	else
		return _global._getValue(variableName);
}

// The module's custom setValue
function moduleSetValue(variableName, variableValue)
{
	if (typeof(this.myName) != "undefined")
		return _global._setValue(this.myName + "." + variableName, variableValue);
	else
		return _global._getValue(variableName, variableValue);
}

// The module's generic layouter
function layoutManager()
{
	// lots of layout type stuff, slated for 0.0.16.16
	
	// calls a custom layouter if there is one
	this.eventHandler(EVENT_MODULE_PAINT, "Init Paint Layout");
}

// Lets the runtime know that this module needs to be finalized now
// This will be probably only used modules that are autoAdvance
function selfFinalize()
{
	if(this.getValue("lifeCycleState") == MODULE_LIFECYCLE_RUNNING || this.getValue("lifeCycleState") == MODULE_LIFECYCLE_RUNNINGFINALIZABLE )
		if(this.getValue("autoAdvance") != "false")
			this.setValue("lifeCycleState", MODULE_LIFECYCLE_FINALIZED);
			// 0.0.20: changed the state from FINALIZED to MODULE_LIFECYCLE_RUNNINGFINALIZABLE
		else
			st(this.myName + ": ERROR: module was in the correct state, but not autoadvance");
	else
		st(this.myName + ": ERROR: invalid attempt to change from " + this.getValue("lifeCycleState") + " to MODULE_LIFECYCLE_FINALIZE");
}

// lets the runtime know that we can be finalize if so desired
function selfFinalizable()
{
	if(this.getValue("lifeCycleState") == MODULE_LIFECYCLE_RUNNING ||
	   this.getValue("lifeCycleState") == MODULE_LIFECYCLE_RUNNINGFINALIZABLE)
	{
		this.setValue("lifeCycleState", MODULE_LIFECYCLE_RUNNINGFINALIZABLE);
		// 0.1.29: hook in to the new model of navigating by sending an event
		if(this.getValue("autoAdvance") != "false")
			sendEventToModules("navigation", EVENT_NAVIGATION_ATTEMPTFORWARD, "AutoAdvance");
	}
	else
		st(this.myName + ": ERROR: invalid attempt to change from " + this.getValue("lifeCycleState") + " to MODULE_LIFECYCLE_RUNNINGFINALIZABLE");

}

// set the module back to the running state
function selfRunning()
{
	if(this.getValue("lifeCycleState") == MODULE_LIFECYCLE_FINALIZED ||
	   this.getValue("lifeCycleState") == MODULE_LIFECYCLE_RUNNINGFINALIZABLE)
	{
		this.setValue("lifeCycleState", MODULE_LIFECYCLE_RUNNING);
		// 0.1.29: hook in to the new model of navigating by sending an event
		if(this.getValue("autoAdvance") != "false")
			sendEventToModules("navigation", EVENT_NAVIGATION_ATTEMPTFORWARD, "AutoAdvance");
	}
	else
		st(this.myName + ": ERROR: invalid attempt to change from " + this.getValue("lifeCycleState") + " to MODULE_LIFECYCLE_RUNNING");
}

// gets the xml that caused this module to load
function moduleGetXml()
{
	return _global._internalDB.LoadHistory[_global._internalDB.LoadHistory - 1];
}
