{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}

module Effects.CLI where

import Data.Char (toLower)
import Data.String.Interpolate (i)
import Data.Text qualified as Text
import Effects.Config (
  AppConfig,
  AppName (AppName),
  Config (Config),
  ConfigInput (..),
  ConnectionString (ConnectionString),
  NetworkConfig (NetworkConfig),
  configToAppConfig,
 )
import Log.LogLevel (LogLevel (..))
import Log.Logger (Logger, logInfo, runLoggerIO)
import Options.Applicative (
  Alternative ((<|>)),
  Parser,
  ParserInfo,
  ReadM,
  auto,
  eitherReader,
  execParser,
  flag',
  fullDesc,
  header,
  help,
  helper,
  info,
  long,
  metavar,
  option,
  progDesc,
  short,
  showDefault,
  strOption,
  value,
  (<**>),
 )
import Polysemy (Embed, Member, Members, Sem, embed, runM)

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

connectionStringParser :: Parser ConnectionString
connectionStringParser =
  ConnectionString . Text.pack
    <$> strOption
      ( long "db-path"
          <> short 'd'
          <> metavar "PATH"
          <> help "SQlite connection path, e.g. for .db/myapp.db"
          <> value ".db/myapp.db"
          <> showDefault
      )

networkConfigParser :: Parser NetworkConfig
networkConfigParser =
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

configParser :: Parser Config
configParser =
  Config
    <$> connectionStringParser
    <*> networkConfigParser
    <*> appNameParser
    <*> logLevelParser

runCli :: (Member (Embed IO) r) => Sem r Config
runCli =
  let
    opts :: ParserInfo Config
    opts =
      info
        (configParser <**> helper)
        ( fullDesc
            <> progDesc "Run the application with the specified configuration"
            <> header "MyApp - a sample application demonstrating Polysemy effects and Beam with Sqlite backend"
        )
   in
    embed $ execParser opts

appConfigFromCli :: (Members '[Embed IO, Logger] r) => Sem r AppConfig
appConfigFromCli = do
  config <- runCli
  logInfo [i|Loaded config: #{config}|]
  embed $ configToAppConfig config

appConfigIO :: IO AppConfig
appConfigIO = runM $ runLoggerIO appConfigFromCli
