# Goonstation Dream Maker (DM) Code Guidelines

These code guidelines are for DM code developed for the Goonstation codebase. Future submissions should conform to the latest version of these standards prior to being merged.

[toc]

## Formatting Guidelines

### Pathing

Absolute pathing should be used to delimit `/datum`s and their `/proc`s. `/var`s for a given `/datum` may be nested, but no further than one layer.

#### Example

```csharp
// Non-compliant
datum
	datum1
		var
			var1 = 1
			var2 = 2
		proc
			proc1()
				// ...
			proc2()
				// ...
				
// Compliant
/datum/datum1
	var/var1 = 1
	var/var2 = 2

/datum/datum1/proc/proc1()
	// ...
/datum/datum1/proc/proc2()
	// ...
```

## Code Style Guidelines
