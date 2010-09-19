/* Database -- These methods support our internal DB
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * $Id: database.as,v 1.10 2003/10/22 19:56:22 abansod Exp $
 */ 

/*
	TODO: Add callee checking to ensure _global state of any SYSTEMWRITEONLY fields

Notes on this method:
	1. the <scope_variable_section> should be idential in get and set value methods
	2. the constant defines are on the top


*/

_global.DB_FIELDACCESS_CONSTANT		= 0;
_global.DB_FIELDACCESS_READWRITE	= 1;
_global.DB_FIELDACCESS_SYSTEMWRITEONLY	= 2;

_global.DB_TYPE_OBJECT		= 0;
_global.DB_TYPE_STRING		= 1;
_global.DB_TYPE_INTEGER		= 2;
_global.DB_TYPE_FLOAT		= 3;
_global.DB_TYPE_BOOLEAN		= 4;
_global.DB_TYPE_COMPOSITE	= 5;

// sets a value
// the first two parameters are required, the last three are required if createVariable is true
_global._setValue = function(variableName, variableValue, createVariable, fieldAccess, fieldType)
{
	// <scope_variable_section>
	/* THIS SHOULD BE IDENTIAL TO THE "SCOPE VARIABLE SECTION" in getValue
	   We keep this code in each function for performance reasons -- the context switch of moving from one
	   function to another is too high in flash
	*/

	// 0.0.19: scope the variable -- removed from a seperate function for performance
	if(variableName.substring(0, 7) != "impact4")
	{
		variableName = "impact4." + variableName;
	}

	// 0.0.20: check the aliaslookup table
	var varParts = variableName.split(".");
	if(	varParts[1] != "modules" &&
		varParts[1] != "configuration" &&
		varParts[1] != "runtime" &&
		typeof(_global._internalDB.ModuleAliasLookup[varParts[1]]) != "undefined") // make sure this link acutally exists
	{

		// we do varPars[2] explicilty because we know there will ALWAYS be 3 parts to a variable name
		// and we don't want to loop unless we absolutly have to (which would be the case if there was composite var)
		variableName = 	"impact4." +
				_global._internalDB.ModuleAliasLookup[varParts[1]] + "." +
				varParts[2];

		// loop if we have to -- most of the time (~99%) this loop should never run because var names
		// are only 3 parts long
		for(var i = 3; i < varParts.length; i++)
			variableName += "." + varParts[i];
	}

	// </scope_variable_section>

	// var currentModules = getCurrentModules();
	if(_global._internalDB.ValuePairs["impact4.configuration.traceSetValue"])
		st("setval {" + variableName + ", " + variableValue + "} {" + createVariable + " " + fieldAccess + " " + fieldType + " " + currentModules[0] + ", " + getTimer() + ", " + typeof(variableValue) +"}");
	
	// the 1st part of this checks to see if we're trying to create a var
	// the 2rd half makes sure that variable creation only occurs for runtime
	if((typeof(createVariable) != "undefined" && createVariable == true) /* &&
	   (currentModules[0] == "runtime")*/)
	{
		// Set up our access rule for this new field
		if (typeof(fieldAccess) != "undefined")
			_global._internalDB.FieldAccess[variableName] = fieldAccess;
		else
			// By default, the field is read-write if unspecified
			_global._internalDB.FieldAccess[variableName] = DB_FIELDACCESS_READWRITE;

		// Set the data type
		if (typeof(fieldType) == "undefined")
			// in the undefined case we assume its an object
			_global._internalDB.DataTypes[variableName] = DB_TYPE_OBJECT;
		else
			_global._internalDB.DataTypes[variableName] = fieldType;

		// Now set the variable
		_global._internalDB.ValuePairs[variableName] = castObject(variableName, variableValue);
		_global._internalDB.TimeStamp[variableName] = getTimer();
		_global._internalDBChangeLog.push(variableName);
//		_global._internalDB.ValuePairs[variableName] = variableValue;
	}
	else
	{
		if(typeof(_global._internalDB.ValuePairs[variableName]) == "undefined")
		{
			st("ERROR -- Setting an undefined variable (" + variableName + ")");
		}
		else
			if(_global._internalDB.FieldAccess[variableName] != DB_FIELDACCESS_CONSTANT /* ||
				(_global._internalDB.FieldAccess[variableName] == DB_FIELDACCESS_SYSTEMWRITEONLY  &&
				currentModules[0] == "runtime" )*/ )
			{
				_global._internalDB.ValuePairs[variableName] = castObject(variableName, variableValue);
				_global._internalDB.TimeStamp[variableName] = getTimer();
				_global._internalDBChangeLog.push(variableName);
//				_global._internalDB.ValuePairs[variableName] = variableValue;
			}
			else
				st("database[setValue]: ERROR -- attempted to set " + variableName);
	}

	// Second Stage Commit -- Send it to the cacheObject
	// TODO: We should only do the second stage commit if needed	_global._cacheObject.data._internalDB = _global._internalDB;
	// TODO: We should have a property for the cache flush frequency:	_global._cacheObject.flush();
	if(_internalDB.FieldAccess[variableName] == DB_FIELDACCESS_READWRITE)
	{
//		if(_internalDB.ValuePairs["impact4.configuration.writeToManifest"] == true)
//		{
			_cacheManager.writeToManifest(variableName);
//		}
		
		if(	_internalDB.ValuePairs["impact4.configuration.dataClient"] == "xmlsocket" &&
			XmlSocketClient.isConnected &&
			XmlSocketClient.isSecure)
		{
			XmlSocketClient.sendData(variableName, "internaldb");
		}

	}
}

