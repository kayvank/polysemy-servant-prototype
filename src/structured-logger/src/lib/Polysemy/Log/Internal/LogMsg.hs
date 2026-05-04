{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

-- | This module defines the 'LogMsg' data type, which represents a log message consisting of a text message and a list of key-value pairs for additional context. It provides instances for 'IsString', 'ToJSON', 'ToLogStr', 'Semigroup', and 'Monoid', allowing for easy construction, JSON encoding, and combination of log messages. The '(#+)' operator is defined to add key-value pairs to an existing log message.
module Polysemy.Log.Internal.LogMsg (
  -- | The 'LogMsg' data type represents a log message consisting of a text message and a list of key-value pairs for additional context. It provides instances for 'IsString', 'ToJSON', 'ToLogStr', 'Semigroup', and 'Monoid', allowing for easy construction, JSON encoding, and combination of log messages. The '(#+)' operator is defined to add key-value pairs to an existing log message.
  LogMsg (..),
  -- | The '(#+)' operator allows us to add key-value pairs to an existing log message.
  (#+),
) where

import Data.Aeson (
  KeyValue ((.=)),
  ToJSON (toJSON),
  encode,
  object,
 )
import Data.Aeson.Types (Pair)
import Data.String (IsString (..))
import Data.Text (Text)
import System.Log.FastLogger (
  ToLogStr (..),
 )

{- | A log message, consisting of a text message and a list of key-value pairs.
 - The text message is the main message, and the key-value pairs are additional context.
 - The 'Semigroup' instance allows us to combine log messages, concatenating the text messages with " - " and merging the key-value pairs.
 - The 'Monoid' instance provides an empty log message.
 - The '(#+)' operator allows us to add key-value pairs to an existing log message.
-}
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
