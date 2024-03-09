# Arma3 Ace Medical AI Heal
<br>
must have ace medical installed for script to work 
<br>
<br>
can remove

```SQF
&& !isPlayer _x
```

from

```SQF
_nearbyUnits = (_unit nearEntities ["CAManBase", 50]) select {side _x == side _unit && _x != _unit && !isPlayer _x};
```

if you want to the AI to target players as well
