## Example project using genconf.rb

For this example project, we're going to have a programming board find all
damaged elements on a construct, and display them on a screen.

First, create a directory, repairscreen/, and copy over the sample.yaml file to
repairscreen/yamlbase.yaml. Give it a name: Repair Screen. There are two slots
we need linked for this: CoreUnit and ScreenUnit. So we delete everything but
those two sections (we don't need fuel tanks!)

Let's talk about structure: We want to do the following:

1) On start, turn on the screen, run a check, and start a timer to check again
every 10 seconds. We don't want to do this every second since it's intensive on
the network and LUA script to check every element.

2) On the timer tick, run the check and update the screen.

3) On stop, turn off the screen.

## The dependencies of checkElements code

According to the codex, Core exposes four functions that we want to use:

1) getElementIdList() - This returns UIDs for every single element on the
construct.

2) getElementMaxHitPointsById(uid) - Returns max hit points for a given element

3) getElementHitPointsById(uid) - Returns current hit points for a given element

4) getElementNameById(uid) - Gets their name.

Functions that Screen exposes that we need:

1) activate() - turn on.

2) deactivate() - turn off.

3) setHTML(html) - display things.

## checkElements()

We want checkElements to 1) Find all damaged items, and 2) Display them. So
here is some code to do that:

```
function checkElements()
    local uids = core.getElementIdList()

    local damaged = {}
    for _, uid in ipairs(uids) do
        local max = core.getElementMaxHitPointsById(uid)
        local cur = core.getElementHitPointsById(uid)
        if cur < max then
            table.insert(damaged, string.format("%.5d/%.5d %s", math.floor(cur), math.floor(max), core.getElementName(uid)))
        end
    end

    if #damaged < 1 then
        screen.setHTML([[
        <div style="font-size: 400%; padding: 2vw;">
        <h2 style="color: green; font-size: 100%;">All systems okay</h2><br>
        </div>
        ]])
    else
        screen.setHTML([[
        <div style="font-size: 400%; padding: 2vw;">
        <h2 style="color: red; font-size: 100%;">Alert: Element Damage</h2><br>
        ]] .. table.concat(damaged, '<br>') .. "</div>")
    end
end

-- And run it for the first time:
checkElements()
```

Put this code into the `repairscreen/checkElements.lua` file, and add
the line `checkElements.lua` to `repairscreen/loadorder` file.

Now we need to add a timer to tick every 10 seconds. Create a file `repairscreen/events/unit.start.lua` containing:

```
unit.setTimer('check', 10)
```

And another for the tick: `repairscreen/events/unit.check.tick.lua`

```
checkElements()
```

## 'Uploading' the code to a programming board

Dual Universe has basically 3 ways of uploading code: An autoconf file, which
only works for controllers (such as hovercraft control seats); Pasting Lua
Config YAML or JSON from Clipboard; or manually entering via cut+paste.

Because we're working with a programming board here, we want to use 'Paste Lua from Clipboard'

Run "ruby genconf.rb repairscreen" to generate repairscreen.conf (for controllers) and repairscreen.yaml.

Open repairscreen.yaml and copy its entire contents into the clipboard, then
right-click on the programming board and select "Paste Lua Configuration from
Clipboard".

Because programming boards can't use autoconf, we have to manually link the
core and screen. Do so with Build tool 6 ("Link Elements"), and name the slots
'core' and 'screen'

Activate programming board, and tada!
