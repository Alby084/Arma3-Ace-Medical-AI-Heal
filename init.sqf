// Add event handler to all AI units
{
    _x addEventHandler ["HandleDamage", {
        params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];
        
        // Check if the unit is injured and not already being treated
        if (_damage > 0 && {!(_unit getVariable ["ace_medical_isTreated", false])}) then {
            // Mark the unit as being treated
            _unit setVariable ["ace_medical_isTreated", true, true];
            
            // Find nearby friendly AI units (excluding players)
            _nearbyUnits = (_unit nearEntities ["CAManBase", 50]) select {side _x == side _unit && _x != _unit && !isPlayer _x};
            
            // Find nearby medic units
            _nearbyMedics = _nearbyUnits select {_x getUnitTrait "medic"};
            
            // Check if the injured unit is critically injured or unconscious
            _isCritical = _unit getVariable ["ace_medical_isCritical", false];
            _isUnconscious = _unit getVariable ["ACE_isUnconscious", false];
            
            // If there are medics nearby, order them to heal the injured unit
            if (count _nearbyMedics > 0) then {
                _medicUnit = selectRandom _nearbyMedics;
                
                // Spawn a new execution thread for the healing logic
                [_unit, _medicUnit, _isCritical, _isUnconscious] spawn {
                    params ["_unit", "_medicUnit", "_isCritical", "_isUnconscious"];
                    
                    // If the injured unit is critically injured or unconscious, prioritize healing regardless of combat engagement
                    if (_isCritical || _isUnconscious) then {
                        _medicUnit doMove (getPos _unit);
                    } else {
                        // If the injured unit is not critical or unconscious, check if the medic is not currently engaging enemies
                        if (!(_medicUnit getVariable ["isEngagingEnemies", false])) then {
                            // Set the medic as engaging enemies if they have knowledge of any nearby enemies
                            if (count (_medicUnit targets [true, 50]) > 0) then {
                                _medicUnit setVariable ["isEngagingEnemies", true];
                            } else {
                                // If the medic is available, order them to move to the injured unit
                                _medicUnit doMove (getPos _unit);
                            };
                        };
                    };
                    
                    // Wait for the medic to reach the injured unit
                    waitUntil {_medicUnit distance _unit < 3 || !alive _unit};
                    
                    // If the medic reached the injured unit and the unit is still alive, heal them
                    if (_medicUnit distance _unit < 3 && alive _unit) then {
                        _medicUnit action ["HealSoldier", _unit];
                    };
                    
                    // Set the medic as no longer engaging enemies
                    _medicUnit setVariable ["isEngagingEnemies", false];
                    
                    // Wait for the treatment to be completed
                    waitUntil {!alive _unit || {!(_unit getVariable ["ace_medical_isTreated", false])}};
                    
                    // Mark the unit as no longer being treated
                    _unit setVariable ["ace_medical_isTreated", false, true];
                };
            } else {
                // If no medics nearby, spawn a new execution thread for the self-healing logic
                [_unit] spawn {
                    params ["_unit"];
                    
                    // Order the unit to heal themselves
                    _unit action ["HealSoldier", _unit];
                    
                    // Wait for the treatment to be completed
                    waitUntil {!alive _unit || {!(_unit getVariable ["ace_medical_isTreated", false])}};
                    
                    // Mark the unit as no longer being treated
                    _unit setVariable ["ace_medical_isTreated", false, true];
                };
            };
        };
        
        _damage
    }];
} forEach allUnits;