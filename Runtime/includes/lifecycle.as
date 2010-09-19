/* This file supports the life cycle */

// module is not used right now
_global.MODULE_LIFECYCLE_UNLOADED		= 0;

// module has a loadModule executed on it, but the preloader has not finished
_global.MODULE_LIFECYCLE_LOADING		= 1;

// loaded by runtime, means that the runtime is setting it up
// initalize is called under this state, and the preloader has finished
_global.MODULE_LIFECYCLE_LOADED			= 2;

// loaded and running, but not finalizable
_global.MODULE_LIFECYCLE_RUNNING		= 3;

// module will be okay if it needs to be finalized 
// module sets it by calling selfFinalizable
_global.MODULE_LIFECYCLE_RUNNINGFINALIZABLE	= 4;

// work is done, used in the autoadvance mode
// so that a module says, "i'm done" by calling selfFinalize
_global.MODULE_LIFECYCLE_FINALIZED		= 5;

// anything above this value is running
// e.g. if(getValue("lifeCycleState") > MODULE_LIFECYCLE_RUNNINGRANGE) st("i'm running");
_global.MODULE_LIFECYCLE_RUNNINGRANGE = _global.MODULE_LIFECYCLE_LOADED;
