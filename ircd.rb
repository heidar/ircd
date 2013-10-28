#!/usr/bin/env ruby

require 'em-logger'
require 'eventmachine'
require 'logger'
require 'rubygems'
require 'socket'

class IRCd < EventMachine::Connection

  @@clients = {}

  def post_init
    port, ip = Socket.unpack_sockaddr_in(get_sockname)
    $logger.info "Connection from #{ip}:#{port}"
  end

  def receive_data(data)
    case data
    when /^NICK +(.+)$/i
      nick($1.strip)
    when /^USER +([^ ]+) +([0-9]+) +([^ ]+) +:*(.*)$/i
      user($1, $2, $3, $4)
    end
  end

  def nick(nick)
    @@clients[nick] = { connection: self }
    $logger.info "NICK #{nick}"
  end

  def user(user, mode, unused, realname)
    nick = @@clients.key({ connection: self })
    @@clients[nick][:user] = user
    @@clients[nick][:realname] = realname
    $logger.info "USER #{nick}!#{user}@host #{realname}"
  end
end

log = Logger.new(STDOUT)
$logger = EM::Logger.new(log)

EventMachine.run {
  host, port = "0.0.0.0", 6667
  EventMachine.start_server host, port, IRCd
  $logger.info "Listening on #{host}:#{port}..."
}