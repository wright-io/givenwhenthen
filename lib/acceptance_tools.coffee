soda = require 'soda'

module.exports = 
  addGivenWhenThenToSoda: ->
    ###
    Monkey patch soda to get the different 'and' functionality we want
    ###
    soda.prototype.execute = soda.prototype.and
    soda.prototype.and = (msg, fn) -> soda.prototype.execute.call(this, fn)

    ###
    Attach given/when/then/run helpers.
    ###
    soda.prototype.given = (msg, fn) -> this.execute(fn)
    soda.prototype.when  = (msg, fn) -> this.execute(fn)
    soda.prototype.then  = (msg, fn) -> this.execute(fn)

