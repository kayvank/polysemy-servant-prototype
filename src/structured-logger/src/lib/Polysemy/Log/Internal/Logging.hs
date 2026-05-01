{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Polysemy.Log.Internal.Logging where

import Control.Monad.IO.Class
import Data.Aeson
import Data.Aeson.Types (Pair (..))
import Data.String
import Data.Text (Text)
import Data.Time.Clock
import Data.Time.Format
import GHC.Generics (Generic)
import Polysemy
import Polysemy.Resource
import System.Log.FastLogger (
  LogType' (LogStdout),
  ToLogStr (..),
  defaultBufSize,
  newFastLogger,
 )

data LogMsg = Text :# [Pair]
  deriving (Eq, Show)

instance IsString LogMsg where
  fromString msg = fromString msg :# []

instance ToJSON LogMsg where
  toJSON (msg :# ps) = object $ ps <> ["message" .= msg]

instance ToLogStr LogMsg where
  toLogStr msg = toLogStr (encode msg) <> "\n"

instance Semigroup LogMsg where
  "" :# ps0 <> msg1 :# ps1 = msg1 :# (ps0 <> ps1)
  msg0 :# ps0 <> "" :# ps1 = msg0 :# (ps0 <> ps1)
  msg0 :# ps0 <> msg1 :# ps1 = (msg0 <> " - " <> msg1) :# (ps0 <> ps1)

instance Monoid LogMsg where mempty = ""

(#+) :: LogMsg -> [Pair] -> LogMsg
(#+) (msg :# ps0) ps1 = msg :# (ps0 <> ps1)

newtype Logger = Logger (LogMsg -> IO ())

newLogger :: (Members '[Embed IO] r) => Sem r (Logger, Sem r ())
newLogger = do
  (fastLogger, cleanUp) <- embed $ newFastLogger $ LogStdout defaultBufSize
  pure (Logger (fastLogger . toLogStr @LogMsg), embed cleanUp)

withLogger :: (Members '[Embed IO, Resource] r) => (Logger -> Sem r ()) -> Sem r ()
withLogger go = bracket newLogger snd (go . fst)

logSem :: (Member (Embed IO) r) => Text -> Logger -> LogMsg -> Sem r ()
logSem lvl (Logger ls) msg = do
  t <- formatTime defaultTimeLocale "%y-%m-%dT%H:%M:%S%03QZ" <$> embed getCurrentTime
  let bmsg =
        ""
          :# [ "correlation-id" .= ("no-correlation-id" :: Text)
             , "timestamp" .= t
             , "level" .= lvl
             ]
  embed $ ls $ bmsg <> msg

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
logWarn msg = send (LogWarn msg :: SLogger (Sem r) ()) -- undefined

logError :: (Member SLogger r) => LogMsg -> Sem r ()
logError msg = send (LogError msg :: SLogger (Sem r) ()) -- undefined

logFatal :: (Member SLogger r) => LogMsg -> Sem r ()
logFatal msg = send (LogFatal msg :: SLogger (Sem r) ()) -- undefined

logs :: (Member (Embed IO) r) => Logger -> Sem r ()
logs logger = do
  debugIO logger "a log line"
  infoIO logger $ "another log line" #+ ["extras" .= (42 :: Int)]
  infoIO logger $ "User object logging" #+ ["payload" .= user]
  infoIO logger $ "User object logging" #+ ["payload" .= (User2 "Abass")]

logs' :: (Members '[Embed IO, SLogger] r) => Sem r ()
logs' = do
  logDebug "a log line"
  logInfo $ "another log line" #+ ["extras" .= (42 :: Int)]
  logWarn $ "User object logging" #+ ["payload" .= user]
  logError $ "User object logging" #+ ["payload" .= (User2 "Abass")]
  logFatal $ "User object logging" #+ ["payload" .= (User2 "Abass")]

runLogger' :: (Members '[Embed IO] r) => Sem r ()
runLogger' = runResource $ withLogger $ \logger -> logs logger

runLogger :: (Members '[Embed IO] r) => (Logger -> Sem (Resource : r) ()) -> Sem r ()
runLogger l = runResource $ withLogger $ \logger -> l logger

runLogger'' :: (Members '[Embed IO, Resource] r) => Sem (SLogger ': r) () -> Sem r ()
runLogger'' = do
  interpret $ \case
    LogDebug logMsg ->
      -- runResource $
      withLogger $ \logger -> logSem "debug" logger logMsg
    LogInfo logMsg ->
      -- runResource $
      withLogger $ \logger -> logSem "info" logger logMsg
    LogWarn logMsg ->
      -- runResource $
      withLogger $ \logger -> logSem "warn" logger logMsg
    LogError logMsg ->
      -- runResource $
      withLogger $ \logger -> logSem "error" logger logMsg
    LogFatal logMsg ->
      -- runResource $
      withLogger $ \logger -> logSem "fatal" logger logMsg

debugIO, infoIO, warnIO, errIO, fatalIO :: (Member (Embed IO) r) => Logger -> LogMsg -> Sem r ()
debugIO = logSem "debug"
infoIO = logSem "info"
warnIO = logSem "warn"
errIO = logSem "error"
fatalIO = logSem "fatal"

data User = User
  { name :: Text
  , age :: Int
  }
  deriving (Show, Generic)

instance ToJSON User

newtype User2 = User2 Text
  deriving (Show)
  deriving (IsString) via Text
  deriving (ToJSON) via Text

user = User "SpecialUser" 21
