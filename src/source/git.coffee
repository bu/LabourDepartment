# git source
spawn = require("child_process").spawn
fs = require "fs"
path = require "path"

# init
git_init = (jobInfo, callback) ->
    git = spawn "git", ["clone", "-v", jobInfo.bundleObject.source.repoURL, "."], {
        cwd: jobInfo.workingDirectory
    }

    git.stdout.on "data", (m) -> console.log m.toString()
    git.stderr.on "data", (m) -> console.log m.toString()

    git.on "exit", (code, signal) ->
        if code == 0
            return callback(null)
        
        return callback(code)

git_update = (jobInfo, callback) ->
    gitDirectory = path.join jobInfo.workingDirectory, ".git"

    # we check if the workingDirectory exists a .git
    fs.exists gitDirectory, (exist) ->
        if not exist
            return git_init jobInfo, callback

         git = spawn "git", ["pull", "-v"], {
            cwd: jobInfo.workingDirectory
        }

        git.stdout.on "data", (m) -> console.log m.toString()
        git.stderr.on "data", (m) -> console.log m.toString()

        git.on "exit", (code, signal) ->
            if code == 0
                return callback(null)
        
            return callback(code)

module.exports = {
    init: git_init
    update: git_update
}
