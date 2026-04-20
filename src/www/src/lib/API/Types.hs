{-# LANGUAGE OverloadedStrings #-}

module API.Types where

import Data.Aeson (
  FromJSON (parseJSON),
  KeyValue ((.=)),
  ToJSON (toJSON),
  object,
  withObject,
  (.!=),
  (.:),
  (.:?),
 )
import Data.Text (Text)
import GHC.Generics (Generic)
import Model.Types (Item (Item), NewItem (NewItem))

-- | JSON for Item
instance ToJSON Item where
  toJSON (Item i n d) =
    object
      [ "id" .= i
      , "name" .= n
      , "desc" .= d
      ]

instance FromJSON Item where
  parseJSON = withObject "Item" $ \v ->
    Item <$> v .: "id" <*> v .: "name" <*> v .: "desc"

-- | JSON for NewItem (request body)
instance ToJSON NewItem where
  toJSON (NewItem n d) = object ["name" .= n, "desc" .= d]

instance FromJSON NewItem where
  parseJSON = withObject "NewItem" $ \v ->
    NewItem <$> v .: "name" <*> v .:? "desc" .!= ""

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
err msg = ApiResponse False Nothing msg
