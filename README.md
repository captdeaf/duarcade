## Dual Universe Build System

Dual Universe allows for .conf files to be created that contain all the code
and slot specifications for a project. The files in this directory are intended
to build .conf files from source .lua files and a base .yaml template.

A project directory looks like this:
```
  dirname/
          yamlbase.yaml     <-- Base slot configuration for the .conf file

          events/
		 slotname.eventname.lua <--  Event handler without an argument.
		 slotname.arg.eventname.lua <-- With an argument
		 -- Examples:
	         unit.start.lua       <-- Event handler for "unit.start"
		 unit.min.tick.lua    <-- Event handler for "unit.tick(min)"
		 system.forward.actionStart.lua
		 system.update.lua
		 system.flush.lua

	  loadorder     <-- Text file containing a list of .lua files to load
			    as system.start event. e.g: "start.lua",
			    "physics.lua", "hud.lua"

          start.lua     <-- Example filenames, listed in loadorder. These are
	  physics.lua       read and joined all into one big start function
	  hud.lua

  dirname_start.lua   <-- Generated start function from loadorder.
                          If you have an error "system.start line 234",
			  dirname_start.lua helps you find it.

  dirname.conf        <-- The generated .conf file
```
