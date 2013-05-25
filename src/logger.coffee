# 3rd party
moment = require "moment"

class Logger
    @LogTarget: ""

    constructor: (@target)->
        @LogTarget = target

        return (message) =>
            console.log "[" + moment().format("YYYY-MM-DD HH:mm:ss:SSS Z") + "] #{@LogTarget}: " + message

exports.logFactory = (target) ->
    new Logger(target)
