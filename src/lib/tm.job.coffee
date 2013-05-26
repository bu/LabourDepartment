# Librray/Taskmaster.Job.coffee
# ================================
# This file will perform all worker job related stuff
# like:
#    * job queue
#    * get a job id
#    ....

# native modules
path = require "path"

# logger factory (to generate logger)
loggerFactory = require path.join __dirname, "..", "logger"

# log function used for all taskmaster
log = loggerFactory "TaskMaster"

# database
Accessor = require "Accessor_Singleton"
BuildRecord = Accessor "build_results", "MySQL"

# all awaiting job
awaitJob = []

# all worker info (reference to taskmaskter)
workers = null

createJob = (message, callback) ->
    BuildRecord._query "SELECT MAX(`build_number`) + 1 AS `next_build_number` FROM `build_results` WHERE `bundle` = '#{message.bundle}';", (err, data) ->
        if err
            log err
            return

        next_build_number = data[0].next_build_number

        if not next_build_number
            next_build_number = 1
        
        BuildRecord.create
            bundle: message.bundle
            build_number: next_build_number
            result: 0
        , (err, info) ->
             if err
                log err
                return
            
            message.jobBuildNumber = next_build_number
            awaitJob.push message
            
            return callback()

setWorkers = (tm_workers) ->
    workers = tm_workers

checkAwaitJobs = ->
    log "start to work on check for await job"

    if awaitJob.length == 0
        log "No job awaiting"

        # we check next time
        return setTimeout checkAwaitJobs, 5000
    
    log "okay, we got jobs to do (#{awaitJob.length} jobs), start to check for free worker"

    free_workers = []

    workers.map (worker) ->
        if worker.status is "FREE"
            free_workers.push worker

    log "free workers #{free_workers.length}"
    
    if free_workers.length == 0
        log "No worker free now, wait for next check"
        
        return setTimeout checkAwaitJobs, 5000
    
    free_workers.map (worker) ->
        if awaitJob.length == 0
            return

        new_job = awaitJob.pop()
        
        worker.process.send new_job
        worker.status = "BUSY"
        
        log "A job is assign to worker#" + worker.index + " - " + new_job.bundle

     return setTimeout checkAwaitJobs, 5000

updateStatus = (this_worker, build_result, callback) ->
    log "receive update status request #{this_worker.bundle} - #{build_result}"
    
    BuildRecord.update
        where: [
            ["bundle", "=", this_worker.bundle],
            "AND",
            ["build_number", "=", this_worker.buildNumber]
        ]
    ,
        result: build_result
    , (err, info) ->
        if err
            log err
            return callback()
        
        log "successfully update databse"
        
        return callback()

notifyAll = (this_worker, notifications, build_result, callback) ->
    log "now we should notify via notifiers"

    iterateOverNotify = (this_worker, notifications, build_result, index, callback) ->
        if notifications.length == index
            return callback()
        
        this_task = notifications[index]

        this_task.build_result = build_result
        this_task.bundle = this_worker.bundle
        this_task.buildNumber = this_worker.buildNumber
        
        try
            notifier = require path.join __dirname, "..", "notify", this_task.type
        catch error
            return callback "Cannot found task [#{this_task.type}]", index
                
        notifier this_task, (err) ->
            # if task operator occur issues, we report back to the caller
            if err
                return callback err, index
            
            setImmediate ->
                iterateOverNotify this_worker,build_result, notifications, index + 1, callback

    iterateOverNotify this_worker, notifications, build_result, 0, callback

module.exports =
    createJob: createJob
    setWorkers: setWorkers
    checkAwaitJobs: checkAwaitJobs
    notifyAll: notifyAll
    updateStatus: updateStatus
