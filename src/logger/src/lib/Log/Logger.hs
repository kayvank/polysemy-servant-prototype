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
import Data.Text (Text)
import Data.Text.IO qualified as Text.IO
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
