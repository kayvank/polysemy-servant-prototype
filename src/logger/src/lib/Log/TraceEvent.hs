{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Log.TraceEvent where

import Data.Aeson
import Data.Text (Text)
import GHC.Generics (Generic)

data TraceEvent a = TraceEvent
  { message :: Maybe Text
  , context :: Text
  , event :: a
  , service :: Text
  }
  deriving (Show, Generic)

instance (ToJSON a) => ToJSON (TraceEvent a) where
  toJSON TraceEvent{..} =
    object
      [ "message" .= message
      , "context" .= context
      , "traceEvent" .= event
      , "application" .= service
      ]
