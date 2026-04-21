{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effects.Config
Description : Configuration effect and pure interpreter
-}
module Effects.Config where

import Data.Default (Default (..))
import Data.Text (Text)
import Polysemy

-- | App configuration
data AppConfig = AppConfig
  { configDbPath :: Text
  , configPort :: Int
  , configAppName :: Text
  }
  deriving (Show)

instance Default AppConfig where
  def = defaultConfig

defaultConfig :: AppConfig
defaultConfig =
  AppConfig
    { configDbPath = ".db/myapp.db"
    , configPort = 8080
    , configAppName = "MyApp"
    }

-- | Effect
data Config m a where
  GetConfig :: Config m AppConfig

makeSem ''Config

-- | Interpreter: supply a fixed config
runConfigPure :: AppConfig -> Sem (Config ': r) a -> Sem r a
runConfigPure cfg = interpret $ \case
  GetConfig -> pure cfg
