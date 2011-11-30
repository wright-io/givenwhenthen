soda = require 'soda'

module.exports = 
  addGivenWhenThenToSoda: ->
    ###
    Monkey patch soda to get the different 'and' functionality we want
    ###
    soda::execute = soda::and
    soda::and = (msg, fn) -> soda::execute.call(this, fn)

    ###
    Attach given/when/then/run helpers.
    ###
    soda::given = (msg, fn) -> this.execute(fn)
    soda::when  = (msg, fn) -> this.execute(fn)
    soda::then  = (msg, fn) -> this.execute(fn)

