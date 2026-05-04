{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Aeson
import Data.Default
import Data.Function ((&))
import Data.String
import Data.Text (Text)
import Data.Word
import GHC.Generics (Generic)
import Polysemy
import Polysemy.Log.Logging
import Polysemy.Reader (runReader)
import Polysemy.Resource

data Address = Address
  { houseNumber :: Text
  , streetName :: Text
  , city :: Text
  , postalCode :: Word32
  }
  deriving (Show, Generic)
instance ToJSON Address

data User = User
  { name :: Text
  , age :: Int
  , address :: Address
  }
  deriving (Show, Generic)

instance ToJSON User

logs :: (Members '[Embed IO, SLogger] r) => Sem r ()
logs = do
  logDebug "a log line"
  logInfo $ "another log line" #+ ["extras" .= (42 :: Int)]
  logWarn $ "User object logging" #+ ["payload" .= user]
  logError $ "User object logging" #+ ["payload" .= (User2 "Abass")]
  logFatal $ "User object logging" #+ ["payload" .= (User2 "Abass")]

newtype User2 = User2 Text
  deriving (Show)
  deriving (IsString) via Text
  deriving (ToJSON) via Text

userAddress = Address "2303" "Third Street" "San Francisco" 94124
user = User "SpecialUser" 21 userAddress

main :: IO ()
main =
  logs
    & runLogger (def @LogConfig)
    & runResource
    & runM
