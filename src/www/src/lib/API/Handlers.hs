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
import Polysemy (Embed, Sem)
import Polysemy.Error (Error)

handleGetAll :: forall a. (Sem '[ItemRepo, Logger, Error AppError, Embed IO]) (ApiResponse [Item])
handleGetAll = do
  logInfo "GET /items"
  items <- getAllItems
  pure (ok items)
handleGetOne :: Int -> (Sem '[ItemRepo, Logger, Error AppError, Embed IO]) (ApiResponse Item)
handleGetOne itemId = do
  logInfo $ "GET /items/" <> T.pack (show itemId)
  mItem <- getItemById itemId
  case mItem of
    Nothing -> throwNotFound $ "Item " <> T.pack (show itemId) <> " not found"
    Just item -> pure (ok item)

handleCreate :: NewItem -> (Sem '[ItemRepo, Logger, Error AppError, Embed IO]) (ApiResponse Item)
handleCreate body = do
  logInfo "POST /items"
  item <- createItem body
  pure (ok item)

handleUpdate
  :: Int -> NewItem -> (Sem '[ItemRepo, Logger, Error AppError, Embed IO]) (ApiResponse Item)
handleUpdate itemId body = do
  logInfo $ "PUT /items/" <> T.pack (show itemId)
  mItem <- updateItem itemId body
  case mItem of
    Nothing -> throwNotFound $ "Item " <> T.pack (show itemId) <> " not found"
    Just item -> pure (ok item)

handleDelete :: Int -> (Sem '[ItemRepo, Logger, Error AppError, Embed IO]) (ApiResponse Bool)
handleDelete itemId = do
  logInfo $ "DELETE /items/" <> T.pack (show itemId)
  deleted <- deleteItem itemId
  if deleted
    then pure (ok True)
    else throwNotFound $ "Item " <> T.pack (show itemId) <> " not found"
