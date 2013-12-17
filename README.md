### IRCd

Experimental prototype of an IRCd written in Ruby using EventMachine.

The main goal of this project is to attempt to create and implement a simple
mesh network structure for linking IRC servers together.

### Usage

Install Ruby 2.0.0 and install the eventmachine, rgl and em-logger gems.

Run the ircd.rb file.

Connect using TCP to 0.0.0.0:6667

Issue a NICK message: NICK yournick

Issue a USER message: USER youruser 0 * :Your Name

Then you should be connected.

To private message nother user: PRIVMSG user :Message string

To quit: QUIT :Message
