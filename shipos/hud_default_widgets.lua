-- Widget HUDS from default ship configuration

local function displayCategoryPanel(elements, title, widgettype)
    if #elements > 0 then
        local panel = system.createWidgetPanel(title)
	local widget = system.createWidget(panel, widgettype)
	for i, el in pairs(elements) do
	    system.addDataToWidget(elements[i].getDataId(), widget)
	end
	return panel
    end
end

local function addFuelWidget(name, varname)
  local widget = {
      name = "Default " .. name .. " Widget",
      key = 'defaultwidget' .. varname,
      opts = {
	  enabled = false,
      },
  }

  function widget.start(self)
      self.panel = displayCategoryPanel(_G.fueltanks[varname], name .. " Fuel", "fuel_container")
  end

  function widget.stop(self)
      system.destroyWidgetPanel(self.panel)
  end

  HUDConfig.addHUD(widget)
end

addFuelWidget("Atmo", "atmo")
addFuelWidget("Space", "space")
addFuelWidget("Rocket", "rocket")

local HUDWidgetCore = {
    name = "Hide Controller Default",
    key = 'defaultwidgetcore',
    opts = {
	enabled = false,
    },
}

function HUDWidgetCore.start(self)
    unit.hide()
end

function HUDWidgetCore.stop(self)
    unit.show()
end

HUDConfig.addHUD(HUDWidgetCore)
