-- Dealing with Dual Universe's planetary and moon bodies,
-- Gravity, Locations, Bookmark styles, etc

local DU = {}

function DU.getNearestBody(loc)
    -- Far planet for "default"
    local nearest = DU.BODIES[4]
    local ndist = (loc - nearest.center):len()
    for id, body in pairs(DU.BODIES) do
        local bdist = (loc - body.center):len()
	if bdist < ndist then
	    ndist = bdist
	    nearest = body
	end
    end
    return nearest
end

function DU.distanceFromSurface(loc, body)
    return (loc - body.center):len() - body.radius
end
