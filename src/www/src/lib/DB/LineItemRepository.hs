{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

{- |
Module      : DB.LineItemRepo
Description : Repository effect and SQLite interpreter
-}
module DB.LineItemRepository where

import DB.Database (
  ShoppingCartDB (shoppingCartLineItems),
  shoppingCartDB,
  withPool,
 )
import Data.Int (Int32)
import Data.Maybe (listToMaybe)
import Database.Beam (
  FromBackendRow,
  MonadBeam,
  SqlValable (val_),
  all_,
  default_,
  insertExpressions,
  lookup_,
  runSelectReturningList,
  runSelectReturningOne,
  runUpdate,
  save,
  select,
  (==.),
 )
import Database.Beam.Sqlite (
  Sqlite,
  insertReturning,
  runBeamSqlite,
  runSqliteInsertReturningList,
 )
import Database.Beam.Sqlite.Connection (deleteReturning, runSqliteDeleteReturningList)
import Effects.Config (AppConfig, getPool)
import Effects.Error (AppError)
import Model.LineItem (
  LineItem,
  LineItemT (LineItem, _itemDesc, _itemId, _itemName),
  NewLineItem (..),
  PrimaryKey (ItemId),
 )
import Polysemy (Embed, Members, Sem, embed, interpret, makeSem)
import Polysemy.Error (Error)
import Polysemy.Reader (Reader, asks)

-- | Repository effect
data LineItemRepo m a where
  GetAllLineItems :: LineItemRepo m [LineItem]
  GetLineItemById :: Int32 -> LineItemRepo m (Maybe LineItem)
  CreateLineItem :: NewLineItem -> LineItemRepo m (Maybe LineItem)
  UpdateLineItem :: Int32 -> NewLineItem -> LineItemRepo m (Maybe LineItem)
  DeleteLineItem :: Int32 -> LineItemRepo m Bool

makeSem ''LineItemRepo

-- | SQLite interpreter
runLineItemRepoSQLite
  :: (Members '[Reader AppConfig, Error AppError, Embed IO] r)
  => Sem (LineItemRepo ': r) a
  -> Sem r a
runLineItemRepoSQLite = interpret $ \case
  GetAllLineItems -> getAllLineItemsDB
  GetLineItemById lineItemId -> getLineItemByIdDB lineItemId
  CreateLineItem newLineItem -> createLineItemDB newLineItem
  UpdateLineItem lineItemId newLineItem -> updateLineItemDB lineItemId newLineItem
  DeleteLineItem lineItemId -> deleteLineItemDB lineItemId

type IsHandler r = Members '[Embed IO, Reader AppConfig] r

getAllLineItemsDB' :: (MonadBeam Sqlite m, FromBackendRow Sqlite LineItem) => m [LineItem]
getAllLineItemsDB' = runSelectReturningList $ select $ all_ (shoppingCartLineItems shoppingCartDB)

getAllLineItemsDB :: (IsHandler r) => Sem r [LineItem]
getAllLineItemsDB = do
  pool <- asks getPool
  embed $ withPool pool $ \conn -> runBeamSqlite conn getAllLineItemsDB'

getLineItemByIdDB'
  :: (MonadBeam Sqlite m, FromBackendRow Sqlite LineItem) => Int32 -> m (Maybe LineItem)
getLineItemByIdDB' itemId =
  runSelectReturningOne $
    lookup_ (shoppingCartLineItems shoppingCartDB) (ItemId itemId)

getLineItemByIdDB :: (IsHandler r) => Int32 -> Sem r (Maybe LineItem)
getLineItemByIdDB lineItemId = do
  pool <- asks getPool
  embed $ withPool pool $ \conn -> runBeamSqlite conn $ getLineItemByIdDB' lineItemId

createLineItemDB'
  :: (MonadBeam Sqlite m, FromBackendRow Sqlite LineItem) => NewLineItem -> m (Maybe LineItem)
createLineItemDB' NewLineItem{..} =
  listToMaybe
    <$> runSqliteInsertReturningList
      ( insertReturning (shoppingCartLineItems shoppingCartDB) $
          insertExpressions
            [ LineItem
                { _itemName = val_ newLineItemName
                , _itemDesc = val_ newLineItemDesc
                , _itemId = default_
                }
            ]
      )

createLineItemDB :: (IsHandler r) => NewLineItem -> Sem r (Maybe LineItem)
createLineItemDB newLineItem = do
  pool <- asks getPool
  embed $ withPool pool $ \conn -> runBeamSqlite conn $ createLineItemDB' newLineItem

updateLineItemDB'
  :: (MonadBeam Sqlite m, FromBackendRow Sqlite LineItem) => Int32 -> NewLineItem -> m (Maybe LineItem)
updateLineItemDB' lineItemId newItem = do
  getLineItemByIdDB' lineItemId >>= \case
    Nothing -> pure Nothing
    Just lineItem -> do
      runUpdate $
        save (shoppingCartLineItems shoppingCartDB) $
          lineItem
            { _itemName = newLineItemName newItem
            , _itemDesc = newLineItemDesc newItem
            }
      getLineItemByIdDB' lineItemId

updateLineItemDB :: (IsHandler r) => Int32 -> NewLineItem -> Sem r (Maybe LineItem)
updateLineItemDB lineItemId newLineItem = do
  pool <- asks getPool
  embed $ withPool pool $ \conn -> runBeamSqlite conn $ updateLineItemDB' lineItemId newLineItem

deleteLineItemDB' :: (MonadBeam Sqlite m) => Int32 -> m Bool
deleteLineItemDB' lid =
  not . null
    <$> runSqliteDeleteReturningList
      ( deleteReturning
          (shoppingCartLineItems shoppingCartDB)
          (\lineItem -> _itemId lineItem ==. val_ lid)
          _itemId
      )

deleteLineItemDB :: (IsHandler r) => Int32 -> Sem r Bool
deleteLineItemDB linteItemId = do
  pool <- asks getPool
  embed $ withPool pool $ \conn -> runBeamSqlite conn $ deleteLineItemDB' linteItemId
