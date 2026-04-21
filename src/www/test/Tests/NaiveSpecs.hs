module Tests.NaiveSpecs where

import Test.Hspec (Spec, describe, it, shouldBe)

-- TODO add unit tests
--
specSuite :: Spec
specSuite =
  describe "Project1 naive specs" $ do
    it "do something interesting" $ do
      "pass" `shouldBe` "pass"
