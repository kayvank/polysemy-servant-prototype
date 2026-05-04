{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

{- |
Module      : Effects.Config
Description : Configuration effect and pure interpreter
-}
module Effects.Config (
  -- * Configuration types
  ConnectionString (..),
  NetworkConfig (..),
  AppName (..),
  DBConfig (..),
  AppConfig (..),
  Config (..),
  ConfigInput (..),

  -- * LogConfiguration exported from `structured-logging`
  LogConfig (..),

  -- * helper functions
  configToAppConfig,
  getPool,
) where

import DB.Database (ConnectionString (..), createSqlitePool)
import Data.Aeson (
  FromJSON (parseJSON),
  KeyValue ((.=)),
  ToJSON (toJSON),
  object,
  withObject,
  (.:),
 )
import Data.Default (Default (..))
import Data.Pool (Pool)
import Data.Text (Text)
import Database.SQLite.Simple (Connection)
import GHC.Generics (Generic)
import Polysemy.Log.Logging (LogConfig (..))

newtype NetworkConfig = NetworkConfig
  { _networkPort :: Int
  }
  deriving (Show, Generic)

instance ToJSON NetworkConfig where
  toJSON (NetworkConfig port) = object ["port" .= port]
instance FromJSON NetworkConfig where
  parseJSON = withObject "NetworkConfig" $ \v ->
    NetworkConfig <$> v .: "port"

instance Default NetworkConfig where
  def = NetworkConfig 8080

newtype AppName = AppName
  { unAppName :: Text
  }
  deriving (Show, Generic)

instance ToJSON AppName where
  toJSON (AppName name) = object ["name" .= name]

instance FromJSON AppName where
  parseJSON = withObject "AppName" $ \v ->
    AppName <$> v .: "name"

instance Default AppName where
  def = AppName "MyApp"

newtype DBConfig = DBConfig
  { _dbPool :: Pool Connection
  }
  deriving (Generic)

-- | App configuration
data AppConfig = AppConfig
  { _appDBConfig :: DBConfig
  , _appNetworkConfig :: NetworkConfig
  , _appLogConfig :: LogConfig
  }
  deriving (Generic)

data Config = Config
  { _configConnectionString :: ConnectionString
  , _configNetworkConfig :: NetworkConfig
  , _configLogConfig :: LogConfig
  }
  deriving (Generic, Show)
instance Default Config where
  def = Config def def def

instance ToJSON Config where
  toJSON Config{..} =
    object
      [ "connectionString" .= _configConnectionString
      , "networkConfig" .= _configNetworkConfig
      , "logConfig" .= _configLogConfig
      ]
instance FromJSON Config where
  parseJSON = withObject "Config" $ \v ->
    Config
      <$> v .: "connectionString"
      <*> v .: "networkConfig"
      <*> v .: "logConfig"

configToAppConfig :: Config -> IO AppConfig
configToAppConfig Config{..} = do
  pool <- createSqlitePool _configConnectionString
  pure $
    AppConfig
      { _appDBConfig = DBConfig pool
      , _appNetworkConfig = _configNetworkConfig
      , _appLogConfig = _configLogConfig
      }

data ConfigInput = ConfigInputFile FilePath | StdInput
  deriving (Show)

getPool :: AppConfig -> Pool Connection
getPool = _dbPool . _appDBConfig
