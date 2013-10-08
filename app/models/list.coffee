Base = require 'base'
Sync = require '../controllers/sync'
Task = require './task'

class List extends Base.Model

  defaults:
    id: null
    name: ''
    permanent: null

  @extend Sync.core

  # Reference active list
  # Should proabably be in a controller
  @current: null

  constructor: ->
    super

    # Create a new task collection
    @tasks = new Task.constructor()

  # Move a task from one list to another
  # - task (Task) : The task to move
  # - list (List) : The list to move the task to
  moveTask: (task, list) =>
    if @id == list.id then return
    task.list = list.id
    list.tasks.add task
    @tasks.remove task

  # Remove completed tasks from list
  moveCompleted: =>
    @tasks.refresh(@tasks.active(), true)

class ListCollection extends Base.Collection

  model: List

  constructor: ->
    super

  # Set the current list 
  open: (list) =>
    @currrent = list
    @trigger 'change:current', list

module.exports = new ListCollection()

# Is this the best way to do this?
# Nope. Like I said, put it in a controller.
module.exports.on 'refresh', ->
  return unless List.current?
  if List.exists(List.current.id)
    console.log 'Updating List.current'
    List.current = List.get(List.current.id)
  else
    console.log 'Changing List.current to inbox'
    List.current = List.get('inbox')

