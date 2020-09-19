#!/usr/bin/ruby

puts "Building keypress files based on names"

keypresses = {
    'forward' => 'FORWARD',
    'backward' => 'BACKWARD',
    'yawleft' => 'YAWLEFT',
    'yawright' => 'YAWRIGHT',
    'strafeleft' => 'STRAFELEFT',
    'straferight' => 'STRAFERIGHT',
    'left' => 'LEFT',
    'right' => 'RIGHT',
    'up' => 'UP',
    'down' => 'DOWN',
    'lalt' => 'LALT',
    'lshift' => 'LSHIFT',
    'gear' => 'GEAR',
    'light' => 'LIGHT',
    'brake' => 'BRAKE',
    'groundaltitudeup' => 'GROUNDALTITUDEUP',
    'groundaltitudedown' => 'GROUNDALTITUDEDOWN',
    'speedup' => 'SPEEDUP',
    'speeddown' => 'SPEEDDOWN',
    'antigravity' => 'ANTIGRAVITY',
    'booster' => 'BOOSTER',
    'warp' => 'WARP',
    'stopengines' => 'STOPENGINES',
}

loopers = {
    'brake' => 'BRAKE',
    'speedup' => 'SPEEDUP',
    'speeddown' => 'SPEEDDOWN',
    'groundaltitudeup' => 'GROUNDALTITUDEUP',
    'groundaltitudedown' => 'GROUNDALTITUDEDOWN',
}

keypresses.each do |k,v|
    File.open("system.#{k}.actionStart.lua", "w") do |fout|
	    fout.puts %Q[press("#{v}")]
    end
    File.open("system.#{k}.actionStop.lua", "w") do |fout|
	    fout.puts %Q[release("#{v}")]
    end
end

loopers.each do |k,v|
    File.open("system.#{k}.actionLoop.lua", "w") do |fout|
	    fout.puts %Q[loopKey("#{v}")]
    end
end
