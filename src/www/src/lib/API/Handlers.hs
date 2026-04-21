{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

{- |
Module      : API.Handlers
Description : Handlers for API endpoints
-}
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
import Data.String.Interpolate (i)
import Effects.Error (AppError (..), throwNotFound)
import Effects.Logger (Logger)
import Model.Types (Item, NewItem)
import Polysemy (Members, Sem)
import Polysemy.Error (Error)

type IsHandler r = Members '[ItemRepo, Logger, Error AppError] r

handleGetAll :: (Members '[ItemRepo, Logger] r) => Sem r (ApiResponse [Item])
handleGetAll = do
  items <- getAllItems
  pure (ok items)

handleGetOne :: (IsHandler r) => Int -> Sem r (ApiResponse Item)
handleGetOne itemId = do
  mItem <- getItemById itemId
  case mItem of
    Nothing -> throwNotFound [i|Item #{itemId} not found|]
    Just item -> pure (ok item)

handleCreate :: (Members '[ItemRepo, Logger] r) => NewItem -> Sem r (ApiResponse Item)
handleCreate body = do
  item <- createItem body
  pure (ok item)

handleUpdate
  :: (IsHandler r) => Int -> NewItem -> Sem r (ApiResponse Item)
handleUpdate itemId body = do
  mItem <- updateItem itemId body
  case mItem of
    Nothing -> throwNotFound [i|Item #{itemId} not found|]
    Just item -> pure (ok item)

handleDelete :: (IsHandler r) => Int -> Sem r (ApiResponse Bool)
handleDelete itemId = do
  deleted <- deleteItem itemId
  if deleted
    then pure (ok True)
    else throwNotFound [i|Item #{itemId} not found|]
