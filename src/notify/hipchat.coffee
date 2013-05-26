# 
path = require "path"

# logger factory (to generate logger)
loggerFactory = require path.join __dirname, "..", "logger"

# log function used for all taskmaster
log = loggerFactory "Hipchat"

request = require "request"

module.exports = (job, callback) ->
    sent_message = "#{job.bundle} - ##{job.buildNumber} "

    if job.build_result
        sent_message += "Success"
        message_color = "green"
    else
        sent_message += "Failure"
        message_color = "red"

    request
        uri: "https://api.hipchat.com/v1/rooms/message",
        method: "POST"
        form:
            room_id: job.room_id
            from: "LabourDept"
            message: sent_message
            auth_token: job.token
            color: message_color
    , (err, response, body) ->
        log JSON.stringify
            room_id: job.room_id
            from: "LaborDept"
            message: sent_message
            auth_token: job.token
            color: message_color

        log err
        log response
        log body
