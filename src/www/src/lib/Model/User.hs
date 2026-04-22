{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}

{- | Module      : Model.User
Description : Domain model and JSON instances for User
-}
module Model.User where

import Data.Aeson (
  FromJSON,
  KeyValue ((.=)),
  ToJSON (toJSON),
  object,
  withObject,
  (.:),
 )
import Data.Aeson.Types (parseJSON)
import Data.Int (Int32)
import Data.Text (Text)
import Database.Beam (
  Beamable,
  Columnar,
  Generic,
  Identity,
  Table (..),
 )

data UserT f = User
  { _userEmail :: Columnar f Text
  , _userFirstName :: Columnar f Text
  , _userLastName :: Columnar f Text
  , _userId :: Columnar f Int32
  }
  deriving (Generic)

-- | New user (no ID yet)
data NewUser = NewUser
  { newUserEmail :: Text
  , newUserFirstName :: Text
  , newUserLastName :: Text
  }
  deriving (Show, Eq)

instance ToJSON NewUser where
  toJSON (NewUser email firstName lastName) =
    object
      [ "email" .= email
      , "firstName" .= firstName
      , "lastName" .= lastName
      ]

instance FromJSON NewUser where
  parseJSON = withObject "NewUser" $ \v ->
    NewUser
      <$> v .: "email"
      <*> v .: "firstName"
      <*> v .: "lastName"

type User = UserT Identity
type UserId = PrimaryKey UserT Identity

instance ToJSON User where
  toJSON (User email firstName lastName id) =
    object
      [ "email" .= email
      , "firstName" .= firstName
      , "lastName" .= lastName
      , "id" .= id
      ]
instance FromJSON User where
  parseJSON = withObject "User" $ \v ->
    User
      <$> v .: "email"
      <*> v .: "firstName"
      <*> v .: "lastName"
      <*> v .: "id"

deriving instance Show User
deriving instance Eq User
deriving instance Beamable UserT

instance Table UserT where
  data PrimaryKey UserT f = UserId (Columnar f Int32) deriving (Generic, Beamable)
  primaryKey :: UserT f -> PrimaryKey UserT f
  primaryKey = UserId . _userId
