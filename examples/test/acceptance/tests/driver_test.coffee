story 'WD test',
  """
  As a Developer
  I want to create a node.js test runner with BDD semantics using SauceLabs and Selenium 2
  So that acceptance testing can be more awesome
  """, ->

    scenario "Example of every method", (browser) ->
      browser
        .given "I have written Given, When, Then", ->
          return browser
        .when "I execute every test method supported", ->
          title = null
          browser
            .get('http://www.google.com')
            .assertTitle('Google')
            .element('q', using:'name')
            .clickElement('btnK', using:'name')
            .typeInElement('q', 'turkey fryer fire', using:'name')
            .execute('window.location.href')
            .eval('document.title', (err, data) -> console.log data)
            .elementPresent('q', using:'name')
            .textPresent('Images')
            .setImplicitWait(1000)
            .assertElementPresent('q', using:'name')
            .assertElementNotPresent('qrs', using:'name')
            .assertTextPresent('Images')
            .assertTextNotPresent('Monkey')
        .then "Everything works!", ->
          return browser

