{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}

module Polysemy.Log.Internal.LogConfig where

import Data.Aeson
import Data.Default
import Data.Text (Text)
import GHC.Generics (Generic)

data LogSeverity
  = DEBUG
  | INFO
  | WARN
  | ERROR
  | FATAL
  deriving (Show, Generic, Ord, Eq)

instance ToJSON LogSeverity

instance Default LogSeverity where
  def = INFO

newtype LogCorrelationId = LogCorrelationId Text
  deriving (Show, Generic)

instance ToJSON LogCorrelationId

instance Default LogCorrelationId where
  def = LogCorrelationId "default-correlation-id"

data LogConfig = LogConfig
  { logSeverity :: LogSeverity
  , logCorrelationId :: LogCorrelationId
  }
  deriving (Show, Generic)

instance Default LogConfig where
  def = LogConfig def def
