{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}

module Log.LogLevel where

import Data.Aeson (
  FromJSON (parseJSON),
  KeyValue ((.=)),
  ToJSON (toJSON),
  object,
  withObject,
  (.:),
 )
import Data.Default (Default (..))
import Data.Text (Text)
import GHC.Generics (Generic)

data LogLevel = DEBUG | INFO | WARN | ERROR
  deriving (Show, Generic)

instance ToJSON LogLevel where
  toJSON DEBUG = object ["level" .= ("DEBUG" :: Text)]
  toJSON INFO = object ["level" .= ("INFO" :: Text)]
  toJSON WARN = object ["level" .= ("WARN" :: Text)]
  toJSON ERROR = object ["level" .= ("ERROR" :: Text)]
instance FromJSON LogLevel where
  parseJSON = withObject "LogLevel" $ \v -> do
    level <- v .: "level"
    case level :: Text of
      "DEBUG" -> pure DEBUG
      "INFO" -> pure INFO
      "WARN" -> pure WARN
      "ERROR" -> pure ERROR
      _ -> fail "Invalid log level"

instance Default LogLevel where
  def = INFO
