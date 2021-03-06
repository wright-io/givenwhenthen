# Simple, powerful acceptance testing for [node.js](http://nodejs.org/).

- Construct acceptance tests with [BDD](http://dannorth.net/introducing-bdd/) 
  semantics in straightforward, sentence-like statements. 
- Execute your tests in the cloud using Selenium 2 on [Sauce Labs](http://saucelabs.com/).


---

Writing a story to be run against multiple browsers and operating systems
is as simple as:

    :coffee
    story 'Executing a Google search',
      """
      As a human 
      I want to perform a search 
      So that I can access the world's information
      """, ->

        scenario "Search for info about Node.js", (browser) ->
          browser
            .given "I am on the homepage", -> 
              browser.step(steps.visitHomepage)
            .when "I enter search terms", ->
              browser.typeInElement('q', 'nodejs', using:'name')
            .and "submit the search", ->
              browser.clickElement('btnG', using:'name')
            .then "I see search results", ->
              browser.assertTextPresent('results')
            .and "the results contain information about nodejs", ->
              browser
                .assertTextPresent('node.js')
                .assertTextPresent('nodejs.org')



## Installation

 `npm install givenwhenthen`
    
## Running Stories

Take it for a test drive by looking at the `/examples` folder:  

1. Get a [Sauce Labs](http://saucelabs.com/) account. Trial account is free.
2. Set your sauce account details in `/examples/test/acceptance/config.coffee`.
3. From within the `/examples` folder, run `cake test:acceptance`.

To use in your own project:

1. Create the `test/acceptance` directory.
2. Populate it with your own stories, steps, and config.
3. Execute via your own [Cake](http://jashkenas.github.com/coffee-script/#cake) 
   task or similar (see `/examples/Cakefile`) 

## Writing a Story
`Given When Then` is a [DSL](http://en.wikipedia.org/wiki/Domain-specific_language) 
for writing executable stories in the 
[Dan North format](http://dannorth.net/whats-in-a-story/).

In a `.coffee` file, write each story with a description:

    :coffee
    story 'Executing a Google search',
      """
      As a human 
      I want to perform a search 
      So that I can access the world's information
      """, ->

and one or more scenarios:

    :coffee
    scenario "Search for info about Node.js", (browser) ->
      browser
        .given "I am on the homepage", -> 
          browser.step(steps.visitHomepage)
        .when "I enter search terms", ->
          browser.typeInElement('q', 'nodejs', using:'name')
        .and "submit the search", ->
          browser.clickElement('btnG', using:'name')
        .then "I see search results", ->
          browser.assertTextPresent('results')
        .and "the results contain information about nodejs", ->
          browser
            .assertTextPresent('node.js')
            .assertTextPresent('nodejs.org')
              
Each scenario has "**given**", "**when**", and "**then**" steps. 

- **Given**: Setup the initial conditions for the scenario.
- **When**: Take the action the scenario is testing.
- **Then**: Assert the conditions expected after taking the tested action.

Each step contains one or more chained calls to WebDriver commands in the form of 
`browser.someCommand` - (see `/examples`).

Each step (`given`, `when`, `then`) can have an arbitrary number of `and` steps following it
(see above example).

## Steps
Often there are steps that are repeated throughout many scenarios,
for example "visit homepage" or "sign in".

This kind of functionality can be defined in steps and referred to in scenarios via 
`browser.step()`:

    :coffee
    scenario "Search for info about Node.js", (browser) ->
      browser
        .given "I am on the homepage", -> 
          browser.step(steps.visitHomepage)

Steps are defined in `*_steps.coffee` files. Multiple steps per file can be defined 
as follows:  

    :coffee
    steps.visitHomepage = (browser) -> browser.get 'http://www.google.com'

Multiple steps files can be defined to organize your steps sensibly.

## Configuration
`config.coffee` contains the configuration for running the stories.

- Overall story and Sauce Labs configuration.
- Browser / OS definitions.
  - Stories will be run against each browser/os configuration defined.

For example:

    :coffee
    config.credentials =
      'username':   'sauce_labs_username'
      'access-key': 'sauce_labs_access_key'
  
    config.settings =
      'max-duration': '180'

    config.browsers = [
      {
        'platform':     'VISTA'
        'browserName':  'firefox'
        'version':      '7'
      }
      {
        'platform':     'LINUX'
        'browserName':  'firefox'
        'version':      '7'
      }
    ]

See Sauce Labs for the list of available browser/OS configurations.

## Skipping or Isolating Stories and Scenarios
- To skip one or more stories or scenarios, prefix the story or scenario with `x`
  - e.g. `xstory` or `xscenario`
- To select only one or a set of stories or scenarios, prefix the story or scenario with `$`
  - e.g. `$story` or `$scenario`

## Subtitles In Test Videos
When the subtitle flag to the GivenWhenThen runner, subtitle divs will be inserted into the 
test browser which will show up in the Sauce Labs test videos and illustrate which 
of the BDD steps is currently being executed (see `/examples/Cakefile`).

## Authors
- **Doug** Wright [GitHub: wright-io](https://github.com/wright-io) | [Twitter: @dougwright](https://twitter.com/#!/dougwright)
- **Phil** Cockfield [GitHub: philcockfield](https://github.com/philcockfield) | [Twitter: @philcockfield](https://twitter.com/#!/philcockfield)

## Design Sources
In addition to being built on top of [Sauce Labs](http://saucelabs.com/) 
and Selenium 2, `Given When Then` is heavily influenced by [Cucumber](http://cukes.info/) 
and the [BDD movement](http://en.wikipedia.org/wiki/Behavior_Driven_Development) in general 
- and in turn all of the efforts that BDD and Cucumber are indebted to. 
It's cucumbers all the way down baby!

## License
The [MIT License](http://www.opensource.org/licenses/mit-license.php) (MIT)  
Copyright © 2011 Phil Cockfield, Doug Wright

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.