# Taskmaster

moment = require "moment"

# log
log = (message) ->
    console.log "[" + moment().format("YYYY-MM-DD HH:mm:SS Z") + "] TaskMaster: " + message
 
spawn = require("child_process").spawn

# we store all worker information here
workers = []

# this is how many worker we should keep in the same time
MAX_WORKER_CONCURRENCY = 2

process.on "message", (msg) ->
    log msg

startWork = (index, callback, force) ->
    # if we had been reach the maximun, then we go back
    if index == MAX_WORKER_CONCURRENCY
        return callback()
    
    log "start create worker #{index}"

    this_worker = workers[index] = {}
    
    this_worker.process = spawn "node", ["./worker"],
        stdio: ["ipc"]
    
    this_worker.stop = false
    
    # setup process title
    this_worker.process.send {
        command: "setProcessTitle",
        index: index
    }
    
    # creeated
    log "created worker #{index} - pid #{this_worker.process.pid}"
    
    this_worker.process.on "close", ->
        # if this worker is not closed by taskmaster, then we restart it
        if not workers[index].stop
            log "server ##{index} is stopped, and restart "

            startWork index, ->
                return
            , true
    
    setImmediate ->
        # if it was called by restart event, then we don't go next
        if force
            return callback
        
        # otherwise, we just move to next one
        startWork index+1, callback

startWork 0, ->
    log "Done"

    workers[0].process.send {
        command: "runBundle",
        bundle: "Dummy",
        jobBuildNumber: 15
    }

    workers[1].process.send {
        command: "runBundle",
        bundle: "EumarkhScrapper",
        jobBuildNumber: 1
    }
