# Taskmaster.coffee
# =====================

# External Module Include
# --------------------------

# native modules
path = require "path"
spawn = require("child_process").spawn

# logger factory (to generate logger)
loggerFactory = require path.join __dirname, "logger"

# log function used for all taskmaster
log = loggerFactory "TaskMaster"

# Module-scope variables
# ------------------------

# we store all worker information here
workers = []

# this is how many worker we should keep in the same time
MAX_WORKER_CONCURRENCY = 2

# Receive parent message
# ------------------------

process.on "message", (message) ->
    if message.command is "HALT"
        workers.map (worker) ->
            worker.stop = true
            worker.process.kill()
        
        log "all worker dead, bye"
        
        process.exit(0)

process.on "SIGTERM", ->
    log "im dead, bye"
    

# Functions
# ----------------

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
    
    # TODO:
    #  for each message it was required to write into file
    #  if worker is dead, then we should close it too
    #  when start work, need to open a new file
    #  log/BundleName-BuildNumber.log
    this_worker.process.on "message", (msg) ->
        if msg.command is "msg"

            log JSON.stringify msg
        if msg.command is "jobFinished"
            this_worker.status = "DONE"
            log "Worker - #{index}: job Finished"
        if msg.command is "jobStarted"
            this_worker.logger = loggerFactory "#{msg.bundle}-#{msg.buildNumber}"

            this_worker.status = "WORKING"
            log "Worker - #{index}: job Started"
    
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

# Start working
# -----------------
startWork 0, ->
    log "Successfully started all workers"

    # send signal to app.coffee
    process.send
        signal: "READY"
