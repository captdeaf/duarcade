#!/usr/bin/ruby
#
require 'yaml'
require 'json'

# Only minify the _start
MINIFY = false
MINIFY_ALL = false

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

$jsconf = {}
$jsslots = {}

$jsslotkeys = {}

def jsaddslot(num, name)
    $jsslots["#{num}"] = { "name" => name, "type" => { "events" => [], "methods" => []}}
    $jsslotkeys[name] = num
end

jsaddslot(-3, 'library')
jsaddslot(-2, 'system')
jsaddslot(-1, 'unit')

i = 0
conf['slots'].each do |k, v|
  jsaddslot(i, k)
  i = i + 1
end

handlers = {}
conf["handlers"] = handlers

jshandlers = []

SIGNATURES = {}
SIGNATURES['tick'] = 'tick(timerId)'

counter = 1
Dir["#{dirname}/events/*.lua"].each do |eventfile|
  evt = {}
  evt["lua"] = IO.read(eventfile).gsub(/^\s+|\s+$/,'')
  slotname = ""
  evtname = ""
  argname = ""
  jsfilt = {}
  if eventfile =~ /(\w+)\.(\w+)\.(\w+)\.lua$/ then
    evtname = $3
    slotname = $1
    argname = $2
    evt["args"] = "_DELME_1__[#{argname}]_DELME_1__"
    jsfilt["args"] = [{"value" => argname}]
  elsif eventfile =~ /(\w+)\.(\w+)\.lua$/ then
    evtname = $2
    slotname = $1
  end
  if slotname then
    evtname = evtname
    handlers[slotname] ||= {}
    handlers[slotname][evtname + "_DELME_#{counter}__"] = evt
    counter = counter + 1
  end

  jsfilt['slotKey'] = "#{$jsslotkeys[slotname]}"
  if SIGNATURES.key?(evtname) then
      jsfilt['signature'] = SIGNATURES[evtname]
  elsif jsfilt['args'] then
      jsfilt['signature'] = "#{evtname}(#{argname})"
  else
      jsfilt['signature'] = "#{evtname}()"
  end
  jsfilt['args'] ||= []
  jshandler = {}
  jshandler['code'] = evt['lua']
  jshandler['filter'] = jsfilt

  jshandlers << jshandler
end

startevt = {}
body = ""
IO.readlines("#{dirname}/loadorder").each do |fn|
  fn.chomp!
  if fn =~ /^\w+.lua$/ then
    body += IO.read("#{dirname}/" + fn).gsub(/^\s+/,'')
  end
end
File.open("#{dirname}_start.lua", 'w') do |fout|
  fout.puts(body)
end

startevt["lua"] = body

handlers["system"] ||= {}
handlers["system"]["start"] = startevt

def minify(script)
  # Now minify everything
      IO.popen(['luamin', '-c'], mode='r+') do |lm|
	lm.puts script
	lm.close_write
	return lm.gets(nil)
      end
end

if MINIFY then
  if MINIFY_ALL then
    puts "Minifying All, this may take some time"
    handlers.each do |k,slot|
      slot.each do |k,evt|
	puts "Minifying #{evt['name']}"
	evt['lua'] = minify(evt['lua'])
      end
    end
  else
    puts "Minifying system.start"
    startevt['lua'] = minify(startevt['lua'])
  end
end

jshandlers << {
  'code' => startevt['lua'],
  'filter' => {
    'slotKey' => '-2',
    'signature' => 'start()',
    'args' => [],
  }
}

File.open("#{dirname}.conf", "w") do |fout|
  fout.puts YAML.dump(conf).gsub(/.DELME_\d+_./,'')
end

jshandlers.each_with_index do |jsh, idx|
  jsh['key'] = "#{idx}"
end


File.open("#{dirname}.yaml", "w") do |fout|
  jsconf = {
    'slots' => $jsslots,
    'handlers' => jshandlers,
    'methods' => [],
    'events' => [],
  }
  fout.puts YAML.dump(jsconf).gsub(/.DELME_\d+_./,'')
end
