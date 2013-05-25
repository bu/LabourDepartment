# App.coffee
# ==============

# External Modules
# -------------------

# native modules
path = require "path"
spawn = require("child_process").spawn

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
