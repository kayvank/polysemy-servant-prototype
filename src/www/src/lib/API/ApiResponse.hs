{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : API.Types
Description : Common types for API responses
-}
module API.ApiResponse (
  ApiResponse (..),
  ok,
  err,
) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Generic API response envelope
data ApiResponse a = ApiResponse
  { success :: Bool
  , payload :: Maybe a
  , message :: Text
  }
  deriving (Show, Generic)

instance (ToJSON a) => ToJSON (ApiResponse a)
instance (FromJSON a) => FromJSON (ApiResponse a)

ok :: a -> ApiResponse a
ok x = ApiResponse True (Just x) "OK"

err :: Text -> ApiResponse ()
err = ApiResponse False Nothing
