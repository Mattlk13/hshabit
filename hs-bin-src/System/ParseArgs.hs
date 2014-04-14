module System.ParseArgs(
                         Command(..)
                       , habitHelp
                       , parseCommandLine
                       , getInputFile
                       , getOutputFile
                       )
 where

import Data.Monoid
import Options.Applicative
import Options.Applicative.Help.Core
import Text.PrettyPrint.ANSI.Leijen(SimpleDoc,renderPretty)

data Command = Help
             | Version
             | Lexer { lexOutputFile       :: FilePath
                     , lexAddIndentInfo    :: Bool
                     , lexEmitIndentBlocks :: Bool
                     , lexInputFile        :: FilePath
                     }
 deriving (Show)

getInputFile :: Command -> FilePath
getInputFile Lexer{ lexInputFile = f } = f
getInputFile _                         =
  error "INTERNAL ERROR: get input file"

getOutputFile :: Command -> FilePath
getOutputFile Lexer{ lexOutputFile = f } = f
getOutputFile _                          =
  error "INTERNAL ERROR: get output file"

habitOptions :: Parser Command
habitOptions = subparser (helpCmd <> versionCmd <> lexCmd)
 where
  helpCmd     = command "help"    (info (pure Help)    (progDesc "Show the help."))
  versionCmd  = command "version" (info (pure Version) (progDesc "Show the version."))
  lexCmd      = command "lex"     (info lexeropts      (progDesc "Lex an input file."))
  --
  lexeropts   = Lexer <$> outputFlag <*> addIndFlag <*> emitBlFlag <*> inputFile
  addIndFlag  = flag False True (long "addIndent" <> short 'i'
                                   <> help "Add automatic indenting information.")
  emitBlFlag  = flag False True (long "emitBlocks" <> short 'e'
                                   <> help "Emit inferred block tokens.")
  --
  outputFlag  = strOption (long "output" <> short 'o' <> metavar "FILE" <> value ""
                                         <> help "Output to the given file.")
  inputFile   = argument str (metavar "FILE")


habitHelp :: SimpleDoc
habitHelp = renderPretty 0.9 80 (helpText (parserHelp undefined habitOptions))

parseCommandLine :: IO Command
parseCommandLine  = execParser (info (habitOptions <**> helper) idm)