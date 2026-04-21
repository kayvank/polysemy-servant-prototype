{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : DB.Schema
Description : Database schema initialization
-}
module DB.Schema where

import Data.Text qualified as T
import Database.SQLite.Simple (Connection, execute_, open)
import Effects.Config (AppConfig (..))

-- | Open a connection using config
openDb :: AppConfig -> IO Connection
openDb cfg = do
  conn <- open (T.unpack (configDbPath cfg))
  initSchema conn
  pure conn

-- | Create tables if they don't exist
initSchema :: Connection -> IO ()
initSchema conn =
  execute_
    conn
    "CREATE TABLE IF NOT EXISTS items \
    \( id   INTEGER PRIMARY KEY AUTOINCREMENT \
    \, name TEXT    NOT NULL                  \
    \, desc TEXT    NOT NULL DEFAULT ''       \
    \)"
