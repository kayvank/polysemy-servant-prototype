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
import Effects.Config
import Effects.Error (AppError (..), runAppError)
import Network.Wai.Handler.Warp qualified
import Network.Wai.Middleware.RequestLogger qualified as Logger
import Polysemy (Embed, Sem, runM)
import Polysemy.Error (Error)
import Polysemy.Log.Logging
import Polysemy.Reader (Reader, runReader)
import Polysemy.Resource
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
import Servant.Server (hoistServer, serve)

-- | Proxy for the API type
api :: Proxy API
api = Proxy

type App a =
  Sem
    [ UserRepository -- User Persistence
    , LineItemRepo -- LineItem Persistence
    , SLogger -- Logging framework
    , Resource -- Required by fast-logger
    , Error AppError -- Error handlers
    , Reader AppConfig -- Reader for Application
    , Embed IO -- Lower Polysemy to IO
    ]
    a

-- | Server implementation using Polysemy effects
semHandler
  :: ServerT
       API
       (Sem '[UserRepository, LineItemRepo, SLogger, Resource, Error AppError, Reader AppConfig, Embed IO])
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
  -- -> Sem [UserRepository, LineItemRepo, SLogger, Resource, Reader LogConfig, Error AppError, Reader AppConfig, Embed IO] a
  -> App a
  -> Handler a -- IO (Either AppError a)
lowerToHandler config action =
  liftIO
    ( action
        & runUserRepository
        & runLineItemRepoSQLite -- interpret LineItemRepo with SQLite
        & runLogger (_appLogConfig config) -- provide AppConfig to Reader-- interpret Logger with IO
        & runResource -- close logging resource
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

startServer :: AppConfig -> IO ()
startServer cfg =
  Network.Wai.Handler.Warp.run
    (_networkPort . _appNetworkConfig $ cfg)
    (Logger.logStdout (serve api (server cfg)))
