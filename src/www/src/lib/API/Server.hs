{-# LANGUAGE OverloadedStrings #-}

module API.Server where

import API.ApiResponse (err)
import API.Handlers
import API.Routes (API)
import Control.Monad.IO.Class (liftIO)
import DB.LineItemRepository (LineItemRepo, runLineItemRepoSQLite)
import DB.UserRepository (UserRepository, runUserRepository)
import Data.Aeson (encode)
import Data.Function ((&))
import Effects.Config (AppConfig)
import Effects.Error (AppError (..), runAppError)
import Log.Logger (Logger, runLoggerIO)
import Polysemy (Embed, Sem, runM)
import Polysemy.Error (Error)
import Polysemy.Reader (Reader, runReader)
import Servant (
  Handler (..),
  Proxy (..),
  Server,
  ServerError (errBody),
  ServerT,
  err400,
  err404,
  err500,
  throwError,
  type (:<|>) (..),
 )
import Servant.Server (hoistServer)

-- | Proxy for the API type
api :: Proxy API
api = Proxy

-- | Server implementation using Polysemy effects
semHandler
  :: ServerT
       API
       (Sem '[UserRepository, LineItemRepo, Logger, Error AppError, Reader AppConfig, Embed IO])
semHandler =
  ( handleGetAllUsers
      :<|> handleGetOneUser
      :<|> handleCreateUser
      :<|> handleUpdateUser
  )
    :<|> ( handleGetAllLineItem
             :<|> handleGetOneLineItem
             :<|> handleCreateLineItem
             :<|> handleUpdateLineItem
             :<|> handleDeleteLineItem
         )

lowerToHandler
  :: AppConfig
  -> Sem [UserRepository, LineItemRepo, Logger, Error AppError, Reader AppConfig, Embed IO] a
  -> Handler a -- IO (Either AppError a)
lowerToHandler config action =
  liftIO
    ( action
        & runUserRepository
        & runLineItemRepoSQLite -- interpret LineItemRepo with SQLite
        & runLoggerIO -- interpret Logger with IO
        & runAppError -- interpret Error AppError -> Either
        & runReader config -- provide AppConfig to Reader
        & runM -- Embed IO -> IO
    )
    >>= \case
      Left (NotFound msg) -> throwError $ err404{errBody = encode (err msg)}
      Left (ValidationError msg) -> throwError $ err400{errBody = encode (err msg)}
      Left (DatabaseError msg) -> throwError $ err500{errBody = encode (err msg)}
      Right x -> pure x
      _ -> throwError $ err500{errBody = encode (err "Unknown error")}

-- | Convert our Sem server to a Servant Handler
server :: AppConfig -> Server API
server appConfig = hoistServer api (lowerToHandler appConfig) semHandler
