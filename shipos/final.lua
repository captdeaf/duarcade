function initialize()
    system.print("Initializing ShipOS 0.01")
    PHYSICS.update()
    HUDConfig.start()
    MainScreen.start()
    AutoPilotScreen.reset()
    local body = DU.getNearestBody(PHYSICS.position)
    system.print("Nearest: " .. body.name)
end
