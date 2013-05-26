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

# job_helper
jobHelper = require path.join __dirname, "lib", "tm.job"

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

    if message.command is "runBundle"
        log "received job request - trigger by #{message.trigger}"

        jobHelper.createJob message, ->
            log "processed job request - trigger by #{message.trigger}"

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
    this_worker.status = "FREE"
    this_worker.index = index

    # setup process title
    this_worker.process.send
        command: "setProcessTitle"
        index: index
    
    # creeated
    log "created worker #{index} - pid #{this_worker.process.pid}"
    
    this_worker.process.on "message", (msg) ->
        if msg.command is "msg"
            this_worker.logger msg.msg
        
        if msg.command is "jobFinished"
            log "receive worker said job is done, then we should update the database - result is #{msg.success} for #{this_worker.bundle} @ #{this_worker.buildNumber}"

            jobHelper.updateStatus this_worker, msg.success, ->
                jobHelper.notifyAll this_worker, this_worker.notify, msg.success, ->
                    log "all notifier is done"
                    
                    this_worker.status = "FREE"
                    this_worker.logger = null
                    this_worker.bundle = null
                    this_worker.buildNumber = null
                    this_worker.notify = null
                    
                    log "Worker - #{index}: job Finished"
 
        if msg.command is "jobNotifies"
            this_worker.notify = msg.notify ? []

        if msg.command is "jobStarted"
            this_worker.status = "BUSY"
            this_worker.logger = loggerFactory "#{msg.bundle}-#{msg.buildNumber}"
            this_worker.bundle = msg.bundle
            this_worker.buildNumber = msg.buildNumber

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

    # start check if there is await job
    setImmediate ->
        log "now we assign workers to await job checker"

        jobHelper.setWorkers workers
        jobHelper.checkAwaitJobs()
