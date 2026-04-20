module Main (main) where

import Test.Tasty (defaultMain, testGroup)
import Test.Tasty.Hspec (testSpec)
import qualified Tests.NaiveSpecs

main :: IO ()
main = do
  naiveSpecs <- testSpec "hspec tests " Tests.NaiveSpecs.specSuite

  defaultMain
    ( testGroup
        "tests"
        [ naiveSpecs
        ]
    )
