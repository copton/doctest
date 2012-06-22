module RunSpec (main, spec) where

import           Test.Hspec.ShouldBe hiding (Summary)
import           System.Exit

import           Control.Exception
import           System.Directory (getCurrentDirectory, setCurrentDirectory)
import           Data.List

import           System.IO.Silently
import           System.IO (stderr)

import           Run

withCurrentDirectory :: FilePath -> IO a -> IO a
withCurrentDirectory workingDir action = do
  bracket getCurrentDirectory setCurrentDirectory $ \_ -> do
    setCurrentDirectory workingDir
    action

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "doctest" $ do
    it "exits with ExitFailure, if at least one test case fails" $ do
      hSilence [stderr] (doctest ["test/integration/failing/Foo.hs"]) `shouldThrow` (== ExitFailure 1)

    it "prints help on --help" $ do
      (r, e) <- (capture . try) (doctest ["--help"])
      e `shouldBe` Left ExitSuccess
      lines r `shouldBe` [
          "Usage: doctest [OPTION]... MODULE..."
        , ""
        , "      --optghc=OPTION  option to be forwarded to GHC"
        , "  -v  --verbose        explain what is being done, enable Haddock warnings"
        , "      --help           display this help and exit"
        , "      --version        output version information and exit"
        ]

    it "prints resion on --version" $ do
      (r, e) <- (capture . try) (doctest ["--version"])
      e `shouldBe` Left ExitSuccess
      lines r `shouldSatisfy` any (isPrefixOf "doctest version ")

  describe "doctest_" $ do
    context "on parse error" $ do
      let action = withCurrentDirectory "test/integration/parse-error" (doctest_ ["Foo.hs"])

      it "aborts with (ExitFailure 1)" $ do
        hSilence [stderr] action `shouldThrow` (== ExitFailure 1)

      it "prints a useful error message" $ do
        (r, _) <- hCapture [stderr] (try action :: IO (Either ExitCode Summary))
        r `shouldBe` "\nFoo.hs:6:1: parse error (possibly incorrect indentation)\n"
