[![Linux Haskell CI](https://github.com/kayvank/polysemy-servant-prototype/actions/workflows/linux-ci.yml/badge.svg)](https://github.com/kayvank/polysemy-servant-prototype/actions/workflows/linux-ci.yml)
[![NixOS Haskell CI](https://github.com/kayvank/polysemy-servant-prototype/actions/workflows/nixos-ci.yml/badge.svg)](https://github.com/kayvank/polysemy-servant-prototype/actions/workflows/nixos-ci.yml)
# What is this
A [polysemy](https://hackage.haskell.org/package/polysemy) [servant](https://www.servant.dev/) project


# How do I build and execute the project
Clone the project:

``` sh
git clone git@github.com:kayvank/polysemy-servant-prototype.git
cd polysemy-servant-prototype

```

To build and execute using `cabal`:

``` sh
nix develop
cabal update && cabal build all
cabal run www
```

To build using `nix` :

``` sh
git clone git@github.com:kayvank/polysemy-servant-prototype.git
cd polysemy-servant-prototype
nix build .#www-server
./result/bin/www
```

# How do I test it
Create a sub directory `.db`

``` sh
mkdir ./.db
```

If you're using emacs [ReSt](https://github.com/pashky/restclient.el) client, use [http-tests.http](./src/www/int-test/http-tests.http)

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
+ Delete an item
``` sh
curl -i  -X DELETE "http://localhost:8080/items/1"
```
## TODO
- [x] Config should be Reader Monad
- [x] use beam for Db stuff
- [x] add github action
- [ ] add github action for nix build
- [x] JSON Logging
- [ ] async Logging
- [ ] More domain objects
- [ ] Rename the project
- [ ] Add a servant client
- [ ] property tests
- [ ] blog the development process

## References
- [Polysemy](https://hackage.haskell.org/package/polysemy)
- [Beam](https://haskell-beam.github.io/beam/)
- [Beam migration blog, William Yao](https://williamyaoh.com/posts/2019-09-27-figuring-out-beam-migrations.html)
- [Servant combinators blog, William Yao](https://williamyaoh.com/posts/2023-02-28-writing-servant-combinators.html)
- [Abstractions in Context](https://williamyaoh.gumroad.com/l/CLyzT)
- [Parallel and Concurrent Programming in Haskell](https://simonmar.github.io/pages/pcph.html)

> Note:
This project is under development.
