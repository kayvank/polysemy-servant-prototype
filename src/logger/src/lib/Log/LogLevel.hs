{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}

module Log.LogLevel where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import GHC.Generics (Generic)

data LogLevel = DEBUG | INFO | WARN | ERROR
  deriving (Show, Generic)
instance ToJSON LogLevel
instance FromJSON LogLevel

instance Default LogLevel where
  def = INFO
