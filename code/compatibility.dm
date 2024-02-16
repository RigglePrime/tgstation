// This file contains defines and procs that the old code doesn't
// Yes, I could rewrite new code but why? This makes it easier to update. -Riggle

///////////////
// DIRECT IO //
///////////////

#define DIRECT_OUTPUT(A, B) A << B
#define DIRECT_INPUT(A, B) A >> B
#define SEND_IMAGE(target, image) DIRECT_OUTPUT(target, image)
#define SEND_SOUND(target, sound) DIRECT_OUTPUT(target, sound)
#define SEND_TEXT(target, text) DIRECT_OUTPUT(target, text)
#define WRITE_FILE(file, text) DIRECT_OUTPUT(file, text)
#define READ_FILE(file, text) DIRECT_INPUT(file, text)


/////////////////
// PROTECTIONS //
/////////////////

///Protects a datum from being VV'd
#define GENERAL_PROTECT_DATUM(Path)\
##Path/can_vv_get(var_name){\
	return FALSE;\
}\
##Path/vv_edit_var(var_name, var_value){\
	return FALSE;\
}\
##Path/CanProcCall(procname){\
	return FALSE;\
}


/////////////
// GLOBALS //
/////////////

/// Creates a global initializer with a given InitValue expression, do not use
#define GLOBAL_MANAGED(X, InitValue)\
/datum/controller/global_vars/proc/InitGlobal##X(){\
	##X = ##InitValue;\
	gvars_datum_init_order += #X;\
}
/// Creates an empty global initializer, do not use
#define GLOBAL_UNMANAGED(X) /datum/controller/global_vars/proc/InitGlobal##X() { return; }

/// Prevents a given global from being VV'd
#ifndef TESTING
#define GLOBAL_PROTECT(X)\
/datum/controller/global_vars/InitGlobal##X(){\
	..();\
	gvars_datum_protected_varlist[#X] = TRUE;\
}
#else
#define GLOBAL_PROTECT(X)
#endif

/// Standard BYOND global, do not use
#define GLOBAL_REAL_VAR(X) var/global/##X

/// Standard typed BYOND global, do not use
#define GLOBAL_REAL(X, Typepath) var/global##Typepath/##X

/// Defines a global var on the controller, do not use
#define GLOBAL_RAW(X) /datum/controller/global_vars/var/global##X

/// Create an untyped global with an initializer expression
#define GLOBAL_VAR_INIT(X, InitValue) GLOBAL_RAW(/##X); GLOBAL_MANAGED(X, InitValue)

/// Create a global const var, do not use
#define GLOBAL_VAR_CONST(X, InitValue) GLOBAL_RAW(/const/##X) = InitValue; GLOBAL_UNMANAGED(X)

/// Create a list global with an initializer expression
#define GLOBAL_LIST_INIT(X, InitValue) GLOBAL_RAW(/list/##X); GLOBAL_MANAGED(X, InitValue)

/// Create a list global that is initialized as an empty list
#define GLOBAL_LIST_EMPTY(X) GLOBAL_LIST_INIT(X, list())

/// Create a typed list global with an initializer expression
#define GLOBAL_LIST_INIT_TYPED(X, Typepath, InitValue) GLOBAL_RAW(/list##Typepath/X); GLOBAL_MANAGED(X, InitValue)

/// Create a typed list global that is initialized as an empty list
#define GLOBAL_LIST_EMPTY_TYPED(X, Typepath) GLOBAL_LIST_INIT_TYPED(X, Typepath, list())

/// Create a typed global with an initializer expression
#define GLOBAL_DATUM_INIT(X, Typepath, InitValue) GLOBAL_RAW(Typepath/##X); GLOBAL_MANAGED(X, InitValue)

/// Create an untyped null global
#define GLOBAL_VAR(X) GLOBAL_RAW(/##X); GLOBAL_UNMANAGED(X)

/// Create a null global list
#define GLOBAL_LIST(X) GLOBAL_RAW(/list/##X); GLOBAL_UNMANAGED(X)

/// Create a typed null global
#define GLOBAL_DATUM(X, Typepath) GLOBAL_RAW(Typepath/##X); GLOBAL_UNMANAGED(X)


////////////
// NAMEOF //
////////////

#define NAMEOF(datum, X) (#X || ##datum.##X)


///////////
// SPANS //
///////////

#define span_boldannounce(str) ("<span class='boldannounce'>" + str + "</span>")


///////////////
// SUBSYSTEM //
///////////////

#define SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/subsystem/##X);\
/datum/subsystem/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
}\
/datum/subsystem/##X


/////////////
// LOGGING //
/////////////

/// Wrapper for compatibility. It shrimply just outputs to `world.log`.
/// Parameters:
/// - D (sting): text to log
/proc/log_world(text)
    SEND_TEXT(world.log, text)

/// Wrapper for compatibility. This does not do much of anything like the original, just a wrapper. For compatibility.
/// Parameters:
/// - target (client|world): what do we want to output to?
/// - message_html (string): thing to be sent
/proc/to_chat(target, message_html)
	if(!target)
		return
	SEND_TEXT(target, message_html)

/// Tries to adit a var, handling edit rejections. Here for compatibility purposes. Prints a helpful message!
/// Parameters:
/// - D (datum): the datum that's to be edited
/// - var_name (any): the name of the variable
/// - var_value (any): new desired value
/// Returns: TRUE if the edit was successful, else false
/client/proc/try_edit_var(datum/D, var_name, var_value)
	if(!D)
		return FALSE
	if(!D.vv_edit_var(var_name, var_value))
		if(src) // Probably unnecessary but I'm leaving it
			to_chat(src, "Your edit was rejected by the object.")
		return FALSE
	return TRUE

///////////////////
// LIBRARY CALLS //
///////////////////

// 515 split call for external libraries into call_ext
#if DM_VERSION < 515
#define call_ext call
#endif

//////////
// TIME //
//////////

#define MILLISECONDS *0.01

#define DECISECONDS *1 //the base unit all of these defines are scaled by, because byond uses that as a unit of measurement for some fucking reason

#define SECONDS *10

#define MINUTES SECONDS*60

#define HOURS MINUTES*60

#define TICKS *world.tick_lag
