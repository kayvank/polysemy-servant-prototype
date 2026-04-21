module Main where

import Network.Wai.Handler.Warp qualified
import Servant.Server (serve)

import API.Routes (api, server)
import DB.Schema (openDb)
import Data.Default (def)
import Effects.Config (AppConfig (configPort))
import Network.Wai.Middleware.RequestLogger qualified as Logger

main :: IO ()
main = do
  -- TODO: resource-pool
  conn <- openDb def

  Network.Wai.Handler.Warp.run
    (configPort def)
    (Logger.logStdout (serve api (server conn)))
