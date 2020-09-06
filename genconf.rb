#!/usr/bin/ruby
#
require 'yaml'

dirname = ARGV.shift
if not dirname then
  puts <<EOT
Usage: #{$0} <directory>"

Directory must contain the following:
  loadorder  - a listing of .lua files to load
  yamlbase.yaml  - Default yaml template to start from
  events/  - containing slotname.[parameter.]eventname.lua e.g: system.down.onActionStart.lua

#{$0} will generate a <directory>_start.lua (containing all files in loadorder)
EOT
  exit
end

explanation = <<EOT
So a little about the .conf file for Dual Universe.

It's not pure YAML, it's YAML-ish.
The main differences:
  * It allows duplicate keys, such as actionStart and actionStop. YAML doesn't.
  * It expects actionStart.args to be [down]. YAML prefers it to be "[down]" quotes included)

So the .gsub and _DELME_ stuff below is hackery to get around those limitations of YAML.
EOT


conf = YAML.load(IO.read("#{dirname}/yamlbase.yaml"))

handlers = {}
conf["handlers"] = handlers

counter = 1
Dir["#{dirname}/events/*.lua"].each do |eventfile|
  evt = {}
  evt["lua"] = IO.read(eventfile).gsub(/^\s+|\s+$/,'')
  slotname = ""
  evtname = ""
  if eventfile =~ /(\w+)\.(\w+)\.(\w+)\.lua$/ then
    evtname = $3
    slotname = $1
    evt["args"] = "_DELME_1__[#{$2}]_DELME_1__"
  elsif eventfile =~ /(\w+)\.(\w+)\.lua$/ then
    evtname = $2
    slotname = $1
  end
  if slotname then
    evtname = evtname + "_DELME_#{counter}__"
    counter = counter + 1
    handlers[slotname] ||= {}
    handlers[slotname][evtname] = evt
  end
end

startevt = {}
body = ""
IO.read("#{dirname}/loadorder").split.each do |fn|
  if fn =~ /^\w+.lua/ then
    body += IO.read("#{dirname}/" + fn)
  end
end
File.open("#{dirname}_start.lua", 'w') do |fout|
  fout.puts(body)
end

startevt["lua"] = body

handlers["system"] ||= {}
handlers["system"]["start"] = startevt

File.open("#{dirname}.conf", "w") do |fout|
  fout.puts YAML.dump(conf).gsub(/.DELME_\d+_./,'')
end
