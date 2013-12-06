#!/usr/bin/env ruby

require 'json'
require 'rgl/adjacency'
require 'rgl/dot'

servers = JSON.parse(IO.read('servers.json'))

network = []

servers.each do |s|
  servers.each do |sp|
    unless s.eql? sp
      network.push(s)
      network.push(sp)
    end
  end
end

graph = RGL::DirectedAdjacencyGraph.new
0.step(network.size-1, 2) { |i| graph.add_edge(network[i], network[i+1]) }
graph.write_to_graphic_file('png')
puts "Saving graph as graph.dot and graph.png"
puts "#{servers.size} servers with total #{network.size/2} links"