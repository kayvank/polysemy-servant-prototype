# What is this
A [polysemy](https://hackage.haskell.org/package/polysemy) [servant](https://www.servant.dev/) project

# How do I use it

clone and build the project.

``` sh
nix develop
cabal update && cabal build all
cabal run www
```
# How do I test it
Create a subdirectory `.db`

``` sh
mkdir ./.db
```

If you're using emacs [ReSt](https://github.com/pashky/restclient.el) client, use [http-tests.http](http-tests.http)

Or you may use curl:

+ Store an item
``` sh
curl -i -H "Content-Type: application/json"  -X POST "http://localhost:8080/items" -d '{
  "name" : "special-item-name-1",
  "desc": "special-item-name-description-1"
}'
```
+ Fetch all items
``` sh
curl -i  -X GET "http://localhost:8080/items"
```
+ Delete and item
``` sh
curl -i  -X DELETE "http://localhost:8080/items/1"
```
## TODO
- Config should be Reader Monad
- use beam for DB stuff
- add github action
- Logging is incomplete
- More domain objects
