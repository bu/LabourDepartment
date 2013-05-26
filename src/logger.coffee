# native module
fs = require "fs"
path = require "path"

# 3rd party
moment = require "moment"

# logger class
class Logger
    constructor: (@target)->
        @LogTarget = target
        @LogFilepath = path.join __dirname, "log", @target + ".log"

        return (message) =>
            recorded_message = "[" + moment().format("YYYY-MM-DD HH:mm:ss:SSS Z") + "] #{@LogTarget}: " + message + "\n"

            fs.appendFile @LogFilepath, recorded_message , ->
                return true

# expose to outside
module.exports = (target) ->
    new Logger(target)
