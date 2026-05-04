{-# LANGUAGE RecordWildCards #-}

module Main where

import API.Server (startServer)
import CLI (appConfigIO)

main :: IO ()
main = do
  -- TODO: cli to read config
  appConfigIO >>= startServer
