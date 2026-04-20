module Tests.NaiveSpecs where

import Test.Hspec (Spec, describe, it, shouldBe)

specSuite :: Spec
specSuite =
  describe "Project1 naive specs" $ do
    it "do something interesting" $ do
      "fail" `shouldBe` "pass"
