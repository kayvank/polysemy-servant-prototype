{-# LANGUAGE OverloadedStrings #-}

module API.Handlers where

import API.Types (ApiResponse (..), ok)
import DB.ItemRepo (
  ItemRepo,
  createItem,
  deleteItem,
  getAllItems,
  getItemById,
  updateItem,
 )
import Data.Text qualified as T
import Effects.Error (AppError (..), throwNotFound)
import Effects.Logger (Logger, logInfo)
import Model.Types (Item, NewItem)
import Polysemy (Sem, Members)
import Polysemy.Error (Error)

type IsHandler r = Members '[ItemRepo, Logger, Error AppError] r

handleGetAll :: Members '[ItemRepo, Logger] r => Sem r (ApiResponse [Item])
handleGetAll = do
  logInfo "GET /items"
  items <- getAllItems
  pure (ok items)

handleGetOne :: IsHandler r => Int -> Sem r (ApiResponse Item)
handleGetOne itemId = do
  logInfo $ "GET /items/" <> T.pack (show itemId)
  mItem <- getItemById itemId
  case mItem of
    Nothing -> throwNotFound $ "Item " <> T.pack (show itemId) <> " not found"
    Just item -> pure (ok item)

handleCreate :: Members '[ItemRepo, Logger] r => NewItem -> Sem r (ApiResponse Item)
handleCreate body = do
  logInfo "POST /items"
  item <- createItem body
  pure (ok item)

handleUpdate
  :: IsHandler r => Int -> NewItem -> Sem r (ApiResponse Item)
handleUpdate itemId body = do
  logInfo $ "PUT /items/" <> T.pack (show itemId)
  mItem <- updateItem itemId body
  case mItem of
    Nothing -> throwNotFound $ "Item " <> T.pack (show itemId) <> " not found"
    Just item -> pure (ok item)

handleDelete :: IsHandler r => Int -> Sem r (ApiResponse Bool)
handleDelete itemId = do
  logInfo $ "DELETE /items/" <> T.pack (show itemId)
  deleted <- deleteItem itemId
  if deleted
    then pure (ok True)
    else throwNotFound $ "Item " <> T.pack (show itemId) <> " not found"
