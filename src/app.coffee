# App.coffee
# ==============

# External Modules
# -------------------

# native modules
path = require "path"
spawn = require("child_process").spawn
fs = require "fs"

# Opening check
factoryDirectory = path.join __dirname, "factory"
logDirectory = path.join __dirname, "log"

fs.mkdirSync factoryDirectory unless fs.existsSync factoryDirectory
fs.mkdirSync logDirectory unless fs.existsSync logDirectory

# TaskMaster module
# ----------------------
taskmaster_callable = false

# while we loading, before we receive signal "READY", we cannot operator
taskmaster = spawn "node", ["./taskmaster"],
    stdio: ["ipc"]
        
taskmaster.on "message", (message) ->
    if message.signal is "READY"
        taskmaster_callable = true

taskmaster.on "close", ->
    console.log "taskmaster is dead"
    process.exit 0

# Timer module
# ---------------
timer = require path.join __dirname, "timer"
timer.init taskmaster
