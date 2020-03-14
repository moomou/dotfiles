Short
=

A short link server with basic auth for protecting sensitive links written in Rust.

A rust learning project.


Features
==

Password protected links starting with `_`
===
By default, all created links are public. However, you can protect sensitive links by prefixing with `_`. The link is then protected by a password generated on server startup.


Namespaced short links
===
Every link by default lives under the `default` namespace. To avoid conflict, you can create more links under a different namespace via 

    $  curl -XPOST -L -k http://go/<NS>/<SHORT_LINK>/<FULL_LINK>

Anything without a namespace will automatically be placed under `default`

    $  curl -XPOST -L -k http://go/<SHORT_LINK>/<FULL_LINK>


[ TODO ] String expansions
===
You can save a url with `<s>` for string expansion when visiting short links. 

First, save a URL with `<s>`

    $  curl -XPOST -L -k http://go/g/http://google.com/?q=<s>

Now try visiting

    # this will expand to http://google.com/?q=hello
    $  curl -L -k http://go/g/hello 

    # this will expand to http://google.com/?q=
    $  curl -L -k http://go/g