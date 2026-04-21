{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Model.Types
Description : Domain model and JSON instances
-}
module Model.Types where

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
import Database.SQLite.Simple (FromRow (..), ToRow (..), field)

-- | Domain model
data Item = Item
  { itemId :: Int
  , itemName :: Text
  , itemDesc :: Text
  }
  deriving (Show, Eq)

instance FromRow Item where
  fromRow = Item <$> field <*> field <*> field

instance ToRow Item where
  toRow (Item i n d) = toRow (i, n, d)

-- | New item (no ID yet)
data NewItem = NewItem
  { newItemName :: Text
  , newItemDesc :: Text
  }
  deriving (Show, Eq)

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
