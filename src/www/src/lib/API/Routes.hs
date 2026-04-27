{- |
Module      : API.Routes
Description : Route definitions and server implementation
-}
module API.Routes (
  -- * Route handlers
  API,
) where

import API.ApiResponse (ApiResponse)
import Model.LineItem (LineItem, NewLineItem)
import Model.User (NewUser, User)
import Servant (
  Capture,
  Delete,
  Get,
  JSON,
  Post,
  Put,
  ReqBody,
  type (:<|>) (..),
  type (:>),
 )

-- | Top-level API type
type API =
  -- "users" :> UserAPI :<|>
  "items" :> LineItemAPI

type UserAPI =
  "users"
    :> ( Get '[JSON] (ApiResponse [User])
           :<|> Capture "id" Int :> Get '[JSON] (ApiResponse User)
           :<|> ReqBody '[JSON] NewUser :> Post '[JSON] ()
           :<|> Capture "id" Int :> ReqBody '[JSON] NewUser :> Put '[JSON] (ApiResponse User) -- PUT  /users/:id
       )

-- | Route definitions
type LineItemAPI =
  Get '[JSON] (ApiResponse [LineItem])
    :<|> Capture "id" Int :> Get '[JSON] (ApiResponse LineItem)
    :<|> ReqBody '[JSON] NewLineItem :> Post '[JSON] (ApiResponse LineItem)
    :<|> Capture "id" Int :> ReqBody '[JSON] NewLineItem :> Put '[JSON] (ApiResponse LineItem) -- PUT  /lineitems/:id
    :<|> Capture "id" Int :> Delete '[JSON] (ApiResponse Bool) -- DEL  /items/:id

{-
type LineItemAPI =
  "items"
    :> Get '[JSON] (ApiResponse [LineItem])
    :<|> ReqBody '[JSON] NewLineItem :> Post '[JSON] (ApiResponse LineItem)
    :<|> Capture "id" Int :> Get '[JSON] (ApiResponse LineItem)
    :<|> Capture "id" Int :> Delete '[JSON] (ApiResponse Bool) -- DEL  /items/:id
    :<|> Capture "id" Int :> ReqBody '[JSON] NewLineItem :> Put '[JSON] (ApiResponse LineItem) -- PUT  /lineitems/:id

    :<|> "users" :> Get '[JSON] (ApiResponse [User])
    :<|> Capture "id" Int :> Get '[JSON] (ApiResponse User)
    :<|> ReqBody '[JSON] NewUser :> Post '[JSON] ()
    :<|> Capture "id" Int :> ReqBody '[JSON] NewUser :> Put '[JSON] (ApiResponse User) -- PUT  /users/:id
-}
-- type UserAPI = "users" :> Get '[JSON] (ApiResponse [User])
