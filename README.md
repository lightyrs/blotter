# blotter

**blotter** implements a basic router for Facebook page tab applications as well as
some convenience methods that should come in handy for those deploying Facebook
page tab applications on multiple, disconnected Facebook pages.

[**arsduo/koala**](https://github.com/arsduo/koala) gem has vastly improved the lives of those developing Facebook applications in Ruby and/or Rails. By abstracting the details of Facebook's various API implementations, koala insulates developers from the seemingly capricious and frequent nature of platform changes and the havoc that would normally be wrought on an integrating application's code.

Despite these improvements, one annoyance that I have faced repeatedly is the
design and implementation of a router to handle traffic to a Facebook page tab
application. Having done this recently for the fourth time, I've decided to
abstract this pattern so that I and other page tab application developer's need
not waste precious time and energy reinventing the wheel. I also hope to minimize
the impact of Facebook platform changes on existing page tab applications, much
in the same way that koala achieves this for Facebook applications in general.

## Installation

Add this line to your application's Gemfile:

    gem 'blotter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blotter

## Usage

In config/routes.rb:

    blotter_for [:facebook_page, :giveaway]

The first symbol is the resource that has the page's facebook pid.
The second symbol is the resource that will be used to build the view.

By default, this will create a route that is equivalent to:

    match '/blotter', to: 'blotter#index', as: 'blotter'

To override the default:

    blotter_for [:facebook_page, :giveaway], path: 'facebook'

This will create a route that is equivalent to:

    match '/facebook', to: 'blotter#index', as: 'blotter'

Once you decide on a route, use this URL in your Facebook application settings at
[facebook.com/developer](http://facebook.com/developer). Your blotter route can handle traffic to tab and canvas URLs, both secure and insecure.

By default, blotter will route all traffic to the subdirectory matching the
type of referral traffic.

For example, a request to the canvas URL, originating from an app request
notification, will be redirected to:

    '/blotter/canvas/notification'

A direct request to the tab URL will be redirected to:

    '/blotter/tab/direct'

To override these defaults (as most of you will probably require):

    blotter_for [:facebook_page, :giveaway] do |config|

      config.tab = {
        root: '/tab'
      }

      config.canvas = {
        root: '/canvas',
        notification: '/canvas/notified',
        app_center: '/appcenter'
      }

    end

Given this config, all tab request will be redirected to a subdirectory within
'/tab'.  For example, a bitly link pointing to the tab URL will be redirected to
'/tab/bitly'.  In the canvas example, all requests to the canvas URL that are not
explicitly configured here will be redirected to '/canvas/[referral type]'.  Any
request that has an explicit configuration will be redirected to the specified
route.  For example, a request to the canvas URL originating from a Facebook
send button message, will be redirected to '/canvas/sendbutton', whereas a
request to the canvas URL originating from an appcenter link will be redirected
to '/appcenter' because it has been explicitly defined.

By the time the relevant controller action recieves the redirected request,
you will have access to the Facebook Page resource for which the request
is intended as well as the resource that will be used to render the
requested view.

## Practical Example

For example, let's say that I have a giveaway application that allows page
admins to create, deploy, and manage giveaways on their Facebook pages. In my
application, a Facebook page is represented by the FacebookPage model. The
giveaway that will be used to render the view is represented by the Giveaway
model.

My configuration in config/routes.rb:

    blotter_for [:facebook_page, :giveaway] do |config|

      config.tab = {
        root: '/giveaways'
      }

      config.canvas = {
        root: '/giveaways'
      }

    end

Given this configuration, all requests to my application's tab and canvas URLs will be redirected by blotter to '/giveaways/[referral type]'. This might be a popular configuration, given that many page tab applications do not have the need for separate handling of canvas and tab requests.

Imagine that a Facebook user clicks an app request notification sent by a giveaway entrant. Facebook will route this request to the canvas URL you set at [facebook.com/developer](http://facebook.com/developer). I have mine set to the default `blotter_for` route:

	Tab URL: http://simplegiveaways.com/blotter/
	Secure Tab URL: https://simplegiveaways.com/blotter/
	
	Canvas URL: http://simplegiveaways.com/blotter/
	Secure Canvas URL: https://simplegiveaways.com/blotter/
	
When the request hits the Rails app, blotter does the following:

  1. Determines the referral type of the request.
  2. Parses the signed request.
  3. Builds a visitor object.
  4. Redirects to the appropriate route.

## Dependencies

blotter depends on [arsduo/koala](https://github.com/arsduo/koala) for the time being, however, I'd like to begin building out a basic adapter system to enable support of other popular Facebook
libraries.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
