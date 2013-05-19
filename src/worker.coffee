#
# This is the worker of Labour
# it will listen to the message from the Taskmaster
#

# log
log = require("util").log

# events
EventEmitter = require("events").EventEmitter
ev = new EventEmitter

# load avavilable tasks
task = require "./tasks"

process.on "message", (message) ->
    message_delivered = ev.emit message.command, message

    log "#{message.command} is not able to process" if message_delivered is no

ev.on "setProcessTitle", (message) ->
    # Setup the process title
    process.title = "Labour Worker #" + message.index

   
