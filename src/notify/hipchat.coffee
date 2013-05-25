# 
path = require "path"

# logger factory (to generate logger)
loggerFactory = require path.join __dirname, "..", "logger"

# log function used for all taskmaster
log = loggerFactory "Hipchat"

request = require "request"

module.exports = (job, callback) ->
    request
        uri: "https://api.hipchat.com/v1/rooms/message",
        method: "POST"
        form:
            room_id: job.room_id
            from: "LaborDept"
            message: "Build is #{job.build_result}"
            auth_token: job.token
    , (err, response, body) ->
        console.log err, response, body
        log err
        log response
        log body
