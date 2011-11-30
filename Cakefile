child_process = require 'child_process'
core          = require 'open.core'

task 'specs', 'Runs unit tests', ->
  child_process.exec "jasmine-node --color --coffee test",
    (err, stdout, stderr) ->
      core.util.onExec err, stdout, stderr