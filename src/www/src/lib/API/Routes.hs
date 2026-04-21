{-# LANGUAGE OverloadedStrings #-}

module API.Routes where

import API.Handlers (
  handleCreate,
  handleDelete,
  handleGetAll,
  handleGetOne,
  handleUpdate,
 )
import API.Types (ApiResponse, err)
import Control.Monad.IO.Class (liftIO)
import DB.ItemRepo (ItemRepo, runItemRepoSQLite)
import Data.Aeson (encode)
import Data.Function ((&))
import Database.SQLite.Simple (Connection)
import Effects.Error (AppError (..), runAppError)
import Effects.Logger (Logger, runLoggerIO)
import Model.Types (Item, NewItem)
import Polysemy (Embed, Sem, runM)
import Polysemy.Error (Error)
import Servant (
  Capture,
  Delete,
  Get,
  Handler (..),
  JSON,
  Post,
  Proxy (..),
  Put,
  ReqBody,
  Server,
  ServerError (errBody),
  ServerT,
  err400,
  err404,
  err500,
  throwError,
  type (:<|>) (..),
  type (:>),
 )
import Servant.Server (hoistServer)

-- | Route definitions
type ItemAPI =
  Get '[JSON] (ApiResponse [Item])
    :<|> Capture "id" Int :> Get '[JSON] (ApiResponse Item)
    :<|> ReqBody '[JSON] NewItem :> Post '[JSON] (ApiResponse Item)
    :<|> Capture "id" Int
      :> ReqBody '[JSON] NewItem
      :> Put '[JSON] (ApiResponse Item) -- PUT  /items/:id
    :<|> Capture "id" Int :> Delete '[JSON] (ApiResponse Bool) -- DEL  /items/:id

type API = "items" :> ItemAPI

api :: Proxy API
api = Proxy

-- | Server implementation
semServer :: ServerT API (Sem '[ItemRepo, Logger, Error AppError, Embed IO])
semServer =
  handleGetAll
    :<|> handleGetOne
    :<|> handleCreate
    :<|> handleUpdate
    :<|> handleDelete

runner
  :: Connection
  -> Sem [ItemRepo, Logger, Error AppError, Embed IO] a
  -> Handler a -- IO (Either AppError a)
runner conn action =
  liftIO
    ( action
        & runItemRepoSQLite conn -- interpret ItemRepo with SQLite
        & runLoggerIO -- interpret Logger with IO
        & runAppError -- interpret Error AppError -> Either
        & runM -- Embed IO -> IO
    )
    >>= \case
      Left (NotFound msg) -> throwError $ err404{errBody = encode (err msg)}
      Left (ValidationError msg) -> throwError $ err400{errBody = encode (err msg)}
      Left (DatabaseError msg) -> throwError $ err500{errBody = encode (err msg)}
      Right x -> pure x

server :: Connection -> Server API
server conn = hoistServer api (runner conn) semServer
