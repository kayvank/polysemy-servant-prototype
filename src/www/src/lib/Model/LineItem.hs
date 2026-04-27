{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Model.LineItem
Description : Domain model and JSON instances
-}
module Model.LineItem where

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
import Data.Int (Int32)
import Data.Text (Text)
import Database.Beam (
  Beamable,
  Columnar,
  Generic,
  Identity,
  Table (..),
 )

data LineItemT f = LineItem
  { _itemId :: Columnar f Int32
  , _itemName :: Columnar f Text
  , _itemDesc :: Columnar f Text
  }
  deriving (Generic)

type LineItem = LineItemT Identity
deriving instance Show LineItem
deriving instance Eq LineItem
deriving instance Beamable LineItemT

type ItemId = PrimaryKey LineItemT Identity

instance ToJSON LineItem where
  toJSON (LineItem i n d) =
    object
      [ "id" .= i
      , "name" .= n
      , "desc" .= d
      ]

instance FromJSON LineItem where
  parseJSON = withObject "LineItem" $ \v ->
    LineItem <$> v .: "id" <*> v .: "name" <*> v .: "desc"

instance Table LineItemT where
  data PrimaryKey LineItemT f = ItemId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey = ItemId . _itemId

-- | New item (no ID yet)
data NewLineItem = NewLineItem
  { newLineItemName :: Text
  , newLineItemDesc :: Text
  }
  deriving (Show, Eq)

-- | JSON for NewLineItem (request body)
instance ToJSON NewLineItem where
  toJSON (NewLineItem n d) = object ["name" .= n, "desc" .= d]

instance FromJSON NewLineItem where
  parseJSON = withObject "NewLineItem" $ \v ->
    NewLineItem <$> v .: "name" <*> v .:? "desc" .!= ""
