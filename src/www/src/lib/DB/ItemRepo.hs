{-# LANGUAGE OverloadedStrings #-}

module DB.ItemRepo where

import Database.SQLite.Simple (
  Connection,
  Only (..),
  changes,
  execute,
  lastInsertRowId,
  query,
  query_,
 )
import Effects.Error (AppError)
import Model.Types (Item (Item), NewItem (NewItem))
import Polysemy (Embed, Members, Sem, embed, interpret, makeSem)
import Polysemy.Error (Error)

-- | Repository effect
data ItemRepo m a where
  GetAllItems :: ItemRepo m [Item]
  GetItemById :: Int -> ItemRepo m (Maybe Item)
  CreateItem :: NewItem -> ItemRepo m Item
  UpdateItem :: Int -> NewItem -> ItemRepo m (Maybe Item)
  DeleteItem :: Int -> ItemRepo m Bool

makeSem ''ItemRepo

-- | SQLite interpreter
runItemRepoSQLite
  :: (Members '[Embed IO, Error AppError] r)
  => Connection
  -> Sem (ItemRepo ': r) a
  -> Sem r a
runItemRepoSQLite conn = interpret $ \case
  GetAllItems ->
    embed $ query_ conn "SELECT id, name, desc FROM items"
  GetItemById itemId -> do
    rows <-
      embed $
        query
          conn
          "SELECT id, name, desc FROM items WHERE id = ?"
          (Only itemId)
    pure $ case rows of
      (x : _) -> Just x
      [] -> Nothing
  CreateItem (NewItem name desc) -> do
    embed $
      execute
        conn
        "INSERT INTO items (name, desc) VALUES (?, ?)"
        (name, desc)
    rowId <- embed $ lastInsertRowId conn
    pure $ Item (fromIntegral rowId) name desc
  UpdateItem itemId (NewItem name desc) -> do
    embed $
      execute
        conn
        "UPDATE items SET name = ?, desc = ? WHERE id = ?"
        (name, desc, itemId)
    changes_ <- embed $ changes conn
    if changes_ > 0
      then pure $ Just (Item itemId name desc)
      else pure Nothing
  DeleteItem itemId -> do
    embed $
      execute
        conn
        "DELETE FROM items WHERE id = ?"
        (Only itemId)
    changes <- embed $ changes conn
    pure (changes > 0)
