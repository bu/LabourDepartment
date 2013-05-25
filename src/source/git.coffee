# git source
spawn = require("child_process").spawn
fs = require "fs"
path = require "path"

git_init = (jobInfo, callback) ->
    try
        git = spawn "git", ["clone", "-v", jobInfo.bundleObject.source.repoURL, "."], {
            cwd: jobInfo.workingDirectory,
        }

        git.stdout.on "data", (msg) -> process.send
            command: "msg"
            msg: msg.toString()

        git.stderr.on "data", (msg) -> process.send
            command: "msg"
            msg: msg.toString()

        git.on "exit", (code, signal) ->
            if code == 0
                return callback null
            
            return callback code
    catch error
        return callback error

git_update = (jobInfo, callback) ->
    try
        gitDirectory = path.join jobInfo.workingDirectory, ".git"

        # we check if the workingDirectory exists a .git
        fs.exists gitDirectory, (exist) =>
            if not exist
                return git_init jobInfo, callback

             git = spawn "git", ["pull", "-v"], {
                cwd: jobInfo.workingDirectory
            }

            git.stdout.on "data", (msg) -> process.send
                command: "msg"
                content: msg.toString()

            git.stderr.on "data", (msg) -> process.send
                command: "msg"
                content: msg.toString()

            git.on "exit", (code, signal) ->
                if code == 0
                    return callback null
            
                return callback code
    catch error
        return callback error

module.exports =
    update: git_update
