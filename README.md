[![Build Status](https://travis-ci.org/Haravan/haravan_api.svg?branch=master)](https://travis-ci.org/Haravan/haravan_api)
# Haravan API

The Haravan API gem allows Ruby developers to programmatically access the admin section of Haravan stores.

The API is implemented as JSON over HTTP using all four verbs (GET/POST/PUT/DELETE). Each resource, like Order, Product, or Collection, has its own URL and is manipulated in isolation. In other words, we’ve tried to make the API follow the REST principles as much as possible.

## Usage

### Requirements

All API usage happens through Haravan applications, created by either shop owners for their own shops, or by Haravan Partners for use by other shop owners:

* Shop owners can create applications for themselves through their own admin: https://docs.haravan.com/blogs/authentication/1000017782-create-a-private-app
* Haravan Partners create applications through their admin: http://app.haravan.com/services/partners

For more information and detailed documentation about the API visit http://api.haravan.com

### Installation

To easily install or upgrade to the latest release, use [gem](http://rubygems.org/)

```bash
gem install haravan_api
```

### Getting Started

HaravanAPI uses ActiveResource to communicate with the REST web service. ActiveResource has to be configured with a fully authorized URL of a particular store first. To obtain that URL you can follow these steps:

1. First create a new application in either the partners admin or your store admin. For a private App you'll need the API_KEY and the PASSWORD otherwise you'll need the API_KEY and SHARED_SECRET.

2. For a private App you just need to set the base site url as follows:

   ```ruby
   shop_url = "https://#{API_KEY}:#{PASSWORD}@SHOP_NAME.myharavan.com/admin"
   HaravanAPI::Base.site = shop_url
   ```

   That's it, you're done, skip to step 6 and start using the API!

   For a partner app you will need to supply two parameters to the Session class before you instantiate it:

  ```ruby
  HaravanAPI::Session.setup({:api_key => API_KEY, :secret => SHARED_SECRET})
  ```

3. In order to access a shop's data, apps need an access token from that specific shop. This is a two-stage process. Before interacting with a shop for the first time an app should redirect the user to the following URL:

   ```
   GET https://SHOP_NAME.myharavan.com/admin/oauth/authorize
   ```

   with the following parameters:

   * ``client_id``– Required – The API key for your app
   * ``scope`` – Required – The list of required scopes (explained here: https://docs.haravan.com/blogs/authentication/1000017781-oauth)
   * ``redirect_uri`` – Optional – The URL that the merchant will be sent to once authentication is complete. Defaults to the URL specified in the application settings and must be the same host as that URL.

   We've added the create_permission_url method to make this easier, first instantiate your session object:

   ```ruby
   session = HaravanAPI::Session.new("SHOP_NAME.myharavan.com")
   ```

   Then call:

   ```ruby
   scope = ["write_products"]
   permission_url = session.create_permission_url(scope)
   ```

   or if you want a custom redirect_uri:

   ```ruby
   permission_url = session.create_permission_url(scope, "https://my_redirect_uri.com")
   ```

4. Once authorized, the shop redirects the owner to the return URL of your application with a parameter named 'code'. This is a temporary token that the app can exchange for a permanent access token. Make the following call:

   ```
   POST https://SHOP_NAME.myharavan.com/admin/oauth/access_token
   ```

   with the following parameters:

   * ``client_id`` – Required – The API key for your app
   * ``client_secret`` – Required – The shared secret for your app
   * ``code`` – Required – The token you received in step 3

   and you'll get your permanent access token back in the response.

   There is a method to make the request and get the token for you. Pass
   all the params received from the previous call and the method will verify
   the params, extract the temp code and then request your token:

   ```ruby
   token = session.request_token(params)
   ```

   This method will save the token to the session object and return it. For future sessions simply pass the token in when creating the session object:

   ```ruby
   session = HaravanAPI::Session.new("SHOP_NAME.myharavan.com", token)
   ```

5. The session must be activated before use:

   ```ruby
   HaravanAPI::Base.activate_session(session)
   ```

6. Now you're ready to make authorized API requests to your shop! Data is returned as ActiveResource instances:

   ```ruby
   shop = HaravanAPI::Shop.current

   # Get a specific product
   product = HaravanAPI::Product.find(179761209)

   # Create a new product
   new_product = HaravanAPI::Product.new
   new_product.title = "Burton Custom Freestlye 151"
   new_product.product_type = "Snowboard"
   new_product.vendor = "Burton"
   new_product.save

   # Update a product
   product.handle = "burton-snowboard"
   product.save
   ```

   Alternatively, you can use #temp to initialize a Session and execute a command which also handles temporarily setting ActiveResource::Base.site:

   ```ruby
   products = HaravanAPI::Session.temp("SHOP_NAME.myharavan.com", token) { HaravanAPI::Product.find(:all) }
   ```

7. If you want to work with another shop, you'll first need to clear the session:

   ```ruby
   HaravanAPI::Base.clear_session
   ```


### Console

This package also includes the ``haravan`` executable to make it easy to open up an interactive console to use the API with a shop.

1. Obtain a private API key and password to use with your shop (step 2 in "Getting Started")

2. Use the ``haravan`` script to save the credentials for the shop to quickly log in.

   ```bash
   haravan add yourshopname
   ```

   Follow the prompts for the shop domain, API key and password.

3. Start the console for the connection.

   ```bash
   haravan console
   ```

4. To see the full list of commands, type:

   ```bash
   haravan help
   ```

## Threadsafety

ActiveResource is inherently non-threadsafe, because class variables like ActiveResource::Base.site and ActiveResource::Base.headers are shared between threads. This can cause conflicts when using threaded libraries, like Sidekiq.

We have a forked version of ActiveResource that stores these class variables in threadlocal variables. Using this forked version will allow HaravanAPI to be used in a threaded environment.

To enable threadsafety with HaravanAPI, add the following to your Gemfile. There are various threadsafe tags that you can use, [depending on which version of rails you are using](https://github.com/haravan/activeresource/tags).

```
gem 'activeresource', git: 'git://github.com/Haravan/activeresource', tag: '4.2-threadsafe'
gem 'haravan_api', '>= 3.2.1'
```

## Using Development Version

Download the source code and run:

```bash
rake install
```

## Additional Resources

API Docs: https://docs.haravan.com/blogs/api-reference

## Copyright

Copyright (c) 2014 "Haravan Inc.". See LICENSE for details.
