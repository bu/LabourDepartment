# native module
fs = require "fs"
path = require "path"

# 3rd party
moment = require "moment"

class Logger
    @LogTarget: ""

    constructor: (@target)->
        @LogTarget = target
        @LogFilepath = path.join __dirname, "log", @target + ".log"

        return (message) =>
            recorded_message = "[" + moment().format("YYYY-MM-DD HH:mm:ss:SSS Z") + "] #{@LogTarget}: " + message + "\n"

            fs.appendFile @LogFilepath, recorded_message , ->
                return true

module.exports = (target) ->
    new Logger(target)
