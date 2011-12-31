rest    = require 'restler'
driver  = require '../lib/driver'
Client  = driver.Client

describe 'driver', ->
  
  it 'exports Client', ->
    expect(Client).toBeDefined()

  describe 'driver.Client', ->
    mock =
      sessionID: '12345'
      
    opts =
      credentials:
        username: 'username'
        'access-key': 'access-key'
      desiredCapabilities:
        platform: 'VISTA'
        browserName: 'firefox'
        version: '7'
        'max-duration': '100'
      chain: false
      subtitles: true
      
    browser = null
    
    beforeEach ->
      # Prepare mocks and spies.
      browser = new Client(opts)
      
      
    it 'can be configured via the constructor', ->
      # Verify.
      expect(browser.username).toEqual opts.credentials.username
      expect(browser.accessKey).toEqual opts.credentials['access-key']
      expect(browser.desiredCapabilities).toEqual opts.desiredCapabilities
      expect(browser.chain).toEqual opts.chain
      expect(browser.subtitles).toEqual opts.subtitles
      
      
    describe 'Driver commands', ->
      mock.request =
        on: ->
          
      mock.callback = (err, data) ->
                
      ###
      Mock the restler "on 'x'" event to get the desired return behavior.
      @param eventName: The event to mock (e.g. 'success').
      @param data:      The mock data to return on `eventName`.
      @param response:  The mock response to return on `eventName`.
      ###
      spyOnRestlerEvent = (eventName, data, response) ->
        mock.request.on.andCallFake (event, callback) ->
          if event is eventName
            callback data, response
            
      baseSauceDriverUrl = 'http://ondemand.saucelabs.com/wd/hub/session'
      sauceDriverUrl = baseSauceDriverUrl + '/' + mock.sessionID
      
      verifyCredentials = ->
        expect(rest.request.argsForCall[0][1]['username'])
          .toEqual opts.credentials.username
        expect(rest.request.argsForCall[0][1]['password'])
          .toEqual opts.credentials['access-key']
      
      beforeEach ->
        # Spy on the restler "on 'x'" event to make sure no real web service calls are made
        # in testing.
        # Might be overridden below by calls to `spyOnRestlerEvent`.
        spyOn(mock.request, 'on')
    
      describe 'Selenium driver commands', ->
        
        elementValue = '.someElement'
        usingValue = 'css selector'
        
        beforeEach ->
          # Prepare mocks and spies.
          spyOn(rest, 'request').andReturn mock.request          
          spyOn(mock, 'callback')
              
          browser.sessionID = mock.sessionID
          
        it 'creates a new session', ->
          # Prepare mocks and spies.
          response =
            headers:
              location:
                baseSauceDriverUrl + "/#{mock.sessionID}"
                
          spyOnRestlerEvent 'success', null, response
          
          # Set the sessionID to null for init testing since init is supposed to set it.
          browser.sessionID = null
          
          # Call method under test.
          browser.init mock.callback
          
          # Verify.
          ###
          NOTE: Checking that the correct web service calls are made by mocking the
          Restler library (https://github.com/danwrong/restler).
          Since this is a know third-party library, we can assume it works and just
          ensure that the class under test here is making the right calls to it.
          ###
          verifyCredentials()
          expect(rest.request.argsForCall[0][0]).toEqual baseSauceDriverUrl
          expect(rest.request.argsForCall[0][1]['method']).toEqual 'post'
          expect(rest.request.argsForCall[0][1]['data'])
            .toEqual JSON.stringify(desiredCapabilities: opts.desiredCapabilities)
            
          expect(browser.sessionID).toEqual mock.sessionID
          
          expect(mock.callback).toHaveBeenCalled()
        
        it 'navigates to the specified URL', ->
          targetUrl = 'http://some.site.com'
          
          spyOnRestlerEvent 'success', null, null
          
          # Call method under test.
          browser.get targetUrl, mock.callback
          
          # Verify.
          verifyCredentials()
          
          expect(rest.request.argsForCall[0][0]).toEqual sauceDriverUrl + '/url'
          expect(rest.request.argsForCall[0][1]['method']).toEqual 'post'
          expect(rest.request.argsForCall[0][1]['data']).toEqual JSON.stringify(url: targetUrl)
        
          expect(mock.callback).toHaveBeenCalled()
        
        
        describe 'finding elements', ->
          
          it 'returns the Selenium ID for the specified element if found', ->
            # Prepare mocks and spies.
            mock.returnData = 
              value:
                ELEMENT: '1'
                
            spyOnRestlerEvent 'success', mock.returnData, null

            # Call method under test.
            browser.element elementValue, {using: usingValue}, mock.callback
          
            # Verify.
            verifyCredentials()
          
            expect(rest.request.argsForCall[0][0]).toEqual sauceDriverUrl + '/element'
            expect(rest.request.argsForCall[0][1]['method']).toEqual 'post'
          
            data = JSON.stringify {
              using: usingValue
              value: elementValue
            }
          
            expect(rest.request.argsForCall[0][1]['data']).toEqual data
            expect(mock.callback.argsForCall[0][1]).toEqual mock.returnData.value.ELEMENT
        
        
          it 'returns null if the specified element is not found', ->
            # Prepare mocks and spies.            
            # Simulating element missing by calling the error event and returing the 
            # status code that the method under test is looking for to determine this.
            mock.response = 
              statusCode: 500
                
            spyOnRestlerEvent 'error', null, mock.response
            
            # Call method under test.
            browser.element elementValue, {using: usingValue}, mock.callback
            
            # Verify.
            expect(mock.callback.argsForCall[0][1]).toEqual null
        
        
        describe 'commands against specified elements', ->
          
          # Check that _driver_element was properly called.
          verifyElementCommand = ->            
            expect(browser._driver_element.argsForCall[0][0]).toEqual elementValue
            expect(browser._driver_element.argsForCall[0][1]).toEqual {using: usingValue}
        
          beforeEach ->
            # Mock _driver_element, which the method under test uses and which is 
            # already tested above.
            spyOn(browser, '_driver_element').andCallFake (value, opts, callback) ->
              callback null, mock.returnData
        
          describe 'clicking elements', ->
            
            it 'clicks the specified element if the element exists', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = '1'
            
              spyOnRestlerEvent 'success', mock.returnData, null
            
              # Call method under test.
              browser.clickElement elementValue, {using: usingValue}, mock.callback
            
              # Verify.
              verifyElementCommand()
              verifyCredentials()
          
              expect(rest.request.argsForCall[0][0])
                .toEqual sauceDriverUrl + "/element/#{mock.returnData}/click"
              expect(rest.request.argsForCall[0][1]['method']).toEqual 'post'
              expect(rest.request.argsForCall[0][1]['data']).toEqual null
            
              expect(mock.callback.argsForCall[0][0]).toEqual null
        
        
            it 'returns an error if the specified element doesn\'t exist', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = null
            
              # Call method under test.
              browser.clickElement elementValue, {using: usingValue}, mock.callback
            
              # Verify.
              #
              ###
              Expect that the rest event wasn't called.
              (Since we are mocking the _driver_element method to return null
              and the call to 'click' shouldn't happen in this case).
              ###
              expect(mock.request.on).not.toHaveBeenCalled()
              err = new Error "Element with #{usingValue}: #{elementValue} not present."
              expect(mock.callback.argsForCall[0][0].message).toEqual(err.message)
        
        
          describe 'typing text into elements', ->
            
            it 'types the provided text into the specified element if it exists', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = '1'
            
              spyOnRestlerEvent 'success', mock.returnData, null
            
              text = "text"
            
              # Call method under test.
              browser.typeInElement elementValue, text, {using: usingValue}, mock.callback
            
              # Verify.
              verifyElementCommand()
              verifyCredentials()
          
              expect(rest.request.argsForCall[0][0])
                .toEqual sauceDriverUrl + "/element/#{mock.returnData}/value"
              expect(rest.request.argsForCall[0][1]['method']).toEqual 'post'
              expect(rest.request.argsForCall[0][1]['data'])
                .toEqual JSON.stringify(value: text.split(''))
                          
              expect(mock.callback.argsForCall[0][0]).toEqual null
              
            it 'accepts an array of strings as the sequence of keys', ->
              # See: http://code.google.com/p/selenium/wiki/JsonWireProtocol
                            # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = '1'
            
              spyOnRestlerEvent 'success', mock.returnData, null
            
              text = "text"
              
              # Call method under test.
              browser.typeInElement elementValue,
                text.split(''), {using: usingValue}, mock.callback
            
              # Verify.
              expect(rest.request.argsForCall[0][1]['data'])
                .toEqual JSON.stringify(value: text.split(''))
                          
              expect(mock.callback.argsForCall[0][0]).toEqual null
              
            
            it 'returns an error if the specified element doesn\'t exist', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = null
            
              text = "text"
            
              # Call method under test.
              browser.typeInElement elementValue, text, {using: usingValue}, mock.callback
            
              # Verify.
              #
              ###
              Expect that the rest event wasn't called.
              (Since we are mocking the _driver_element method to return null
              and the call to 'click' shouldn't happen in this case).
              ###
              expect(mock.request.on).not.toHaveBeenCalled()
              err = new Error "Element with #{usingValue}: #{elementValue} not present."
              expect(mock.callback.argsForCall[0][0].message).toEqual(err.message)
        
        
          describe 'indicating element presence', ->
            
            it 'returns true if the provided element is present in the current page', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = '1'
            
              # Call method under test.
              browser.elementPresent elementValue, {using: usingValue}, mock.callback
            
              # Verify.
              verifyElementCommand()
              expect(mock.callback.argsForCall[0][0]).toEqual null
              expect(mock.callback.argsForCall[0][1]).toBeTruthy()
              
            it 'returns false if the provided element is not present in the current page', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = null
            
              # Call method under test.
              browser.elementPresent elementValue, {using: usingValue}, mock.callback
            
              # Verify.
              verifyElementCommand()
              expect(mock.callback.argsForCall[0][0]).toEqual null
              expect(mock.callback.argsForCall[0][1]).toBeFalsy()
        
        
          describe 'indicating text presence', ->
            
            it 'returns true if the provided text is present in the current page', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = '1'
            
              text = 'text'
            
              # Call method under test.
              browser.textPresent text, mock.callback
            
              # Verify.
              expect(browser._driver_element.argsForCall[0][0])
                .toEqual "//*[contains(.,'#{text}')]"
              expect(browser._driver_element.argsForCall[0][1]).toEqual {using: 'xpath'}
              expect(mock.callback.argsForCall[0][0]).toEqual null
              expect(mock.callback.argsForCall[0][1]).toBeTruthy()
              
              
            it 'returns false if the provided text is not present in the current page', ->
              # Prepare mocks and spies.
              # Value that mocked _driver_element (above) will return
              mock.returnData = null
            
              text = 'text'
            
              # Call method under test.
              browser.textPresent text, mock.callback
            
              # Verify.
              expect(browser._driver_element.argsForCall[0][0])
                .toEqual "//*[contains(.,'#{text}')]"
              expect(browser._driver_element.argsForCall[0][1]).toEqual {using: 'xpath'}
              expect(mock.callback.argsForCall[0][0]).toEqual null
              expect(mock.callback.argsForCall[0][1]).toBeFalsy()
        
        
        it 'executes the provided javascript', ->
          script = 'document.title'
          
          responseData =
            value: 'value'
          
          spyOnRestlerEvent 'success', responseData, null
          
          # Call method under test.
          browser.execute script, mock.callback
          
          # Verify.
          verifyCredentials()
          
          expect(rest.request.argsForCall[0][0]).toEqual sauceDriverUrl + '/execute'
          expect(rest.request.argsForCall[0][1]['method']).toEqual 'post'
          
          data = JSON.stringify {
            script: script
            args: []
          }
          
          expect(rest.request.argsForCall[0][1]['data']).toEqual data
          expect(mock.callback.argsForCall[0][0]).toEqual null
          expect(mock.callback.argsForCall[0][1]).toEqual responseData.value
        
        
        it 'evaluates the provided javascript, returning the result', ->
          # Prepare mocks and spies.
          spyOn(browser, '_driver_execute')
          script = 'document.title'
          
          # Call method under test.
          browser.eval script, mock.callback
          
          # Verify.
          expect(browser._driver_execute.argsForCall[0][0]).toEqual "return #{script}"
          expect(browser._driver_execute.argsForCall[0][1]).toEqual mock.callback
        
        
        it 'sets the implicit wait value for the session', ->
          wait = 3000
          
          responseData =
            value: 'value'
          
          spyOnRestlerEvent 'success', responseData, null
          
          # Call method under test.
          browser.setImplicitWait wait, mock.callback
          
          # Verify.
          verifyCredentials()
          
          expect(rest.request.argsForCall[0][0])
            .toEqual sauceDriverUrl + '/timeouts/implicit_wait'
          expect(rest.request.argsForCall[0][1]['method']).toEqual 'post'
          expect(rest.request.argsForCall[0][1]['data']).toEqual JSON.stringify(ms: wait)
          expect(mock.callback.argsForCall[0][0]).toEqual null
          expect(mock.callback.argsForCall[0][1]).toEqual responseData.value
        
        
        describe 'assertions of element presence', ->
          
          describe 'asserting presence', ->
            
            it 'returns true if the element is present on the current page', ->
              # Prepare mocks and spies.
              spyOn(browser, 'elementPresent').andCallFake (value, opts, callback) ->
                callback null, true
                
              # Call method under test.
              browser.assertElementPresent elementValue, {using: usingValue}, mock.callback
            
              expect(mock.callback.argsForCall[0][0]).toEqual null
              expect(mock.callback.argsForCall[0][1]).toEqual true
            
            
            describe 'when the element is not present', ->
              
              beforeEach ->
                # Prepare mocks and spies.
                spyOn(browser, 'elementPresent').andCallFake (value, opts, callback) ->
                  callback null, false

              it 'returns an error to the callback if one is provided', ->
                # Call method under test.
                browser.assertElementPresent elementValue, {using: usingValue}, mock.callback
                
                err = new Error "Element with #{usingValue}: #{elementValue} not present."
                
                expect(mock.callback.argsForCall[0][0].message).toEqual err.message
                expect(mock.callback.argsForCall[0][1]).toEqual false

              it 'throws an err if a callback is not provided', ->
                # Prepare mocks and spies.
                spyOn(global, 'Error').andCallThrough()
                
                # Call method under test.
                exceptionThrown = false
                try
                  browser.assertElementPresent elementValue, {using: usingValue}
                catch error
                  exceptionThrown = true
          
                expect(global.Error).toHaveBeenCalled()
                expect(exceptionThrown).toBeTruthy()
              
          describe 'asserting absence', ->
            
            it 'calls assertElementPresent and passes `inverse` flag', ->
              # Prepare mocks and spies.
              spyOn(browser, 'assertElementPresent')
              
              # Call method under test.
              browser.assertElementNotPresent elementValue, {using: usingValue}, mock.callback
              
              # Verify.
              expect(browser.assertElementPresent.argsForCall[0][0]).toEqual elementValue
              
              data = {using: usingValue, inverse: true}
              expect(browser.assertElementPresent.argsForCall[0][1]).toEqual data
              expect(browser.assertElementPresent.argsForCall[0][2]).toEqual mock.callback
        
        
        describe 'assertions of text presence', ->
          
          text = 'text'
          
          describe 'asserting presence', ->
            
            it 'returns true if the text is present on the current page', ->
              # Prepare mocks and spies.
              spyOn(browser, 'textPresent').andCallFake (value, callback) ->
                callback null, true
                
              # Call method under test.
              browser.assertTextPresent text, [], mock.callback
            
              expect(mock.callback.argsForCall[0][0]).toEqual null
              expect(mock.callback.argsForCall[0][1]).toEqual true
            
            
            describe 'when the text is not present', ->
              
              beforeEach ->
                # Prepare mocks and spies.
                spyOn(browser, 'textPresent').andCallFake (value, callback) ->
                  callback null, false

              it 'returns an error to the callback if one is provided', ->
                # Call method under test.
                browser.assertTextPresent text, [], mock.callback
                
                err = new Error "Text '#{text}' not present."
                
                expect(mock.callback.argsForCall[0][0].message).toEqual err.message
                expect(mock.callback.argsForCall[0][1]).toEqual false

              it 'throws an err if a callback is not provided', ->
                # Prepare mocks and spies.
                spyOn(global, 'Error').andCallThrough()
                
                # Call method under test.
                exceptionThrown = false
                try
                  browser.assertTextPresent text
                catch error
                  exceptionThrown = true
          
                expect(global.Error).toHaveBeenCalled()
                expect(exceptionThrown).toBeTruthy()
              
          describe 'asserting absence', ->
            
            it 'calls assertTextPresent and passes `inverse` flag', ->
              # Prepare mocks and spies.
              spyOn(browser, 'assertTextPresent')
              
              # Call method under test.
              browser.assertTextNotPresent text, mock.callback
              
              # Verify.
              expect(browser.assertTextPresent.argsForCall[0][0]).toEqual text
              expect(browser.assertTextPresent.argsForCall[0][1]).toEqual {inverse: true}
              expect(browser.assertTextPresent.argsForCall[0][2]).toEqual mock.callback
        
        
        describe 'assertion of page title value', ->
          
          title = 'title'
          notTitle = 'not title'
          
          it 'returns true if the specified title matches that of current page', ->
              # Prepare mocks and spies.
              spyOn(browser, 'eval').andCallFake (script, callback) ->
                callback null, title
                
              # Call method under test.
              browser.assertTitle title, mock.callback
            
              expect(mock.callback.argsForCall[0][0]).toEqual null
              expect(mock.callback.argsForCall[0][1]).toEqual true
            
            
            describe 'when the title does not match', ->
              
              beforeEach ->
                # Prepare mocks and spies.
                spyOn(browser, 'eval').andCallFake (script, callback) ->
                  callback null, notTitle

              it 'returns an error to the callback if one is provided', ->
                # Call method under test.
                browser.assertTitle title, mock.callback
                
                err = new Error "Expected title to be '#{title}' but found '#{notTitle}'."
                
                expect(mock.callback.argsForCall[0][0].message).toEqual err.message
                expect(mock.callback.argsForCall[0][1]).toEqual false

              it 'throws an err if a callback is not provided', ->
                # Prepare mocks and spies.
                spyOn(global, 'Error').andCallThrough()
                
                # Call method under test.
                exceptionThrown = false
                try
                  browser.assertTitle title
                catch error
                  exceptionThrown = true
          
                expect(global.Error).toHaveBeenCalled()
                expect(exceptionThrown).toBeTruthy()
      
      
      describe 'given, when, then commands, which allow BDD grouping of steps', ->
        
          it 'executes a group of steps for a "given", clause', ->
            
            
          it 'executes a group of steps for a "when", clause', ->
            
            
          it 'executes a group of steps for a "then", clause', ->
            
            
          it 'executes a group of steps for an "and", clause', ->
        
        
      it 'calls provided functions as steps to allow step reuse', ->
      
      
    describe 'subtitles', ->
      
      
      it 'inserts subtitles into the test pages for each BDD step, if specified', ->
      
      
      describe 'internal functionality', ->
        
        it 'creates a div containing the specified text', ->
          
        it 'creates javascript that adds a subtitle div to a page it is executed against', ->
          # TODO: try mocking document and actually executing the javascript
          # (call `subtitle()`)
          # Can assume other internal parts work if the right elements are present
          # in the returned script.
          # Check for div containing div containing text (not styling).
          # Check that it is appended to document.
      
      
    describe 'chained mode', ->
      
      it 'allows queues all supported driver calls and allows them to be chained', ->
        # NOTE: probably covered below.
        # TODO: create array of method names and dynamically check that they
        # queue with the passed args
        
        
      it 'queues driver commands and executes them serially when `end()` is called', ->
        
        
      it 'supports callbacks for the queued commands', ->
        
        
      it 'calls the callback to `end()` when the chain completes', ->
        
        
      it 'calls the callback to `end()` if there is an error in the chain', ->
        
        
      it 'closes the Sauce session on completion', ->
        
        
      describe 'setting pass/fail on Sauce test', ->
        
        # TODO: Consider externalizing this from `end()` so it can be used in non-chained
        # mode. If so, add a test in the Selenium commands block.
        
        it 'it sets pass on completion of a successful test', ->
          
          
        it 'it sets fail on completion of an unsuccessful test', ->

  