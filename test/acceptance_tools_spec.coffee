soda  = require 'soda'
tools = require '../lib/acceptance_tools.coffee'

describe 'util/acceptance_tools', ->
  
  describe 'extensions', ->
    beforeEach ->
      tools.addGivenWhenThenToSoda()
    
    it 'provides the "given" function on the Client object', ->
      expect(soda::given).toBeDefined()
      
    it 'provides the "when" function on the Client object', ->
      expect(soda::when).toBeDefined()
    
    it 'provides the "then" function on the Client object', ->
      expect(soda::then).toBeDefined()
  
  describe 'changes', ->
    originalAndFunction = null
  
    beforeEach ->
      originalAndFunction = soda::and
      tools.addGivenWhenThenToSoda()
      
    it 'replaces the behavior of "and" to take a message argument', ->
      expect(soda::and).toBeDefined()
      expect(soda::and).not.toEqual(originalAndFunction)
    
    it 'swaps the "and" function with "execute"', ->
      expect(soda::execute).toBeDefined()
      expect(soda::execute).toEqual(originalAndFunction)
