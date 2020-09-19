-- HUD Configuration
-- This is loaded fairly early on, so HUD instances can
-- register themselves with HUDConfig

local HUDConfig = {
    name = "HUD Config",
    HUDS = {},
    OPTIONS = {},
    Choice = 1,
    ENABLED = {},
}

local function getOpt(opt)
    if not databank.hasKey(opt.key) then
        return opt.val
    end
    if opt.datatype == 'bool' then
        return databank.getIntValue(opt.key) ~= 0
    end
    if opt.datatype == 'int' then
        return databank.getIntValue(opt.key)
    end
    if opt.datatype == 'float' then
        return databank.getFloatValue(opt.key)
    end
end
local function setOpt(opt, val)
    opt.hud.opts[opt.id] = val
    if opt.datatype == 'bool' then
        databank.setIntValue(opt.key, val and 1 or 0)
    end
    if opt.datatype == 'int' then
        return databank.setIntValue(opt.key, val)
    end
    if opt.datatype == 'float' then
        return databank.setFloatValue(opt.key, val)
    end
end

local hudodd = false

local HUDUI = {}

HUDUI.BoolHandler = {
    render = function(opt)
        if getOpt(opt) then
	    return "YES"
	else
	    return "NO"
	end
    end,
    onSpace = function(opt)
        local val = not getOpt(opt)
        setOpt(opt, val)
	if opt.onset then
	    opt.onset(opt, val)
	end
    end,
}

HUDUI.IntHandler = {
    render = function(opt)
        local v = getOpt(opt)
	return string.format("%d", v)
    end,
    onLeft = function(opt)
        local val = getOpt(opt) - opt.step
	if val < opt.min then
	    val = opt.min
	end
        setOpt(opt, val)
	if opt.onset then
	    opt.onset(opt, val)
	end
    end,
    onRight = function(opt)
        local val = getOpt(opt) + opt.step
	if val > opt.max then
	    val = opt.max
	end
        setOpt(opt, val)

	if opt.onset then
	    opt.onset(opt, val)
	end
    end,
}

function HUDConfig.setEnabled(opt, val)
    local hud = opt.hud
    hud.opts.enabled = val
    if val then
	HUDConfig.ENABLED[hud.name] = hud
	if hud.start then
	    hud.start(hud)
	end
    else
	HUDConfig.ENABLED[hud.name] = nil
	if hud.stop then
	    hud.stop(hud)
	end
    end
end

function HUDConfig.addHUD(hud)
    local cls = "heven"
    if hudodd then
        cls = "hodd"
    end
    hudodd = not hudodd
    table.insert(HUDConfig.HUDS, hud)
    if type(hud.opts.enabled) == type(true) then
	table.insert(HUDConfig.OPTIONS, {
	    cls = cls, -- for HUDUI rendering and grouping
	    hud = hud,
	    id = 'enabled',
	    datatype = 'bool',
	    val = hud.opts.enabled,
	    onset = HUDConfig.setEnabled,
	    name = "Enable " .. hud.name,
	    uihandler = HUDUI.BoolHandler,
	    key = hud.key .. '.' .. 'enabled',
	})
    end
    if hud.config then
        for k, v in pairs(hud.config) do
	  if not v.cls then v.cls = cls end
	  if not v.hud then v.hud = hud end
	  if not v.val then v.val = hud.opts[k] end
	  if not v.name then v.name = k end
	  if not v.key then v.key = hud.key .. '.' .. k end
	  if not v.id then v.id = k end
	  table.insert(HUDConfig.OPTIONS, v)
	end
    end
end

HUDConfig.Style = el('style', [[
  .hudlist { position: fixed; display: block; left: 20vw; top: 35vh; }
  .heven { background-color: #333399; }
  .hodd { background-color: #339933; }
  .hi { display: block; width: 35vw; height: 4vh; margin: 0; padding: 5px; font-size: 2vh; color: white; }
  .hsel { background-color: yellow; color: black; }
  .hv { display: block; float: right; margin-right: 1vw; }
]])

HUDConfig.onFORWARD = function()
    HUDConfig.Choice = HUDConfig.Choice - 1
    if HUDConfig.Choice < 1 then
	HUDConfig.Choice = #HUDConfig.OPTIONS
    end
end

HUDConfig.onBACKWARD = function()
    HUDConfig.Choice = HUDConfig.Choice + 1
    if HUDConfig.Choice > #HUDConfig.OPTIONS then
	HUDConfig.Choice = 1
    end
end

HUDConfig.onYAWLEFT = function()
    local opt = HUDConfig.OPTIONS[HUDConfig.Choice]
    if opt.uihandler.onLeft then
	opt.uihandler.onLeft(opt)
    end
end

HUDConfig.onYAWRIGHT = function()
    local opt = HUDConfig.OPTIONS[HUDConfig.Choice]
    if opt.uihandler.onRight then
	opt.uihandler.onRight(opt)
    end
end

HUDConfig.onUP = function()
    local opt = HUDConfig.OPTIONS[HUDConfig.Choice]
    if opt.uihandler.onSpace then
	opt.uihandler.onSpace(opt)
    end
end

HUDConfig.render = function()
    local tabs = {}
    local chosen = nil
    for i, opt in ipairs(HUDConfig.OPTIONS) do
	local cls = opt.cls .. ' hi'
	if i == HUDConfig.Choice then
	    cls = 'hi hsel'
	    chosen = opt
	end
	table.insert(tabs, el('div', {class=cls}, {opt.name, el('div', {class='hv'}, opt.uihandler.render(opt))}))
    end
    return HUDConfig.Style .. el('div', {class='hudlist'}, tabs)
end

HUDConfig.start = function()
  -- In here we load all data from databank for each option.
  for i, opt in pairs(HUDConfig.OPTIONS) do
      local val = getOpt(opt)
      if opt.onset then
	  opt.onset(opt, val)
      end
      opt.hud.opts[opt.id] = val
  end
end
