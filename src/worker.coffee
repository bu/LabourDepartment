# native modules
fs = require "fs"
path = require "path"

# 3rdpary
moment = require "moment"
q = require "q"

# worker info
worker_info = {}

# log
log = (message) ->
    recorded_message = "Worker ##{worker_info.id}: " + message

    process.send
        command: "msg"
        msg: recorded_message

# events
EventEmitter = require("events").EventEmitter
ev = new EventEmitter

# listen message from process
process.on "message", (message) ->
    message_delivered = ev.emit message.command, message
    log "#{message.command} is not able to process" if message_delivered is no

# prepare for the source
prepareMaterial = (jobInfo) ->
    deferred = q.defer()

    checkoutSource = ->
        log "now we start to checkout the source"
        
        try
            sourcePreparer = require path.join __dirname, "source", jobInfo.bundleObject.source.type
        catch error
            returndeferred.reject
                stage: "Error while prepare the material for the build"
                error: error
    
        sourcePreparer.update jobInfo, (err) ->
            if err
                 return deferred.reject
                    stage: "Error while prepare the material for the build"
                    error: error

            log("succesfully prepared material")

            deferred.resolve jobInfo

    setImmediate ->
        log "start to preare material"

        log "we check for the factory directory"

        fs.exists jobInfo.workingDirectory, (exist) ->
            if not exist
                log "directory is not exists, so we create it"

                return fs.mkdir jobInfo.workingDirectory, (err) ->
                    checkoutSource()
                
            log "directory is exists, so we just use it"

            checkoutSource()
        
    return deferred.promise

executeTasks = (type, jobInfo) ->
    deferred = q.defer()
    
    setImmediate ->
        # if there is no this attribute
        if not jobInfo.bundleObject[type]?
            log " there is no any #{type} action need to be done "
            return deferred.resolve jobInfo
        
        # or exists, but empty
        if jobInfo.bundleObject[type].length == 0
            log " there is no any #{type} action need to be done "
            return deferred.resolve jobInfo
        
        # then we got things to do
        iterateOverTasks = (tasks, index, callback) ->
            if tasks.length == index
                return callback null, index
            
            this_task = tasks[index]

            try
                taskOperator = require path.join __dirname, "task", this_task.task
            catch error
                return callback "Cannot found task [#{this_task.task}]", index
                    
            taskOperator.do this_task, jobInfo, (err) ->
                # if task operator occur issues, we report back to the caller
                if err
                    return callback err, index
                
                setImmediate ->
                    iterateOverTasks tasks, (index + 1), callback
        
        iterateOverTasks jobInfo.bundleObject[type], 0, (err, index) ->
            if err
                return deferred.reject
                    stage: "Error happens while doing #{type} - #{index} task"
                    error: err

            deferred.resolve jobInfo
        
        
    return deferred.promise

executeBeforeBuild = (jobInfo) ->
    executeTasks("before_build", jobInfo)

executeBuildTasks = (jobInfo) ->
    executeTasks("build_tasks", jobInfo)

executeAfterBuild = (jobInfo) ->
    executeTasks("after_build", jobInfo)

reportResult = (jobInfo) ->
    log "build successfully"
    
    process.send
        command: "jobFinished"

reportBadResult = (err) ->
    log "bad build"
    log err

    process.send
        command: "jobFinished"

# events
ev.on "setProcessTitle", (message) ->
    # Setup the process title
    worker_info.id = message.index

ev.on "runBundle", (message) ->
    # first we will build jobInfo
    # this is an object that will be passed by in the flow

    # let taskmaster know we've been started
    process.send
        command: "jobStarted"
        bundle: message.bundle
        buildNumber: message.jobBuildNumber # current job build number eg: #306

    jobInfo =
        # current job related
        buildNumber: message.jobBuildNumber # current job build number eg: #306
        createdAt: new Date().getTime() # when this job is created?
        finishedAt: null # when this job is finished? (either success or exit by fail)

        # working diretory
        workingDirectory: path.join __dirname, "factory", message.bundle
        workerId: worker_info.id
        workingBundle: message.bundle
        
        # about the bundle (task descritpion file)
        bundleLocation: path.join __dirname, "bundle", message.bundle + ".json"
    
    log "jobInfo created"

    # load the json
    fs.readFile jobInfo.bundleLocation, (err, bundle_buffer) ->
        if err
            ev.emit "buildFail", {
                stage: "Error while reading Bundle file"
                error: error

                bundle: jobInfo.bundle
                buildNumber: jobInfo.buildNumber
            }
            
            return
        
        # and then we try to fetch it
        try
            jobInfo.bundleObject = JSON.parse bundle_buffer.toString()

        catch error
            ev.emit "buildFail", {
                stage: "Error while parsing Bundle file"
                error: error

                bundle: jobInfo.bundle
                buildNumber: jobInfo.buildNumber
            }
            
            # stop here
            return
        
        # after we successfully parse the bundle, then we can start work on it
        log "start working on main pipeline"

        prepareMaterial(jobInfo)
            .then(executeBeforeBuild)
            .then(executeBuildTasks)
            .then(executeAfterBuild)
            .then(reportResult)
            .fail(reportBadResult)
            .done()
        
ev.on "buildFail", (message) ->
    console.log message
