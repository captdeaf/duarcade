#!/usr/bin/ruby

puts "Building keypress files based on names"

keypresses = {
    'yawleft' => 'LEFT',
    'yawright' => 'RIGHT',
    'forward' => 'UP',
    'backward' => 'DOWN',
    'up' => 'BUTTON',
    'down' => 'BUTTON2',
    'left' => 'Q',
    'right' => 'E',
}

keypresses.each do |k,v|
    File.open("system.#{k}.actionStart.lua", "w") do |fout|
	    fout.puts %Q[press("#{v}")]
    end
    File.open("system.#{k}.actionStop.lua", "w") do |fout|
	    fout.puts %Q[release("#{v}")]
    end
end
