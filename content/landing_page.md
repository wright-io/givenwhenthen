# Acceptance Testing Like it Should Be

`Given When Then` brings the beautifully elegant
[BDD](http://dannorth.net/introducing-bdd/) semantics **given**, **when**, and **then**
to [node.js](http://nodejs.org/).

This library lets you easily construct elegant acceptance tests, in straight forward
sentence like statements, for execution using Selenium and the astounding 
[Sauce Labs](http://saucelabs.com/) service.

##### Standing on the Shoulders of Giants
We built this tool on top of [Soda](https://github.com/LearnBoost/soda) which was created 
by the fantastic folks at [LearnBoost](https://github.com/LearnBoost).


---

Writing a story that can be run against multiple browsers and operating systems
is as simple as:

    :coffee
    story 'Executing a Google search',
      '''
      As a human 
      I want to perform a search 
      So that I can access the world's information
      ''', ->

        scenario "Search for info about Node.js", (browser) ->
          browser
            .given "I am on the homepage", -> 
              browser.execute(steps.visitHomepage())
            .when "I enter search terms", ->
              browser.type('q', 'nodejs')
            .and "submit the search", ->
              browser.click('btnK')
            .then "I see the correct title", ->
              browser.assertTitle('nodejs - Google Search')
            .and "I see search results", ->
              browser
                .assertTextPresent('results')
                .assertTextPresent('node.js')



## Installation

 `npm install givenwhenthen`
    
## Running Stories

Take it for a test drive by looking at the `/examples` folder:  

1. Get a [Sauce Labs](http://saucelabs.com/) account.  Trial account is free.
2. Set the your sauce account details in `/examples/test/acceptance/config.coffee`.
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
      '''
      As a human 
      I want to perform a search 
      So that I can access the world's information
      ''', ->

and one or more scenarios:

    :coffee
    scenario "Search for info about Node.js", (browser) ->
      browser
        .given "I am on the homepage", -> 
          browser.execute(steps.visitHomepage())
        .when "I enter search terms", ->
          browser.type('q', 'nodejs')
        .and "submit the search", ->
          browser.click('btnK')
        .then "I see the correct title", ->
          browser.assertTitle('nodejs - Google Search')
        .and "I see search results", ->
          browser
            .assertTextPresent('results')
            .assertTextPresent('node.js')
              
Each scenario has "**given**", "**when**", and "**then**" steps. 

- **Given**: Setup the initial conditions for the scenario.
- **When**: Take the action the scenario is testing.
- **Then**: Assert the conditions expected after taking the tested action.

Each step contains one or more chained calls to 
[Selenium actions](http://release.seleniumhq.org/selenium-core/1.0.1/reference.html) 
in the form of `browser.someSeleneseCommand`.

Each step (`given`, `when`, `then`) can have an arbitrary number of `and` steps following it
(see above example).

## Steps
Often there are steps that are repeated throughout many scenarios,
for example "visit homepage" or "sign in".

This kind of functionality can be defined in steps and referred to in scenarios via 
`browser.execute()`:

    :coffee
    scenario "Search for info about Node.js", (browser) ->
      browser
        .given "I am on the homepage", -> 
          browser.execute(steps.visitHomepage())

Steps are defined in `*_steps.coffee` files. Multiple steps per file can be defined 
as follows:  

`steps.visitHomepage = -> (browser) -> browser.open '/'`

Multiple steps files can be defined to organize your steps sensibly.

## Configuration
`config.coffee` contains the configuration for running the stories.

- Overall story and Sauce Labs configuration.
- Browser / OS definitions.
  - Stories will be run against each browser/os configuration defined.

## Skipping / Explicitly Selecting Stories and Scenarios
- To skip one or more stories or scenarios, prefix the story or scenario with `x`
  - e.g. `xstory` or `xscenario`
- To select only one or more stories or scenarios, prefix the story or scenario with `$`
  - e.g. `$story` or `$scenario`

## Authors
- Doug Wright [wright-io](https://github.com/wright-io)
- Phil Cockfield [philcockfield](https://github.com/philcockfield)

## Background
In addition to being influenced, and based on [Sauce Labs](http://saucelabs.com/), 
Selenium, and [Soda](https://github.com/LearnBoost/soda), `Give When Then` is also heavily 
indebted to the [BDD movement](http://en.wikipedia.org/wiki/Behavior_Driven_Development) 
and [Cucumber](http://cukes.info/), and of course all of the efforts that BDD and Cucumber 
are indebted to.  It's cucumbers all the way down baby!

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