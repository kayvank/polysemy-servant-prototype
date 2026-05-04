{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Polysemy.Log.Internal.LogConfig (
  LogSeverity (..),
  LogCorrelationId (..),
  LogConfig (..),
) where

import Data.Aeson (FromJSON (parseJSON), KeyValue ((.=)), ToJSON (toJSON), object, withObject, (.:))
import Data.Default (Default (..))
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Log severity levels for logging.
data LogSeverity
  = DEBUG
  | INFO
  | WARN
  | ERROR
  | FATAL
  deriving (Show, Generic, Ord, Eq)

instance ToJSON LogSeverity
instance FromJSON LogSeverity

instance Default LogSeverity where
  def = INFO

-- | A correlation ID for log entries, useful for tracing and debugging.
newtype LogCorrelationId = LogCorrelationId Text
  deriving (Show, Generic)

instance ToJSON LogCorrelationId
instance FromJSON LogCorrelationId

instance Default LogCorrelationId where
  def = LogCorrelationId "default-correlation-id"

-- | Configuration for logging, including severity and correlation ID.
data LogConfig = LogConfig
  { logSeverity :: LogSeverity
  , logCorrelationId :: LogCorrelationId
  }
  deriving (Show, Generic)

instance ToJSON LogConfig where
  toJSON LogConfig{..} =
    object
      [ "severity" .= logSeverity
      , "correlationId" .= logCorrelationId
      ]
instance FromJSON LogConfig where
  parseJSON = withObject "LogConfig" $ \v -> LogConfig <$> v .: "severity" <*> v .: "correlationId"
instance Default LogConfig where
  def = LogConfig def def
