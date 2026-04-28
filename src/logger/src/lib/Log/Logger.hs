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
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.IO qualified as Text.IO
import Data.Text.Lazy qualified as Text.Lazy
import Data.Text.Lazy.Encoding (decodeUtf8)
import Data.Time (UTCTime, getCurrentTime)
import GHC.Generics (Generic)
import Log.LogLevel (LogLevel (..))
import Polysemy (Embed, Member, Sem, embed, interpret, makeSem)
import Text.Read (readMaybe)

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
    toLogEvent (NameSpace "dev") DEBUG msg
      >>= embed . Text.IO.putStrLn . Text.Lazy.toStrict . decodeUtf8 . encode
  LogInfo msg ->
    toLogEvent (NameSpace "dev") INFO msg
      >>= embed . Text.IO.putStrLn . Text.Lazy.toStrict . decodeUtf8 . encode
  LogWarn msg ->
    toLogEvent (NameSpace "dev") WARN msg
      >>= embed . Text.IO.putStrLn . Text.Lazy.toStrict . decodeUtf8 . encode
  LogError msg ->
    toLogEvent (NameSpace "dev") ERROR msg
      >>= embed . Text.IO.putStrLn . Text.Lazy.toStrict . decodeUtf8 . encode

newtype NameSpace = NameSpace Text
  deriving (Show, Generic)
  deriving (ToJSON) via Text

data LogEnvelop = LogEnvelop
  { timestamp :: UTCTime
  , threadId :: Int
  , logLevel :: LogLevel
  , nameSpace :: NameSpace
  }
  deriving (Show, Generic)

-- | Provides logging metadata for entries.
data LogEvent = LogEvent
  { logEnvelop :: LogEnvelop
  , logMessage :: Value
  }
  deriving (Show, Generic)

instance ToJSON LogEvent where
  toJSON LogEvent{..} =
    object
      [ "timestamp" .= timestamp logEnvelop
      , "threadId" .= threadId logEnvelop
      , "logLevel" .= logLevel logEnvelop
      , "nameSpace" .= nameSpace logEnvelop
      , "message" .= logMessage
      ]

toLogEvent :: (Member (Embed IO) r) => NameSpace -> LogLevel -> Value -> Sem r LogEvent
toLogEvent nameSpace logLevel logMessage = do
  timestamp <- embed getCurrentTime
  threadId <- mkThreadId <$> embed myThreadId
  let logEnvelop = LogEnvelop{..}
  pure $ LogEvent{..}
  where
    -- NOTE(AB): This is a bit contrived but we want a numeric threadId and we
    -- get some text which we know the structure of
    mkThreadId = fromMaybe 0 . readMaybe . Text.unpack . Text.drop 9 . Text.pack . show

-- | Pure version of toLogEvent for testing purposes
toLogEventPure :: NameSpace -> LogLevel -> Value -> LogEvent
toLogEventPure nameSpace logLevel logMessage =
  let
    timestamp :: UTCTime
    timestamp = read "2026-04-28 17:48:08.00367981 UTC"
    threadId :: Int
    threadId = 12345
    logEnvelop = LogEnvelop{..}
   in
    LogEvent{..}
