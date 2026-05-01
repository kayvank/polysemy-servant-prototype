{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Polysemy.Log.Internal.Logging where

import Control.Monad (when)
import Data.Aeson (
  KeyValue ((.=)),
 )
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Polysemy (
  Embed,
  Member,
  Members,
  Sem,
  embed,
  interpret,
  send,
 )
import Polysemy.Log.Internal.LogConfig (
  LogConfig (..),
  LogSeverity (..),
 )
import Polysemy.Log.Internal.LogMsg (LogMsg (..))
import Polysemy.Reader (Reader, ask)
import Polysemy.Resource (Resource, bracket)
import System.Log.FastLogger (
  LogType' (LogStdout),
  ToLogStr (..),
  defaultBufSize,
  newFastLogger,
 )

-- | A logger that can log messages of type 'LogMsg' to the console. It wraps a function that takes a 'LogMsg' and performs an 'IO' action to log it.
newtype Logger = Logger (LogMsg -> IO ())

-- | A logger that can log messages of type 'LogMsg' to the console.
newLogger :: (Members '[Embed IO] r) => Sem r (Logger, Sem r ())
newLogger = do
  (fastLogger, cleanUp) <- embed $ newFastLogger $ LogStdout defaultBufSize
  pure (Logger (fastLogger . toLogStr @LogMsg), embed cleanUp)

-- | A helper function that creates a logger and ensures that it is properly cleaned up after use.
withLogger :: (Members '[Embed IO, Resource] r) => (Logger -> Sem r ()) -> Sem r ()
withLogger go = bracket newLogger snd (go . fst)

-- | A helper function that logs a message with a given log level using the provided logger. It formats the log message with a timestamp and a correlation ID (if available) before logging it.
logSem
  :: (Members '[Embed IO, Polysemy.Reader.Reader LogConfig] r)
  => LogSeverity
  -> Logger
  -> LogMsg
  -> Sem r ()
logSem lvl (Logger ls) msg = do
  LogConfig{..} <- Polysemy.Reader.ask
  when (logSeverity <= lvl) $ do
    t <- formatTime defaultTimeLocale "%y-%m-%dT%H:%M:%S%03QZ" <$> embed getCurrentTime
    let bmsg =
          ""
            :# [ "correlation-id" .= logCorrelationId -- ("no-correlation-id" :: Text)
               , "timestamp" .= t
               , "level" .= lvl
               ]
    embed $ ls $ bmsg <> msg
  pure ()

{- | The 'SLogger' effect represents a logging effect that can log messages of type 'LogMsg' at different log levels (debug, info, warn, error, fatal).
    Each constructor corresponds to a log level and takes a 'LogMsg' as an argument.
-}
data SLogger m a where
  LogDebug :: LogMsg -> SLogger m ()
  LogInfo :: LogMsg -> SLogger m ()
  LogWarn :: LogMsg -> SLogger m ()
  LogError :: LogMsg -> SLogger m ()
  LogFatal :: LogMsg -> SLogger m ()

logDebug :: (Member SLogger r) => LogMsg -> Sem r ()
logDebug msg = send (LogDebug msg :: SLogger (Sem r) ())

logInfo :: (Member SLogger r) => LogMsg -> Sem r ()
logInfo msg = send (LogInfo msg :: SLogger (Sem r) ())

logWarn :: (Member SLogger r) => LogMsg -> Sem r ()
logWarn msg = send (LogWarn msg :: SLogger (Sem r) ())

logError :: (Member SLogger r) => LogMsg -> Sem r ()
logError msg = send (LogError msg :: SLogger (Sem r) ())

logFatal :: (Member SLogger r) => LogMsg -> Sem r ()
logFatal msg = send (LogFatal msg :: SLogger (Sem r) ())

-- | The 'runLogger' function interprets the 'SLogger' effect by providing an implementation for each log level. It uses the 'withLogger' helper function to create a logger and ensures that it is properly cleaned up after use. For each log level, it formats the log message with a timestamp and a correlation ID (if available) before logging it using the 'logSem' helper function.
runLogger
  :: (Members '[Embed IO, Resource, Polysemy.Reader.Reader LogConfig] r)
  => Sem (SLogger ': r) () -> Sem r ()
runLogger = do
  interpret $ \case
    LogDebug logMsg ->
      withLogger $ \logger -> logSem DEBUG logger logMsg
    LogInfo logMsg ->
      withLogger $ \logger -> logSem INFO logger logMsg
    LogWarn logMsg ->
      withLogger $ \logger -> logSem WARN logger logMsg
    LogError logMsg ->
      withLogger $ \logger -> logSem ERROR logger logMsg
    LogFatal logMsg ->
      withLogger $ \logger -> logSem FATAL logger logMsg
