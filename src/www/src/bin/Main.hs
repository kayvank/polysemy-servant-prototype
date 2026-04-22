{-# LANGUAGE RecordWildCards #-}

module Main where

import API.Server (api, server)
import DB.Database (createSqlitePool)
import Data.Default (def)
import Effects.Config (
  AppConfig (..),
  DBConfig (DBConfig),
  NetworkConfig (_networkPort),
 )
import Network.Wai.Handler.Warp qualified
import Network.Wai.Middleware.RequestLogger qualified as Logger
import Servant.Server (serve)

main :: IO ()
main = do
  -- TODO: cli to read config
  cfg@AppConfig{..} <- defaultAppConfig

  Network.Wai.Handler.Warp.run
    (_networkPort _appNetworkConfig)
    (Logger.logStdout (serve api (server cfg)))

defaultAppConfig :: IO AppConfig
defaultAppConfig = do
  pool <- createSqlitePool def
  pure $ AppConfig (DBConfig pool) def def def
