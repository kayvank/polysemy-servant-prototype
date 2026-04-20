module Effects.Error where

import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)
import Polysemy (Member, Sem)
import Polysemy.Error (Error, runError, throw)

-- | Domain errors
data AppError
  = NotFound Text
  | ValidationError Text
  | DatabaseError Text
  deriving (Show, Eq, Generic)

instance ToJSON AppError
instance FromJSON AppError

-- | Convenience aliases
throwNotFound :: (Member (Error AppError) r) => Text -> Sem r a
throwNotFound = throw . NotFound

throwValidation :: (Member (Error AppError) r) => Text -> Sem r a
throwValidation = throw . ValidationError

throwDbError :: (Member (Error AppError) r) => Text -> Sem r a
throwDbError = throw . DatabaseError

-- | Re-export polysemy error helpers for convenience
runAppError :: Sem (Error AppError ': r) a -> Sem r (Either AppError a)
runAppError = runError
