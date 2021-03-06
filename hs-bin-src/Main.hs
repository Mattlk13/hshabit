import Data.ByteString.Lazy(ByteString, pack)
import qualified Data.ByteString.Lazy as BS
import Data.Char(ord)
import Data.List(intercalate)
import Syntax.Layout(scanWithLayout)
import Syntax.Parser(parse)
import Syntax.Scanner(scan)
import System.FilePath(takeFileName)
import System.IO
import System.ParseArgs
import Text.PrettyPrint.ANSI.Leijen(displayIO)

main :: IO ()
main = parseCommandLine >>= runHSHabit

runHSHabit :: Command -> IO ()
runHSHabit Help           = displayIO stderr habitHelp
runHSHabit Version        = hPutStrLn stderr "The High Speed Habit Compiler, Version 0.1"
runHSHabit c@Lex{}
  | lexEmitIndentBlocks c = runCompiler c scanWithLayout
  | otherwise             = runCompiler c scan
runHSHabit c@Parse{}
                          = runCompiler c ((:[]) .+. parse)

runCompiler :: Show a =>
               Command ->
               (Maybe FilePath -> ByteString -> [a]) ->
               IO ()
runCompiler cmd compiler =
  withFile (getInputFile cmd) ReadMode $ \ ihndl ->
    withOutputFile (getOutputFile cmd) $ \ ohndl ->
      do input <- BS.hGetContents ihndl
         let fname     = takeFileName (getInputFile cmd)
             output    = compiler (Just fname) input
             outputStr = intercalate "\n" (map show output) ++ "\n"
         BS.hPut ohndl (pack (map (fromIntegral . ord) outputStr))

withOutputFile :: FilePath -> (Handle -> IO ()) -> IO ()
withOutputFile "" action = action stdout
withOutputFile f  action = withFile f WriteMode action

(.+.) :: (c -> d) -> (a -> b -> c) -> a -> b -> d
f .+. g = \ a b -> f (g a b)

