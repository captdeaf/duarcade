-- Rezoix's DU-hud
-- https://github.com/Rezoix/DU-hud

local HUDRezoix = {
    name = "Rezoix's DU HUD",
    key = 'hudrezoix',
    opts = {
        enabled = false,
    },
}

function HUDRezoix.render()
    local altitude = core.getAltitude()
    local velocity = core.getVelocity()
    local speed = vec3(velocity):len()
    local worldV = vec3(core.getWorldVertical())
    local constrF = vec3(core.getConstructWorldOrientationForward())
    local constrR = vec3(core.getConstructWorldOrientationRight())
    local constrV = vec3(core.getConstructWorldOrientationUp())

    local pitch = gyro.getPitch()--180 - getRoll(worldV, constrR, constrF)
    local roll = gyro.getRoll()--getRoll(worldV, constrF, constrR)
    local bottomText = "ROLL"
    local mode = 0

    if (altitude == 0) then
        mode = 1
    else
        mode = 0
    end

    if (mode == 1) then
        if (speed > 5) then
            pitch = math.deg(math.atan(velocity[2], velocity[3])) - 90
            roll = math.deg(math.atan(velocity[2], velocity[1])) - 90
        else
            pitch = 0
            roll = 0
        end
        bottomText = "YAW"
    end

    content = [[
        <style>
            body {margin: 0}
            svg {display:block; position:absolute; top:0; left:0}
            .majorLine {stroke:aqua;opacity:0.7;stroke-width:3;fill-opacity:0;}
            .minorLine {stroke:aqua;opacity:0.3;stroke-width:3;fill-opacity:0;}
            .text {fill:aqua;font-family:Montserrat;font-weight:bold}

            #space {}
            #ecu {}
            #atmos {}


        </style>
        <svg height="100%" width="100%" viewBox="0 0 1920 1080">
            <g class="majorLine">
                <line x1="939" y1="537" x2="957" y2="519"/>
                <line x1="939" y1="543" x2="957" y2="561"/>
                <line x1="981" y1="537" x2="963" y2="519"/>
                <line x1="981" y1="543" x2="963" y2="561"/>

                <line x1="932" y1="540" x2="945" y2="540"/>
                <line x1="988" y1="540" x2="975" y2="540"/>
                <line x1="960" y1="512" x2="960" y2="525"/>
                <line x1="960" y1="568" x2="960" y2="555"/>

                <g style="opacity:0.2">
                    <line x1="920" y1="540" x2="840" y2="540"/>
                    <line x1="1000" y1="540" x2="1080" y2="540"/>
                    <line x1="960" y1="500" x2="960" y2="470"/>
                    <line x1="960" y1="580" x2="960" y2="610"/>
                </g>

                <path d="M 700 0 L 740 35 Q 960 55 1180 35 L 1220 0"/>
                <path d="M 792 550 L 785 550 L 785 650 L 792 650"/>
            </g>


            <g>
                <polygon points="782,540 800,535 800,545" style="fill:rgb(42, 234, 248);opacity:0.7"/>
                <polygon points="1138,540 1120,535 1120,545" style="fill:rgb(42, 234, 248);opacity:0.7"/>
                <polygon points="960,725 955,707 965,707" style="fill:rgb(42, 234, 248);opacity:0.7"/>
            </g>

            <g class="text">
                <g font-size=10>
                    <text x="785" y="530" text-anchor="start">PITCH</text>
                    <text x="1135" y="530" text-anchor="end">PITCH</text>
                    <text x="960" y="688" text-anchor="middle">ROLL</text>
                    <text x="790" y="660" text-anchor="start">THRL</text>
                </g>
                <g font-size=15>
                    <text x="1020" y="33" text-anchor="middle" id="space">SPACE</text>
                    <text x="900" y="33" text-anchor="middle" id="atmos">ATMOS</text>
                    <text x="960" y="35" text-anchor="middle" id="ecu">ECU</text>
                </g>

            </g>]]


    pitchC = math.floor(pitch)
    for i = pitchC-25,pitchC+25 do
        if (i%10==0) then
            num = i
            if (num > 180) then
                num = -180 + 10*(i-18)
            elseif (num < -170) then
                num = 180 + 10*(i+18)
            end

            content = content..[[<g transform="translate(0 ]]..(-i*5 + pitch*5)..[[)">
                <text x="745" y="540" style="fill:rgb(1, 165, 177);text-anchor:end;font-size:12;font-family:Montserrat;font-weight:bold">]]..num..[[</text>
                <text x="1175" y="540" style="fill:rgb(1, 165, 177);text-anchor:start;font-size:12;font-family:Montserrat;font-weight:bold">]]..num..[[</text></g>]]
        end

        len = 5
        if (i%10==0) then
            len = 30
        elseif (i%5==0) then
            len = 15
        end

        content = content..[[
        <g transform="translate(0 ]]..(-i*5 + pitch*5)..[[)">
            <line x1="]]..(780-len)..[[" y1="540" x2="780" y2="540"style="stroke:rgb(1, 165, 177);opacity:0.3;stroke-width:3"/>
            <line x1="]]..(1140+len)..[[" y1="540" x2="1140" y2="540"style="stroke:rgb(1, 165, 177);opacity:0.3;stroke-width:3"/></g>]]

    end

    rollC = math.floor(roll)
    for i = rollC-35,rollC+35 do
        if (i%10==0) then
            num = math.abs(i)
            if (num > 180) then
                num = 180 + (180-num)
            end
            content = content..[[<g transform="rotate(]]..(i - roll)..[[,960,460)">
            <text x="960" y="760" style="fill:rgb(1, 165, 177);text-anchor:middle;font-size:12;font-family:Montserrat;font-weight:bold">]]..num..[[</text></g>]]
        end

        len = 5
        if (i%10==0) then
            len = 15
        elseif (i%5==0) then
            len = 10
        end

        content = content..[[<g transform="rotate(]]..(i - roll)..[[,960,460)">
        <line x1="960" y1="730" x2="960" y2="]]..(730+len)..[[" style="stroke:rgb(1, 165, 177);opacity:0.3;stroke-width:2"/></g>]]
    end

    -- -unit.getThrottle()*0.97
    content = content..[[<g transform="translate(0 ]]..(-50)..[[)">
            <polygon points="788,650 800,647 800,653" style="fill:rgb(1, 165, 177);opacity:0.7"/>
        </g>]]


    content = content..[[

        </svg>
    ]]
    return content
end

HUDConfig.addHUD(HUDRezoix)
