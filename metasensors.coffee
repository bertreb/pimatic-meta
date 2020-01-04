module.exports = (env) =>
  Promise = env.require 'bluebird'
  t = env.require('decl-api').types
  _ = env.require('lodash')
  
  class MetasensorsPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass 'MetasensorsPresence',
        configDef: deviceConfigDef.MetasensorsPresence
        createCallback: (config, lastState) =>
          includes = []
          config.includes = includes if config.includes?.length == 0
          return new MetasensorsPresence(config, @framework, lastState)

      @framework.deviceManager.registerDeviceClass 'MetasensorsSwitch',
        configDef: deviceConfigDef.MetasensorsSwitch
        createCallback: (config, lastState) =>
          return new MetasensorsSwitch(config, lastState)

  class MetasensorsPresence extends env.devices.PresenceSensor

    _presence: false
    _sensors: []
    _includes: []
    _trigger: ""

    attributes:
      presence:
        description: "The current state of the sensor"
        type: t.boolean
        labels: ['present', 'absent']
      trigger:
        description: "The device that triggered the alarm"
        type: t.string

    actions:
      changePresenceTo:
        params:
          presence:
            type: "boolean"

    constructor: (@config, @framework, lastState) ->
      @id = @config.id
      @name = @config.name
      @_presence = lastState?.presence?.value or off
      @_includes = @config.includes
      @_autoReset = if @config.autoReset? then @config.autoReset else false
      @_andTrigger = if @config.andTrigger? then @config.andTrigger else false
      @_triggerAutoReset()
      @_nrOfActiveStates = 0
      
      if @_includes.length == 0
        env.logger.debug "config contains no sensors to include"

      #@framework.once "after init", => 
      for id in @_includes
        device = @framework.deviceManager.devices[id]
        if device?
          registerSensor = (event, expectedValue) =>
            sensor = device
            sensor.on event, (value) =>
              if value == expectedValue
                @_setState(true, sensor)
              else
                @_setState(false, sensor)
            env.logger.debug "device #{sensor.id} registered as sensor for #{@id}"
          if device instanceof env.devices.PresenceSensor
            registerSensor 'presence', true
          else if device instanceof env.devices.ContactSensor
            registerSensor 'contact', false
        else
          env.logger.info "device with id #{id} not found"
          throw new Error "device with id #{id} not found"
              
      super()     

    changePresenceTo: (presence) ->
      @_setPresence(presence)
      @_triggerAutoReset()
      return Promise.resolve()

    _triggerAutoReset: ->
      if @config.autoReset and @_presence
        clearTimeout(@_resetPresenceTimeout)
        @_resetPresenceTimeout = setTimeout(( =>
          if @_destroyed then return
          @_setPresence(no)
          @_setTrigger("")
        ), @config.resetTime)

    _setState: (state, sensor) =>
      if state
        @_nrOfActiveStates += 1
        if (@_andTrigger and @_nrOfActiveStates == @_includes.length) or !@_andTrigger
          @_setPresence(yes)
          @_setTrigger(sensor.name)
        if @config.autoReset is true
          @_triggerAutoReset()
      else 
        @_nrOfActiveStates -= 1 if @_nrOfActiveStates > 0
        if @config.autoReset is false #check if 1 or more included sensors are 'expected state'
            if @_nrOfActiveStates == 0
              @_setPresence(no)
              @_setTrigger("")
            else return # still 1 or more sensors are in 'expected state'

    _setTrigger: (trigger) ->
      if @_trigger is trigger then return
      @_trigger = trigger
      @emit 'trigger', trigger

    getPresence: -> Promise.resolve @_presence
    getTrigger: -> Promise.resolve @_trigger

    destroy: ->
      clearTimeout(@_resetPresenceTimeout)
      super()

  class MetasensorsSwitch extends env.devices.SwitchActuator

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @_includes = @config.includes
      @_state = lastState?.state?.value
      super()

    changeStateTo: (state) ->
      @_setState(state)
      return Promise.resolve()
           
    destroy: ->
      super()

  return new MetasensorsPlugin
