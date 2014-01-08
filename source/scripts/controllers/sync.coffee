Base           = require 'base'
Jandal         = require 'jandal/build/client'
event          = require '../utils/event'
config         = require '../utils/config'
queue          = require '../utils/queue'
User           = require '../models/user'
CollectionSync = require './sync/collection'
ModelSync      = require './sync/model'

Jandal.handle 'sockjs'

# -----------------------------------------------------------------------------
# Sync Controller
# -----------------------------------------------------------------------------

Sync =

  online: no
  disabled: no

  connect: () ->
    @connection = new SockJS("http://#{ config.sync }")
    @socket = new Jandal(@connection)
    @connection.onopen = @open

  open: ->
    Sync.online = yes
    Sync.auth()
    event.trigger 'sync:open'

  auth: ->
    @socket.emit 'user.auth', User.id, User.token, ->
      console.log 'we are online'

  namespace: (name) ->
    namespace = null

    ns = ->
      if namespace then return namespace
      return namespace = Sync.socket.namespace(name)

    return {}=

      on: (event, fn) ->
        ns().on(event,fn)

      emit: (event, arg1, arg2, arg3) ->
        if Sync.disabled then return
        if Sync.online and Sync.socket
          ns().emit(event, arg1, arg2, arg3)
        else
          queue.push [name, event, arg1, arg2, arg3]

  disable: (fn) ->
    if Sync.disabled then return fn()
    Sync.disabled = yes
    fn()
    Sync.disabled = no

  sync: (fn) ->
    Sync.socket.emit 'sync', queue.toJSON(), (data) ->
      fn(data)
      queue.clear()

# -----------------------------------------------------------------------------
# Sync Model Handler
# -----------------------------------------------------------------------------

###
 * Takes one model and listens to events on it
 *
 * - model (Base.Collection)
 * - model (Base.Model)
###

Sync.include = (model) ->

  if model instanceof Base.Collection
    handler = new CollectionSync(model)
  else
    handler = new ModelSync(model)

  namespace = null

  handler.oncreate = (item, options) ->
    namespace.emit 'create', item.toJSON(), (id) =>
      Sync.disable => item.id = id

  handler.onupdate = (model, key, value) ->
    data = id: model.id
    data[key] = value
    namespace.emit 'update', data

  handler.ondestroy = (model, options) ->
    namespace.emit 'destroy', model.id

  event.once 'sync:open', ->
    namespace = Sync.namespace model.classname
    namespace.on 'create', handler.create
    namespace.on 'update', handler.update
    namespace.on 'destroy', handler.destroy

  handler.listen()

module.exports = Sync
