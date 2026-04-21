{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

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
import Effects.Error (AppError (..), throwNotFound)
import Effects.Logger (Logger, logInfo)
import Model.Types (Item, NewItem)
import Polysemy (Sem, Members)
import Polysemy.Error (Error)
import Data.String.Interpolate (i)

type IsHandler r = Members '[ItemRepo, Logger, Error AppError] r

handleGetAll :: Members '[ItemRepo, Logger] r => Sem r (ApiResponse [Item])
handleGetAll = do
  items <- getAllItems
  pure (ok items)

handleGetOne :: IsHandler r => Int -> Sem r (ApiResponse Item)
handleGetOne itemId = do
  mItem <- getItemById itemId
  case mItem of
    Nothing -> throwNotFound [i|Item #{itemId} not found|]
    Just item -> pure (ok item)

handleCreate :: Members '[ItemRepo, Logger] r => NewItem -> Sem r (ApiResponse Item)
handleCreate body = do
  item <- createItem body
  pure (ok item)

handleUpdate
  :: IsHandler r => Int -> NewItem -> Sem r (ApiResponse Item)
handleUpdate itemId body = do
  mItem <- updateItem itemId body
  case mItem of
    Nothing -> throwNotFound [i|Item #{itemId} not found|]
    Just item -> pure (ok item)

handleDelete :: IsHandler r => Int -> Sem r (ApiResponse Bool)
handleDelete itemId = do
  deleted <- deleteItem itemId
  if deleted
    then pure (ok True)
    else throwNotFound [i|Item #{itemId} not found|]