// 0.0.24: this function does NOT have any sort of data validation, and should only be used by internal functions
// used to blast a variable into the internaldb as quickly as possible
_global._setValueUnchecked = function(variableName, variableValue, createVariable, fieldAccess, fieldType)
{
	// <scope_variable_section>
	/* This scope_variable_section is modified to take out some of the parameter checks*/
	
	var varParts = variableName.split(".");
	if(	varParts[1] != "modules" &&
		varParts[1] != "configuration" &&
		varParts[1] != "runtime" &&
		typeof(_global._internalDB.ModuleAliasLookup[varParts[1]]) != "undefined") // make sure this link acutally exists
	{

		// we do varPars[2] explicilty because we know there will ALWAYS be 3 parts to a variable name
		// and we don't want to loop unless we absolutly have to (which would be the case if there was composite var)
		variableName = 	"impact4." +
				_global._internalDB.ModuleAliasLookup[varParts[1]] + "." +
				varParts[2];

	}

	// </scope_variable_section>

	if(_global._internalDB.ValuePairs["impact4.configuration.traceSetValue"])
		st("setvalUnchecked {" + variableName + ", " + variableValue + "} {" + createVariable + " " + fieldAccess + " " + fieldType + " " + currentModules[0] + ", " + getTimer() + ", " + typeof(variableValue) +"}");

	_global._internalDB.FieldAccess[variableName] = fieldAccess;
	_global._internalDB.DataTypes[variableName] = fieldType;
	_global._internalDB.TimeStamp[variableName] = getTimer();
	_global._internalDBChangeLog.push(variableName);

	// 0.1.27: Changed this to cast the object
	// _global._internalDB.ValuePairs[variableName] = variableValue;
	_global._internalDB.ValuePairs[variableName] = castObject(variableName, variableValue);

}

// scopeVariable here is used in non-critical sections
_global.scopeVariable = function(variableName)
{
	// <scope_variable_section>
	/* THIS SHOULD BE IDENTIAL TO THE "SCOPE VARIABLE SECTION" in getValue
	   We keep this code in each function for performance reasons -- the context switch of moving from one
	   function to another is too high in flash
	*/

	// 0.0.19: scope the variable -- removed from a seperate function for performance
	if(variableName.substring(0, 7) != "impact4")
	{
		variableName = "impact4." + variableName;
	}

	// 0.0.20: check the aliaslookup table
	var varParts = variableName.split(".");
	if(	varParts[1] != "modules" &&
		varParts[1] != "configuration" &&
		varParts[1] != "runtime" &&
		typeof(_global.internalDB.ModuleAliasLookup[varParts[1]]) != "undefined" ) // make sure this link exists 
	{

		// we do varPars[2] explicilty because we know there will ALWAYS be 3 parts to a variable name
		// and we don't want to loop unless we absolutly have to (which would be the case if there was composite var)
		variableName = 	"impact4." +
				_global.internalDB.ModuleAliasLookup[varParts[1]] + "." +
				varParts[2];

		// loop if we have to -- most of the time (~99%) this loop should never run because var names
		// are only 3 parts long
		for(var i = 3; i < varParts.length; i++)
			variableName += "." + varParts[i];
	}

	// </scope_variable_section>

	return variableName;

	
}

