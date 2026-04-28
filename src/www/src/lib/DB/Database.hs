{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}

module DB.Database where

import Data.Aeson
import Data.Default (Default (def))
import Data.Foldable (traverse_)
import Data.Functor (void)
import Data.Pool (Pool, defaultPoolConfig, newPool, withResource)
import Data.String (IsString)
import Data.Text (Text)
import Data.Text qualified as T
import Database.Beam (
  Database,
  DatabaseSettings,
  Generic,
  TableEntity,
  int,
 )
import Database.Beam.Migrate (
  CheckedDatabaseEntity,
  CheckedDatabaseSettings,
  Migration,
  MigrationSteps,
  createTable,
  evaluateDatabase,
  field,
  migrationStep,
  notNull,
  unCheckDatabase,
  unique,
 )
import Database.Beam.Migrate.Simple (
  BringUpToDateHooks (..),
  bringUpToDateWithHooks,
  defaultUpToDateHooks,
 )
import Database.Beam.Sqlite (
  Sqlite,
  runBeamSqliteDebug,
  sqliteText,
 )
import Database.Beam.Sqlite.Migrate (migrationBackend)
import Database.SQLite.Simple (Connection, Query (Query), close, execute_, open)
import Model.LineItem (LineItemT (..))
import Model.User (UserT (..))

-- | A SQLite3 connection string
newtype ConnectionString
  = ConnectionString
  { unConnectionString :: Text
  }
  deriving (IsString) via Text
  deriving (Generic)
  deriving (Show)

instance ToJSON ConnectionString where
  toJSON (ConnectionString connStr) = object ["connectionString" .= connStr]
instance FromJSON ConnectionString where
  parseJSON = withObject "ConnectionString" $ \v ->
    ConnectionString <$> v .: "connectionString"

instance Default ConnectionString where
  def :: ConnectionString
  def = ConnectionString ".db/myapp.db"

-- | This module defines the database schema and migration logic for the shopping cart application.
data ShoppingCartDB f = ShoppingCartDB
  { shoppingCartUsers :: f (TableEntity UserT)
  , shoppingCartLineItems :: f (TableEntity LineItemT)
  }
  deriving (Generic, Database be)

-- deprecated: use createTables or initializeTables instead
shoppingCartDB :: DatabaseSettings Sqlite ShoppingCartDB
shoppingCartDB = unCheckDatabase $ evaluateDatabase initialSetupStep

createUserTable :: Migration Sqlite (CheckedDatabaseEntity Sqlite be (TableEntity UserT))
createUserTable =
  createTable
    "users"
    ( User
        { _userEmail = field "email" sqliteText notNull
        , _userFirstName = field "firstName" sqliteText notNull
        , _userLastName = field "lastName" sqliteText notNull
        , _userId = field "id" int notNull unique
        }
    )

createLineItemTable :: Migration Sqlite (CheckedDatabaseEntity Sqlite be (TableEntity LineItemT))
createLineItemTable =
  createTable
    "lineItems"
    ( LineItem
        { _itemName = field "name" sqliteText notNull
        , _itemDesc = field "desc" sqliteText notNull
        , _itemId = field "id" int notNull unique
        }
    )

-- | This migration defines the initial setup of the database, creating the necessary tables for users and line items.
initialSetup :: Migration Sqlite (CheckedDatabaseSettings Sqlite ShoppingCartDB)
initialSetup = ShoppingCartDB <$> createUserTable <*> createLineItemTable

-- | This migration step represents the initial setup of the database, which includes creating the necessary tables for users and line items.
initialSetupStep :: MigrationSteps Sqlite () (CheckedDatabaseSettings Sqlite ShoppingCartDB)
initialSetupStep = migrationStep "initia_setup" (const initialSetup)

allowDestructive :: (MonadFail m) => BringUpToDateHooks m
allowDestructive =
  defaultUpToDateHooks
    { runIrreversibleHook = pure True
    }

-- | This function performs the database migration by running the migration logic on an existing database connection. It uses the 'bringUpToDateWithHooks' function from the Beam library to apply the necessary migrations to bring the database up to date with the defined schema. The 'allowDestructive' hooks are used to allow destructive changes during the migration process.
migrateDB :: Connection -> IO (Maybe (CheckedDatabaseSettings Sqlite ShoppingCartDB))
migrateDB conn =
  runBeamSqliteDebug print conn $
    bringUpToDateWithHooks
      allowDestructive
      migrationBackend
      initialSetupStep

newtype SQLiteConnection = SQLiteConnection
  { getSQLiteConn :: Connection
  }

-- | A SQL statement
newtype SQL
  = SQL
  { unSQL :: Text
  }
  deriving (Semigroup, IsString) via Text
  deriving (Show)

-- | Default pragmas to be set when opening a connection from a pool.
defaultPragmas :: [SQL]
defaultPragmas =
  [ -- https://www.sqlite.org/pragma.html#pragma_foreign_keys
    "PRAGMA foreign_keys = on"
  , -- https://www.sqlite.org/pragma.html#pragma_busy_timeout
    "PRAGMA busy_timeout = 30000"
  , -- https://www.sqlite.org/pragma.html#pragma_journal_mode
    "PRAGMA journal_mode = WAL"
  ]

-- | Open a connection using config
openWith :: ConnectionString -> [SQL] -> IO Connection
openWith connStr sqls = do
  conn <- open (T.unpack (unConnectionString connStr))
  void $ migrateDB conn
  traverse_ (execute_ conn . Query . unSQL) sqls
  pure conn

withPool :: Pool Connection -> (Connection -> IO a) -> IO a
withPool = withResource

{- | Create a pool of a sqlite3 db with a specific connection string.
  This also sets a few default pragmas.
-}
createSqlitePool :: ConnectionString -> IO (Pool Connection)
createSqlitePool connStr = do
  newPool $
    defaultPoolConfig
      (openWith connStr defaultPragmas)
      close
      180.0
      50
