# Timer coffee
#

#
fs = require "fs"
path = require "path"

CronJob = require("cron").CronJob

taskmaster = null
cronJobs = []

clearAllExistingTimer = (callback) ->
    # we go over each job, and tell them to stop
    cronJobs.map (job) ->
        job.stop()
    
    # after we tell them to stop, we clear the jobs container
    cronJobs = []
    
    # and return back to the remaining flow
    callback()

iterateOverBundles = (bundles, index, callback) ->
    if bundles.length == index
        return callback()
    
    this_bundle = bundles[index]
    
    fs.readFile path.join(__dirname, "bundle", this_bundle), (err, content_buffer) ->
        try
            bundle_obj = JSON.parse content_buffer.toString()
        catch err
            return iterateOverBundles bundles, index + 1, callback
        
        if not bundle_obj.trigger
            return iterateOverBundles bundles, index + 1, callback

        if not bundle_obj.trigger.cron
            return iterateOverBundles bundles, index + 1, callback
        
        job = new CronJob
            cronTime: bundle_obj.trigger.cron
            onTick: ->
                console.log "Cronjob is started for #{bundle_obj.name} at #{bundle_obj.trigger.cron}"

                taskmaster.send
                    command: "runBundle"
                    bundle: bundle_obj.name
                    trigger: "Timer"
            start: true

        cronJobs.push job

        console.log "Cronjob is setuped for #{bundle_obj.name} at #{bundle_obj.trigger.cron}"
        
        return iterateOverBundles bundles, index + 1, callback

# this function will go over all bundle and create corresponding tasks
reloadTimer = (tm) ->
    if tm
        taskmaster = tm
    
    if not taskmaster
        throw new Error "Taskmaster is not given"

    clearAllExistingTimer ->
        fs.readdir path.join(__dirname, "bundle"), (err, files) ->
            if err
                throw new Error "Bundle is not ready."
            
            setImmediate ->
                iterateOverBundles files, 0, ->
                    console.log "Timer reloaded"

module.exports =
    reload: reloadTimer
    init: reloadTimer
