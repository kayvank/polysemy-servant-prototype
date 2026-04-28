{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Effects.Logger
Description : Logging effect and IO interpreter
-}
module Log.Logger where

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
import Data.Text.IO qualified as Text.IO
import GHC.Generics (Generic)
import Polysemy (Embed, Member, Sem, embed, interpret, makeSem)

-- | Effect
data Logger m a where
  LogDebug :: Text -> Logger m ()
  LogInfo :: Text -> Logger m ()
  LogWarn :: Text -> Logger m ()
  LogError :: Text -> Logger m ()

makeSem ''Logger

-- | Interpreter: print to stdout
runLoggerIO :: (Member (Embed IO) r) => Sem (Logger ': r) a -> Sem r a
runLoggerIO = interpret $ \case
  LogDebug msg -> embed $ Text.IO.putStrLn $ "[INFO]  " <> msg
  LogInfo msg -> embed $ Text.IO.putStrLn $ "[INFO]  " <> msg
  LogWarn msg -> embed $ Text.IO.putStrLn $ "[WARN]  " <> msg
  LogError msg -> embed $ Text.IO.putStrLn $ "[ERROR] " <> msg

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
