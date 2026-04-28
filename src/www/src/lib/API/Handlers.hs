{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

{- |
Module      : API.Handlers
Description : Handlers for API endpoints
-}
module API.Handlers (
  -- * Handlers for LineItem operations
  handleGetAllLineItem,
  handleGetOneLineItem,
  handleCreateLineItem,
  handleUpdateLineItem,
  handleDeleteLineItem,

  -- * Handler for User operations
  handleGetAllUsers,
  handleGetOneUser,
  handleCreateUser,
  handleUpdateUser,
) where

import API.ApiResponse (ApiResponse (..), ok)
import DB.LineItemRepository (
  LineItemRepo,
  createLineItem,
  deleteLineItem,
  getAllLineItems,
  getLineItemById,
  updateLineItem,
 )
import DB.UserRepository (
  UserRepository,
  createUser,
  getAllUsers,
  getUserById,
  updateUser,
 )
import Data.String.Interpolate (i)
import Effects.Error (AppError (..), throwDBError, throwNotFound)
import Log.Logger (Logger, logDebug)
import Model.LineItem (LineItem, NewLineItem)
import Model.User (NewUser, User)
import Polysemy (Members, Sem)
import Polysemy.Error (Error)

type IsLineItemHandler r = Members '[LineItemRepo, Logger, Error AppError] r
type IsUserHandler r = Members '[UserRepository, Logger, Error AppError] r

handleGetAllLineItem :: (IsLineItemHandler r) => Sem r (ApiResponse [LineItem])
handleGetAllLineItem =
  logDebug "handleGetAllLineItem" >> (ok <$> getAllLineItems)

handleGetOneLineItem :: (IsLineItemHandler r) => Int -> Sem r (ApiResponse LineItem)
handleGetOneLineItem itemId = do
  logDebug [i|handleGetOneLineItem #{itemId}|]
  mLineItem <- getLineItemById $ fromIntegral itemId
  case mLineItem of
    Nothing -> logDebug "notfound...." >> throwNotFound [i|LineItem #{itemId} not found|]
    Just item -> pure (ok item)

handleCreateLineItem
  :: (IsLineItemHandler r) => NewLineItem -> Sem r (ApiResponse LineItem)
handleCreateLineItem body = do
  logDebug [i|handleCreateLineItem #{body}|]
  createLineItem body >>= \case
    Nothing -> throwDBError "Failed to store LineItem"
    Just item -> pure $ ok item

handleUpdateLineItem
  :: (IsLineItemHandler r) => Int -> NewLineItem -> Sem r (ApiResponse LineItem)
handleUpdateLineItem lineItemId body = do
  logDebug [i|handleUpdateLineItem #{lineItemId} with #{body}|]
  lineItem <- updateLineItem (fromIntegral lineItemId) body
  case lineItem of
    Nothing -> throwNotFound [i|LineItem #{lineItemId} not found|]
    Just lineItem' -> pure (ok lineItem')

handleDeleteLineItem :: (IsLineItemHandler r) => Int -> Sem r (ApiResponse Bool)
handleDeleteLineItem lineItemId = do
  logDebug [i|handleDeleteLineItem #{lineItemId}|]
  deleted <- deleteLineItem $ fromIntegral lineItemId
  if deleted
    then pure (ok True)
    else throwNotFound [i|LineItem #{lineItemId} not found|]

handleGetAllUsers :: (IsUserHandler r) => Sem r (ApiResponse [User])
handleGetAllUsers =
  logDebug "handleGetAllUsers" >> (ok <$> getAllUsers)

handleUpdateUser :: (IsUserHandler r) => Int -> NewUser -> Sem r (ApiResponse User)
handleUpdateUser userId body = do
  user <- updateUser (fromIntegral userId) body
  case user of
    Nothing -> throwNotFound [i|User #{userId} not found|]
    Just user' -> pure (ok user')

handleCreateUser :: (IsUserHandler r) => NewUser -> Sem r (ApiResponse User)
handleCreateUser newUser =
  createUser newUser >>= \case
    Nothing -> throwDBError "Failed to store User"
    Just user -> pure $ ok user

handleGetOneUser :: (IsUserHandler r) => Int -> Sem r (ApiResponse User)
handleGetOneUser userId =
  getUserById (fromIntegral userId) >>= \case
    Nothing -> throwNotFound [i|User #{userId} not found|]
    Just user -> pure (ok user)
