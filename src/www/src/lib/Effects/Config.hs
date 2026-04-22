{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effects.Config
Description : Configuration effect and pure interpreter
-}
module Effects.Config (
  -- * Configuration types
  ConnectionString (..),
  NetworkConfig (..),
  AppName (..),
  LogLevel (..),
  DBConfig (..),
  AppConfig (..),

  -- * helper functions
  getPool,
) where

import Data.Default (Default (..))
import Data.Pool (Pool)
import Data.String (IsString)
import Data.Text (Text)
import Database.SQLite.Simple (Connection)
import GHC.Generics (Generic)

-- | A SQLite3 connection string
newtype ConnectionString
  = ConnectionString
  { unConnectionString :: Text
  }
  deriving (IsString) via Text
  deriving (Show)

instance Default ConnectionString where
  def = ConnectionString ".db/myapp.db"

newtype NetworkConfig = NetworkConfig
  { _networkPort :: Int
  }
  deriving (Show, Generic)

instance Default NetworkConfig where
  def = NetworkConfig 8080

newtype AppName = AppName
  { unAppName :: Text
  }
  deriving (Show, Generic)

instance Default AppName where
  def = AppName "MyApp"

data LogLevel = INFO | WARN | ERROR
  deriving (Show)

instance Default LogLevel where
  def = INFO

newtype DBConfig = DBConfig
  { _dbPool :: Pool Connection
  }
  deriving (Generic)

-- | App configuration
data AppConfig = AppConfig
  { _appDBConfig :: DBConfig
  , _appNetworkConfig :: NetworkConfig
  , _appName :: AppName
  , _appLogLevel :: LogLevel
  }
  deriving (Generic)

getPool :: AppConfig -> Pool Connection
getPool = _dbPool . _appDBConfig
