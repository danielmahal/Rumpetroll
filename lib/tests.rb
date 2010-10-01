#!/usr/bin/ruby

require "enumerableExtensions.rb"
require "TadpoleSystem.rb"

tadpoles = []



sys = TadpoleSystem.new;


10.times do |i|
end
# sys.createTadpole(TadpoleConnectionAgent.new)
# sys.createTadpole(AIAgent.new)


while true
  sys.update
  sleep 0.4
end
