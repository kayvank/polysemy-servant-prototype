{-# LANGUAGE OverloadedStrings #-}

module Effects.CLI where

import Data.Char (toLower)
import Effects.Config
import Effects.Error
import Options.Applicative
import Polysemy
import Polysemy.Error (Error, throw)

fileInput :: Parser ConfigInput
fileInput =
  ConfigInputFile
    <$> strOption
      ( long "config-file"
          <> short 'f'
          <> metavar "FILEPATH"
          <> help "Path to config file"
      )

stdInput :: Parser ConfigInput
stdInput =
  flag'
    StdInput
    (long "stdin" <> help "Read config from stdin")

inputParser :: Parser ConfigInput
inputParser = fileInput <|> stdInput

parseLogLevel :: String -> Either String LogLevel
parseLogLevel s = case map toLower s of
  "debug" -> Right DEBUG
  "info" -> Right INFO
  "warning" -> Right WARN
  "error" -> Right ERROR
  _ -> Left "Valid levels: debug, info, warning, error"

logLevelReader :: ReadM LogLevel
logLevelReader = eitherReader parseLogLevel

logLevelParser :: Parser LogLevel
logLevelParser =
  option
    logLevelReader
    ( long "log-level"
        <> short 'l'
        <> help "Set log level (debug, info, warning, error)"
        <> value INFO -- Default value
        <> showDefault
    )

debugFlag :: Parser Bool
debugFlag =
  switch
    ( long "debug"
        <> help "Enable debug mode"
    )
infoFlag :: Parser Bool
infoFlag =
  switch
    ( long "info"
        <> help "Enable info mode"
    )
warnFlag :: Parser Bool
warnFlag =
  switch
    ( long "warn"
        <> help "Enable warn mode"
    )
errorFlag :: Parser Bool
errorFlag =
  switch
    ( long "error"
        <> help "Enable error mode"
    )

connectionStringParser :: Parser String
connectionStringParser =
  strOption
    ( long "db-connection"
        <> short 'd'
        <> metavar "CONNECTION_STRING"
        <> help "Database connection string"
        <> value ".db/myapp.db"
        <> showDefault
    )

appDBConfigParser :: Parser DBConfig
appDBConfigParser = undefined

appNetworkConfigParser :: Parser NetworkConfig
appNetworkConfigParser =
  NetworkConfig
    <$> option
      auto
      ( long "port"
          <> short 'p'
          <> help "Port to run the server on"
          <> value 8080
          <> showDefault
      )

appNameParser :: Parser AppName
appNameParser = pure (AppName "MyApp")

appConfigParser :: Parser AppConfig
appConfigParser =
  AppConfig
    <$> appDBConfigParser
    <*> appNetworkConfigParser
    <*> appNameParser
    <*> logLevelParser
