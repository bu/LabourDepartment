spawn = require("child_process").spawn
fs = require "fs"
path = require "path"

doJob = (task, job, callback) ->
    # first, we create a new temporaily shell file
    temp_file_path = path.join job.workingDirectory, new Date().getTime() + ".sh"

    returnCallback = (callback_value) ->
        fs.unlink temp_file_path, (err) ->
            callback callback_value

    fs.writeFile temp_file_path, task.script, { mode: 484 }, (err) ->
        if err
            return callback "Cannot not create temporiily shell file"
        
        try
            sh = spawn temp_file_path, [], {
                cwd: job.workingDirectory
            }

            sh.stdout.on "data", (m) -> console.log m.toString()
            sh.stderr.on "data", (m) -> console.log m.toString()

            sh.on "exit", (code, signal) ->
                if code == 0
                    return returnCallback null
                
                return returnCallback code

        catch error
            return returnCallback error

module.exports =
    do: doJob
