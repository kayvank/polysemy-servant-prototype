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
  object,
 )
import Data.Aeson qualified as Aeson
import Data.ByteString.Lazy.Char8 qualified as C8
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Time (UTCTime, getCurrentTime)
import GHC.Generics (Generic)
import Log.LogLevel (LogLevel (..))
import Polysemy (Embed, Member, Sem, embed, interpret, makeSem)

-- | Effect
data Logger m a where
  LogDebug :: (ToJSON b) => b -> Logger m ()
  LogInfo :: (ToJSON b) => b -> Logger m ()
  LogWarn :: (ToJSON b) => b -> Logger m ()
  LogError :: (ToJSON b) => b -> Logger m ()

makeSem ''Logger

-- TODO(AB): ServiceName should be passed in by the caller, but for now we can hardcode it

-- | Interpreter: print to stdout
runLoggerIO :: (Member (Embed IO) r) => Sem (Logger ': r) a -> Sem r a
runLoggerIO = interpret $ \case
  LogDebug msg ->
    toLogEvent DEBUG msg
      >>= embed . C8.putStrLn . Aeson.encode
  LogInfo msg ->
    toLogEvent INFO msg
      >>= embed . C8.putStrLn . Aeson.encode
  LogWarn msg ->
    toLogEvent WARN msg
      >>= embed . C8.putStrLn . Aeson.encode
  LogError msg ->
    toLogEvent ERROR msg
      >>= embed . C8.putStrLn . Aeson.encode

newtype ServiceName = ServiceName Text
  deriving (Show, Generic)
  deriving (ToJSON) via Text

data LogEnvelope = LogEnvelope
  { timestamp :: UTCTime
  , threadId :: Text
  , logLevel :: LogLevel
  }
  deriving (Show, Generic)

-- | Provides logging metadata for entries.
data LogEvent ev = LogEvent
  { logEnvelope :: LogEnvelope
  , event :: ev
  }
  deriving (Show, Generic)

instance (ToJSON ev) => ToJSON (LogEvent ev) where
  toJSON LogEvent{..} =
    object
      [ "timestamp" .= timestamp logEnvelope
      , "thread" .= threadId logEnvelope
      , "severity" .= logLevel logEnvelope
      , "logEntry" .= event
      ]

toLogEvent
  :: (Member (Embed IO) r) => LogLevel -> ev -> Sem r (LogEvent ev)
toLogEvent logLevel event = do
  timestamp <- embed getCurrentTime
  threadId <- mkThreadId <$> embed myThreadId
  let logEnvelope = LogEnvelope{..}
  pure $ LogEvent{..}
  where
    -- NOTE(AB): This is a bit contrived but we want a numeric threadId and we
    -- get some text which we know the structure of
    mkThreadId = Text.pack . show

-- | Pure version of toLogEvent for testing purposes
toLogEventPure :: LogLevel -> ev -> LogEvent ev
toLogEventPure logLevel event =
  let
    timestamp :: UTCTime
    timestamp = read "2026-04-28 17:48:08.00367981 UTC"
    threadId :: Text
    threadId = "thread-12345"
    logEnvelope = LogEnvelope{..}
   in
    LogEvent{..}
