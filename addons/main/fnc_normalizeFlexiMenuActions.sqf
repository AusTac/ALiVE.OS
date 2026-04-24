#include "\x\alive\addons\main\script_component.hpp"
SCRIPT(normalizeFlexiMenuActions);

/* ----------------------------------------------------------------------------
Function: ALiVE_fnc_normalizeFlexiMenuActions

Description:
Walks a CBA flexiMenu `_menus` array and converts any code-block action
(position 1 of a menu entry) into the SQF source-string form that CBA's
`buttonSetAction` call in `fnc_list.sqf` / `fnc_menu.sqf` requires.

Historical context:
CBA's flexiMenu passes the menu entry's action slot straight into BI's
`buttonSetAction`, which is strictly typed to STRING (SQF source code).
Most ALiVE MenuDef.sqf files were written using `{...}` code blocks in
that slot, which errors at runtime with:

    Error buttonsetaction: Type code, expected String

This helper lets existing MenuDef files keep their ergonomic code-block
syntax and still produce valid menu arrays for CBA. Call once at the end
of each MenuDef (just before returning `_menus`).

Transformation:
For each menu-entry's action slot that is type CODE:
- `str _code` returns the SQF source representation, with nested quotes
  already escaped and preprocessor macros already expanded (macros are
  resolved at preprocess time, before `str` sees the code block).
- Wrapping the result as `"call <source>"` gives a string that
  `buttonSetAction` compiles and executes at click time.

The helper is idempotent: entries already in string form are skipped.

Parameters:
    _input : ARRAY - either a list of menus in the shape
             `[[header, [entry, entry, ...]], ...]` (the common pattern
             where a MenuDef builds a `_menus` variable) OR a single
             menu in the shape `[header, [entry, entry, ...]]` (the
             pattern where a switch-based MenuDef returns one menu per
             case). Detection by shape: if the first element's first
             element is a STRING, it's treated as a single menu (headers
             start with strings like "main"); otherwise as a list.

Returns:
    The same input array (modified in place), so the helper can be
    used inline: `_menus = _menus call ALiVE_fnc_normalizeFlexiMenuActions;`

Examples:
(begin example)
// List-of-menus form (most MenuDef files)
_menus = _menus call ALiVE_fnc_normalizeFlexiMenuActions;

// Single-menu form (switch-based returns, e.g. sys_adminactions)
switch (_menuName) do {
    case "main": { <menu> call ALiVE_fnc_normalizeFlexiMenuActions };
};
(end)

See Also:
CBA `fnc_list.sqf` / `fnc_menu.sqf` line 100-ish buttonSetAction calls.

Author:
Jman
---------------------------------------------------------------------------- */

params [["_input", [], [[]]]];

diag_log format ["[ALIVE_fnc_normalizeFlexiMenuActions] entry: type=%1, count=%2", typeName _input, count _input];

if (count _input == 0) exitWith {_input};

// Shape detection: single menu vs list of menus. A single menu has the
// header array as its first element, and a header starts with the menu-
// name STRING. A list has menu arrays as its elements, and those menus'
// first elements are header ARRAYs.
private _firstSub = _input select 0;
private _isSingleMenu =
    _firstSub isEqualType [] &&
    {count _firstSub > 0} &&
    {(_firstSub select 0) isEqualType ""};

private _menus = if (_isSingleMenu) then {[_input]} else {_input};

{
    private _menu = _x;
    // Defensive: skip anything not array-shaped (string / number / object
    // / nil). A flexiMenu entry should always be an array, but some
    // MenuDef patterns produce unusual shapes (e.g. a stray list wrapping
    // that the detection heuristic can't fully disambiguate).
    if (!(_menu isEqualType [])) then {
        diag_log format ["[ALIVE_fnc_normalizeFlexiMenuActions] skipping non-array menu at index %1: type=%2, value=%3", _forEachIndex, typeName _menu, _menu];
    } else {
        if (count _menu >= 2 && {(_menu select 1) isEqualType []}) then {
            private _entries = _menu select 1;
            {
                if (_x isEqualType [] && {count _x >= 2} && {(_x select 1) isEqualType {}}) then {
                    _x set [1, format ["call %1", str (_x select 1)]];
                };
            } forEach _entries;
        };
    };
} forEach _menus;

_input
