# App.coffee
# ==============

# External Modules
# -------------------

# native modules
spawn = require("child_process").spawn

# LabourDepartment module
# while we loading, before we receive signal "READY", we cannot operator
taskmaster = spawn "node", ["./taskmaster"],
    stdio: ["ipc"]
        
taskmaster.on "message", (message) ->
    if message.signal is "READY"
        console.log "we are ready"
    
    # we ask to halt the server
    taskmaster.send
        command: "HALT"

taskmaster.on "close", ->
    process.exit 0
