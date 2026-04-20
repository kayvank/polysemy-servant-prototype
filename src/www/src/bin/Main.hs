module Main where

import Network.Wai.Handler.Warp qualified
import Servant.Server (serve)

import API.Routes (api, server)
import DB.Schema (openDb)
import Data.Default (def)
import Effects.Config (
  AppConfig (configAppName, configDbPath, configPort),
  defaultConfig,
 )

main :: IO ()
main = do
  conn <- openDb def

  Network.Wai.Handler.Warp.run
    (configPort def)
    (serve api (server conn))
