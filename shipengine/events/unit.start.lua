-- element widgets
-- For now we have to alternate between PVP and non-PVP widgets to have them on the same side.
_autoconf.displayCategoryPanel(weapon, weapon_size, "Weapons", "weapon", true)
core.show()
_autoconf.displayCategoryPanel(radar, radar_size, "Periscope", "periscope")
placeRadar = true
if atmofueltank_size > 0 then
    _autoconf.displayCategoryPanel(atmofueltank, atmofueltank_size, "Atmo Fuel", "fuel_container")
    if placeRadar then
        _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
        placeRadar = false
    end
end
if spacefueltank_size > 0 then
    _autoconf.displayCategoryPanel(spacefueltank, spacefueltank_size, "Space Fuel", "fuel_container")
    if placeRadar then
        _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
        placeRadar = false
    end
end
_autoconf.displayCategoryPanel(rocketfueltank, rocketfueltank_size, "Rocket Fuel", "fuel_container")
if placeRadar then -- We either have only rockets or no fuel tanks at all, uncommon for usual vessels
    _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
    placeRadar = false
end
if antigrav ~= nil then antigrav.show() end
if warpdrive ~= nil then warpdrive.show() end
if gyro ~= nil then gyro.show() end

-- freeze the player in he is remote controlling the construct
if unit.isRemoteControlled() == 1 then
    system.freeze(1)
end

-- landing gear
-- make sure every gears are synchonized with the first
gearExtended = (unit.isAnyLandingGearExtended() == 1) -- make sure it's a lua boolean
if gearExtended then
    unit.extendLandingGears()
else
    unit.retractLandingGears()
end


