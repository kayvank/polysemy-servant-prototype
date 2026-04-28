{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

{- |
Module      : Effects.Logger
Description : Logging effect and IO interpreter
-}
module Log.Logger where

import Control.Concurrent (myThreadId)
import Data.Aeson (
  KeyValue ((.=)),
  ToJSON (toJSON),
  Value,
  encode,
  object,
 )
import Data.ByteString.Lazy.Char8 qualified as C8
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Time (UTCTime, getCurrentTime)
import GHC.Generics (Generic)
import Log.LogLevel (LogLevel (..))
import Polysemy (Embed, Member, Sem, embed, interpret, makeSem)

-- | Effect
data Logger m a where
  LogDebug :: Value -> Logger m ()
  LogInfo :: Value -> Logger m ()
  LogWarn :: Value -> Logger m ()
  LogError :: Value -> Logger m ()

makeSem ''Logger

-- TODO(AB): Namespace should be passed in by the caller, but for now we can hardcode it

-- | Interpreter: print to stdout
runLoggerIO :: (Member (Embed IO) r) => Sem (Logger ': r) a -> Sem r a
runLoggerIO = interpret $ \case
  LogDebug msg ->
    toLogEvent (Namespace "dev") DEBUG msg
      >>= embed . C8.putStrLn . encode
  LogInfo msg ->
    toLogEvent (Namespace "dev") INFO msg
      >>= embed . C8.putStrLn . encode
  LogWarn msg ->
    toLogEvent (Namespace "dev") WARN msg
      >>= embed . C8.putStrLn . encode
  LogError msg ->
    toLogEvent (Namespace "dev") ERROR msg
      >>= embed . C8.putStrLn . encode

newtype Namespace = Namespace Text
  deriving (Show, Generic)
  deriving (ToJSON) via Text

data LogEnvelope = LogEnvelope
  { timestamp :: UTCTime
  , threadId :: Text
  , logLevel :: LogLevel
  , namespace :: Namespace
  }
  deriving (Show, Generic)

-- | Provides logging metadata for entries.
data LogEvent = LogEvent
  { logEnvelope :: LogEnvelope
  , logMessage :: Value
  }
  deriving (Show, Generic)

instance ToJSON LogEvent where
  toJSON LogEvent{..} =
    object
      [ "timestamp" .= timestamp logEnvelope
      , "threadId" .= threadId logEnvelope
      , "logLevel" .= logLevel logEnvelope
      , "namespace" .= namespace logEnvelope
      , "message" .= logMessage
      ]

toLogEvent :: (Member (Embed IO) r) => Namespace -> LogLevel -> Value -> Sem r LogEvent
toLogEvent namespace logLevel logMessage = do
  timestamp <- embed getCurrentTime
  threadId <- mkThreadId <$> embed myThreadId
  let logEnvelope = LogEnvelope{..}
  pure $ LogEvent{..}
  where
    -- NOTE(AB): This is a bit contrived but we want a numeric threadId and we
    -- get some text which we know the structure of
    mkThreadId = Text.pack . show

-- | Pure version of toLogEvent for testing purposes
toLogEventPure :: Namespace -> LogLevel -> Value -> LogEvent
toLogEventPure namespace logLevel logMessage =
  let
    timestamp :: UTCTime
    timestamp = read "2026-04-28 17:48:08.00367981 UTC"
    threadId :: Text
    threadId = "thread-12345"
    logEnvelope = LogEnvelope{..}
   in
    LogEvent{..}