// returns the value of variablename
_global._getValue = function(variableName)
{
	// <scope_variable_section>
	/* THIS SHOULD BE IDENTIAL TO THE "SCOPE VARIABLE SECTION" in getValue
	   We keep this code in each function for performance reasons -- the context switch of moving from one
	   function to another is too high in flash
	*/

	// 0.0.19: scope the variable -- removed from a seperate function for performance
	if(variableName.substring(0, 7) != "impact4")
	{
		variableName = "impact4." + variableName;
	}

	// 0.0.20: check the aliaslookup table
	var varParts = variableName.split(".");
	if(	varParts[1] != "modules" &&
		varParts[1] != "configuration" &&
		varParts[1] != "runtime" &&
		typeof(_global._internalDB.ModuleAliasLookup[varParts[1]]) != "undefined" ) // make sure this link exists 
	{

		// we do varPars[2] explicilty because we know there will ALWAYS be 3 parts to a variable name
		// and we don't want to loop unless we absolutly have to (which would be the case if there was composite var)
		variableName = 	"impact4." +
				_global._internalDB.ModuleAliasLookup[varParts[1]] + "." +
				varParts[2];

		// loop if we have to -- most of the time (~99%) this loop should never run because var names
		// are only 3 parts long
		for(var i = 3; i < varParts.length; i++)
			variableName += "." + varParts[i];
	}

	// </scope_variable_section>
	

	// 0.2.34: return compoistes as objects
	if(_global._internalDB.DataTypes[variableName] != DB_TYPE_COMPOSITE)
		return _global._internalDB.ValuePairs[variableName];
	else
	{
		var compKeys = getKeyNames(variableName);
		set("retVal", {});
		for(var i = 0; i < compKeys.length; i++)
			set("retVal." + searchAndReplace(compKeys[i], ".", "_"), _global._internalDB.ValuePairs[compKeys[i]]);
		return retVal;
	}
}

// Casts an object into its right self, requires a scoped variable
_global.castObject = function(variableName, variableValue)
{
	var retVal;
	dataType = _global._internalDB.DataTypes[variableName];

	//st(variableName + " of value " + variableValue + " being set to a " + dataType);

	if (typeof(variableValue) == "undefined")
		retVal = variableValue;
	else if (dataType == DB_TYPE_OBJECT)
		retVal = variableValue;
	else if (dataType == DB_TYPE_INTEGER)
		retVal = Math.round((new Number(variableValue)).valueOf());
	else if (dataType == DB_TYPE_STRING)
		retVal = (new String(variableValue)).valueOf();
	else if (dataType == DB_TYPE_BOOLEAN)
	{
		if(typeof(variableValue) == "string") // probably came from XML
			retVal = (variableValue=="true") ? true : false;
		else
			retVal = (new Boolean(variableValue)).valueOf();
	}
	else if (dataType == DB_TYPE_FLOAT)
		retVal = parseFloat(variableValue).valueOf();
	else if (dataType == DB_TYPE_COMPOSITE)
		retVal = null; // a "composite" type is always null
	else
	{
		st("ERROR: castObject recieved " + variableName + " and could not make sense of it, dt is " + dataType);
		retVal = variableValue;
	}

	return retVal;
}

// Helper function that takes a "string" and makes a DB_TYPE_STRING out of it
function mapTextToFieldType(typeName)
{
	if (typeName == "string")
		return DB_TYPE_STRING;
	else if (typeName == "object")
		return DB_TYPE_OBJECT;
	else if (typeName == "boolean")
		return DB_TYPE_BOOLEAN;
	else if (typeName == "integer")
		return DB_TYPE_INTEGER;
	else if (typeName == "float")
		return DB_TYPE_FLOAT;
	else if (typeName == "composite")
		return DB_TYPE_COMPOSITE;
	else
	{
		st("ERROR: mapTextToFieldType was passed " + typeName + " and could not make sense of it");
		return DB_TYPE_STRING;
	}
}

// Helper functiont hat takes a type and maps a string to it
function mapFieldTypeToText(fieldType)
{
//st("mapFieldTypeToText: " + fieldType);

	if(fieldType == DB_TYPE_STRING)
		return "string";
	else if(fieldType == DB_TYPE_OBJECT)
		return "object";
	else if(fieldType == DB_TYPE_BOOLEAN)
		return "boolean";
	else if(fieldType == DB_TYPE_INTEGER)
		return "integer";
	else if(fieldType == DB_TYPE_FLOAT)
		return "float";
	else if(fieldType == DB_TYPE_COMPOSITE)
		return "composite";
	else
		return "";
}

// gets a list of all the variables that have the word subPart in it
_global.getKeyNames = function(subPart)
{
	var retVal;
	var i;
	retVal = new Array();
	for(i in _global._internalDB.ValuePairs)
	{
		if(i.indexOf(subPart) != -1)
			retVal.push(i);
	}
	return retVal;
}

// returns the access type of a variable
_global.getFieldAccess = function(variableName)
{
	return _global._internalDB.FieldAccess[scopeVariable(variableName)];
}

// returns the field's type
_global.getFieldType = function(variableName)
{
	return _global._internalDB.DataTypes[scopeVariable(variableName)];
}

// dumps all the name value pairs
_global.dumpNameValuePairs = function()
{
	var i;
	for(i in _global._internalDB.ValuePairs)
	{
		st(i + "[" + _global._internalDB.FieldAccess[i] + ", " + _global._internalDB.DataTypes[i] + "]: " + _global._internalDB.ValuePairs[i]);
	}
}

