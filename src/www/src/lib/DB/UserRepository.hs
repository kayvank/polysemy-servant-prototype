{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}

module DB.UserRepository where

import DB.Database (
  ShoppingCartDB (..),
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
 )
import Database.Beam.Sqlite (
  Sqlite,
  insertReturning,
  runBeamSqlite,
  runInsertReturningList,
 )
import Effects.Config (AppConfig, getPool)
import Effects.Error (AppError)
import Model.User (
  NewUser (..),
  PrimaryKey (UserId),
  User,
  UserT (User, _userEmail, _userFirstName, _userId, _userLastName),
 )
import Polysemy (Embed, Members, Sem, embed, interpret, makeSem)
import Polysemy.Error (Error)
import Polysemy.Reader (Reader, asks)

data UserRepository m a where
  GetAllUsers :: UserRepository m [User]
  GetUserById :: Int32 -> UserRepository m (Maybe User)
  CreateUser :: NewUser -> UserRepository m (Maybe User)
  UpdateUser :: Int32 -> NewUser -> UserRepository m (Maybe User)

makeSem ''UserRepository

runUserRepository
  :: (Members '[Reader AppConfig, Error AppError, Embed IO] r)
  => Sem (UserRepository ': r) a
  -> Sem r a
runUserRepository = do
  interpret $ \case
    GetAllUsers -> getAllUsersDB
    GetUserById userId -> getUserByIdDB userId
    CreateUser newUser -> createUserDB newUser
    UpdateUser userId newUser -> updateUserDB userId newUser

-- TODO DeleteUser userId

type IsHandler r = Members '[Embed IO, Reader AppConfig] r

createUserDB :: (IsHandler r) => NewUser -> Sem r (Maybe User)
createUserDB user = do
  pool <- asks getPool
  embed $ withPool pool $ \conn ->
    runBeamSqlite conn $ createUserDB' user

createUserDB' :: (MonadBeam Sqlite m) => NewUser -> m (Maybe User)
createUserDB' NewUser{..} =
  listToMaybe
    <$> runInsertReturningList
      ( insertReturning (shoppingCartUsers shoppingCartDB) $
          insertExpressions
            [ User
                { _userEmail = val_ newUserEmail
                , _userFirstName = val_ newUserFirstName
                , _userLastName = val_ newUserLastName
                , _userId = default_
                }
            ]
      )

getAllUsersDB' :: (MonadBeam Sqlite m, FromBackendRow Sqlite User) => m [User]
getAllUsersDB' = runSelectReturningList $ select (all_ (shoppingCartUsers shoppingCartDB))

getAllUsersDB :: (IsHandler r, FromBackendRow Sqlite User) => Sem r [User]
getAllUsersDB = do
  pool <- asks getPool
  embed $ withPool pool $ \conn ->
    runBeamSqlite conn getAllUsersDB'

getUserByIdDB' :: (MonadBeam Sqlite m, FromBackendRow Sqlite User) => Int32 -> m (Maybe User)
getUserByIdDB' userId =
  runSelectReturningOne $
    lookup_ (shoppingCartUsers shoppingCartDB) (UserId userId)

getUserByIdDB :: (IsHandler r, FromBackendRow Sqlite User) => Int32 -> Sem r (Maybe User)
getUserByIdDB userId = do
  pool <- asks getPool
  embed $ withPool pool $ \conn ->
    runBeamSqlite conn (getUserByIdDB' userId)

updateUserDB' :: (MonadBeam Sqlite m) => Int32 -> NewUser -> m (Maybe User)
updateUserDB' userId NewUser{..} = do
  getUserByIdDB' userId >>= \case
    Nothing -> pure Nothing
    Just user -> do
      let new_user =
            user
              { _userEmail = newUserEmail
              , _userFirstName = newUserFirstName
              , _userLastName = newUserLastName
              }
      runUpdate $ save (shoppingCartUsers shoppingCartDB) new_user
      pure $ Just new_user

updateUserDB :: (IsHandler r) => Int32 -> NewUser -> Sem r (Maybe User)
updateUserDB userId newUser = do
  pool <- asks getPool
  embed $ withPool pool $ \conn ->
    runBeamSqlite conn (updateUserDB' userId newUser)
