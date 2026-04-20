module Model.Types where

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
