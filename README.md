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

  dirname.conf        <-- The generated .conf file for autoconf for chairs.
  dirname.yaml        <-- The generated .yaml file for cut+paste to
                          programming board.
```

To build dirname_start.lua and dirname.conf, run `ruby genconf.rb dirname`.

build.sh_example is an example build script that I use to validate my code
(with lua compiler), run genconf.rb, then copy the .conf file over to dual
universe's lua/autoconf/custom/ directory.

## Included projects

In here I have two projects: Arcade, and ShipOS.

Arcade contains 3 (at time of writing) games, and is designed for a control
seat, databank and Screen, to play games.

ShipOS is my in-progress modular HUD management and autopilot script.

You can see more about them in their individual README.md files

## Example project using genconf.rb

I've added "Repair Screen" project, open up "repairscreen" directory above to
read through its instructions.
