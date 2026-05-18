{-# LANGUAGE DataKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module API.WebSockets where

import Conduit
import Data.ByteString ( ByteString )
import Network.Wai ( Request, Response, ResponseReceived )
import Network.WebSockets.Connection ( ConnectionOptions )
import Servant
import Servant.Server.Internal.Delayed ( runDelayed )
import Servant.Server.Internal.Router ( leafRouter )
import Servant.Server.Internal.RouteResult ( RouteResult(..) )

data WebSocketStream

instance HasServer WebSocketStream ctx where
  type ServerT WebSocketStream m = (ConnectionOptions, ConduitT ByteString ByteString (ResourceT IO) ())

  hoistServerWithContext _ _ _ server = server

  route _ _ delayed = leafRouter $ \env req respK -> runResourceT $ do
    result <- runDelayed delayed env req
    go req respK result
    where
      go
        :: Request
        -> (RouteResult Response -> IO ResponseReceived)
        -> RouteResult (ServerT WebSocketStream IO)
        -> ResourceT IO ResponseReceived
      go req respK (Route (options, conduit)) = undefined
      go _req respK (Fail e) = liftIO $ respK $ Fail e
      go _req respK (FailFatal e) = liftIO $ respK $ FailFatal e
