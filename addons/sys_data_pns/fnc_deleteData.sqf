/* ----------------------------------------------------------------------------
Function: ALIVE_fnc_deleteData

Description:
Deletes data from an external datasource (pns)

Parameters:
Object - data handler object
Array - Array of module name (string) and then unique identifer (string)

Returns:
Array - Returns a response error or data in the form of key value pairs

Examples:
(begin example)
    [ _logic, [ _module, [_key,_key etc], _uid ] ] call ALIVE_fnc_deleteData;
(end)

Author:
Tupolov
Peer Reviewed:

---------------------------------------------------------------------------- */
#include "script_component.hpp"
SCRIPT(deleteData_pns);

["SYS DATA PNS - Operation deleteData unsupported! Called by %1 - input %2",_fnc_scriptNameParent,_this] call ALiVE_fnc_dump;

"SYS DATA ERROR";
