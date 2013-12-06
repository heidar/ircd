#!/usr/bin/env ruby

require 'em-logger'
require 'eventmachine'
require 'json'
require 'logger'
require 'rubygems'
require 'socket'

class IRCd < EventMachine::Connection

  config = JSON.parse(IO.read('config.json'))
  @@clients = {}
  @@links = {}
  @@name = config['name']
  @@network = config['network']
  @@full = "#{@@name}.#{@@network}"
  @@version = 'pre-alpha'
  @@date = Time.now

  links = config['links']

  links.each do |s|
    # TODO: connect to server
    puts "Linking with #{s}..."
  end

  def receive_data(data)
    case data
    when /^NICK +(.+)$/i
      nick($1.strip)
    when /^USER +([^ ]+) +([0-9]+) +([^ ]+) +:*(.*)$/i
      user($1, $2, $3, $4)
    when /^QUIT :(.*)$/i
      quit($1)
    when /^PRIVMSG +([^ ]+) +:(.*)$/i
      privmsg($1, $2)
    when /^SERVER +([^ ]+) +([0-9]+) +([0-9]+) +:*(.*)$/i
      server($1, $2, $3, $4)
    end
  end

  def nick(nick)
    @@clients[nick] = { connection: self }
    $logger.info("NICK #{nick}")
  end

  def user(user, mode, unused, realname)
    port, ip = Socket.unpack_sockaddr_in(get_sockname)
    $logger.info("Connection from #{ip}:#{port}")
    nick = ''
    @@clients.each { |k,c| nick = k if c[:connection] == self }
    @@clients[nick][:user] = user
    @@clients[nick][:realname] = realname
    @@clients[nick][:ip] = ip
    @@clients[nick][:post] = port
    @@clients[nick][:host] = nil
    self.send_data(":#{@@full} 001 #{nick} :Welcome to the Internet Relay Network #{nick}!#{user}@#{ip}\n")
    self.send_data(":#{@@full} 002 #{nick} :Your host is #{@@full}, running version #{@@version}\n")
    self.send_data(":#{@@full} 003 #{nick} :This server was created #{@@date}\n")
    self.send_data(":#{@@full} 004 #{nick} :#{@@full} #{@@version} <available user modes> <available channel modes>\n")
    $logger.info("USER #{nick}!#{user}@#{ip} #{realname}")
  end

  def quit(msg)
    nick = @@clients.invert[connection: self]
    nick = ''
    @@clients.each { |k,c| nick = k if c[:connection] == self }
    @@clients.delete(nick)
    self.close_connection
    $logger.info("QUIT #{nick}")
  end

  def privmsg(target, msg)
    target_nick = target.strip
    target = @@clients[target]
    nick = ''
    @@clients.each { |k,c| nick = k if c[:connection] == self }
    client = @@clients[nick]
    user = client[:user]
    ip = client[:ip]
    if target.nil?
      self.send_data("#{@@full} 401 #{nick} #{target_nick} :No such nick/channel\n")
      return
    else
      target[:connection].send_data(":#{nick}!#{user}@#{ip} PRIVMSG #{target_nick} :#{msg}\n")
    end
  end

  def server(name, hopcount, token, info)
    @@servers[token] = { connection: self, name: name, info: info }
    $logger.info("SERVER #{name} #{hopcount} #{token} :#{info}")
  end
end

log = Logger.new(STDOUT)
$logger = EM::Logger.new(log)

EventMachine.run {
  host, port = "0.0.0.0", 6667
  EventMachine.start_server host, port, IRCd
  $logger.info "Listening on #{host}:#{port}..."
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
}