module Main where

import Polysemy
import Polysemy.Log.Internal.Logging
import Polysemy.Resource

main :: IO ()
main = runM $ runResource $ runLogger'' logs'
