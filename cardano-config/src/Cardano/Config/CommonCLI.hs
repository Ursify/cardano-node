{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE NamedFieldPuns #-}

{-# OPTIONS_GHC -Wno-all-missed-specialisations #-}

module Cardano.Config.CommonCLI
  ( command'
  , lastOption
  , lastAutoOption
  , lastIntOption
  , lastDoubleOption
  , lastBoolOption
  , lastWordOption
  , lastTextListOption
  , lastStrOption
  , lastStrOptionM
  , lastFlag
  , parseDbPathLast
  , parseDelegationCert
  , parseDelegationCertLast
  , parseGenesisHash
  , parseGenesisHashLast
  , parseGenesisPath
  , parseGenesisPathLast
  , parsePbftSigThreshold
  , parsePbftSigThresholdLast
  , parseRequiresNetworkMagic
  , parseRequiresNetworkMagicLast
  , parseSigningKey
  , parseSlotLengthLast
  , parseSocketDir
  , parseSocketDirLast
  -- Last Parsers
  , parseSigningKeyLast

  ) where

import           Cardano.Prelude hiding (option)
import qualified Prelude

import           Options.Applicative hiding (command)
import qualified Options.Applicative as OA

import           Cardano.Crypto (RequiresNetworkMagic(..))
import qualified Ouroboros.Consensus.BlockchainTime as Consensus


{-------------------------------------------------------------------------------
  Common CLI
-------------------------------------------------------------------------------}

parseDbPathLast :: Parser (Last FilePath)
parseDbPathLast =
  lastStrOption
    ( long "database-path"
        <> metavar "FILEPATH"
        <> help "Directory where the state is stored."
    )
parseGenesisPath :: Parser FilePath
parseGenesisPath =
  strOption
    ( long "genesis-file"
        <> metavar "FILEPATH"
        <> help "The filepath to the genesis file."
    )

parseGenesisPathLast :: Parser (Last FilePath)
parseGenesisPathLast =
  lastStrOption
    ( long "genesis-file"
        <> metavar "FILEPATH"
        <> help "The filepath to the genesis file."
    )

parseGenesisHash :: Parser Text
parseGenesisHash =
  strOption
    ( long "genesis-hash"
        <> metavar "GENESIS-HASH"
        <> help "The genesis hash value."
    )

parseGenesisHashLast :: Parser (Last Text)
parseGenesisHashLast =
  lastStrOption
    ( long "genesis-hash"
        <> metavar "GENESIS-HASH"
        <> help "The genesis hash value."
    )
parseDelegationCert :: Parser FilePath
parseDelegationCert =
  strOption
    ( long "delegation-certificate"
        <> metavar "FILEPATH"
        <> help "Path to the delegation certificate."
    )

parseDelegationCertLast :: Parser (Last FilePath)
parseDelegationCertLast =
  lastStrOption
    ( long "delegation-certificate"
        <> metavar "FILEPATH"
        <> help "Path to the delegation certificate."
    )

parseSigningKeyLast :: Parser (Last FilePath)
parseSigningKeyLast =
  lastStrOption
    ( long "signing-key"
        <> metavar "FILEPATH"
        <> help "Path to the signing key."
    )

parseSigningKey :: Parser FilePath
parseSigningKey =
  strOption
    ( long "signing-key"
        <> metavar "FILEPATH"
        <> help "Path to the signing key."
    )

parseSocketDir :: Parser FilePath
parseSocketDir =
  strOption
    ( long "socket-dir"
        <> metavar "FILEPATH"
        <> help "Directory with local sockets:\
                \  ${dir}/node-{core,relay}-${node-id}.socket"
    )

parseSocketDirLast :: Parser (Last FilePath)
parseSocketDirLast =
  lastStrOption
    ( long "socket-dir"
        <> metavar "FILEPATH"
        <> help "Directory with local sockets:\
                \  ${dir}/node-{core,relay}-${node-id}.socket"
    )


parsePbftSigThreshold :: Parser (Maybe Double)
parsePbftSigThreshold =
  optional $ option auto
    ( long "pbft-signature-threshold"
        <> metavar "DOUBLE"
        <> help "The PBFT signature threshold."
        <> hidden
    )


parsePbftSigThresholdLast :: Parser (Last Double)
parsePbftSigThresholdLast =
  lastDoubleOption
    ( long "pbft-signature-threshold"
        <> metavar "DOUBLE"
        <> help "The PBFT signature threshold."
        <> hidden
    )

parseRequiresNetworkMagic :: Parser RequiresNetworkMagic
parseRequiresNetworkMagic =
  flag RequiresNoMagic RequiresMagic
    ( long "require-network-magic"
        <> help "Require network magic in transactions."
        <> hidden
    )

parseRequiresNetworkMagicLast :: Parser (Last RequiresNetworkMagic)
parseRequiresNetworkMagicLast =
  lastFlag RequiresNoMagic RequiresMagic
    ( long "require-network-magic"
        <> help "Require network magic in transactions."
        <> hidden
    )
parseSlotLengthLast :: Parser (Last Consensus.SlotLength)
parseSlotLengthLast = do
  slotDurInteger <- lastAutoOption
                      ( long "slot-duration"
                          <> metavar "SECONDS"
                          <> help "The slot duration (seconds)"
                          <> hidden
                      )
  pure $ mkSlotLength <$> slotDurInteger
 where
  mkSlotLength :: Integer -> Consensus.SlotLength
  mkSlotLength sI = Consensus.slotLengthFromMillisec $ 1000 * sI

{-------------------------------------------------------------------------------
  optparse-applicative auxiliary
-------------------------------------------------------------------------------}

command' :: Prelude.String -> Prelude.String -> Parser a -> Mod CommandFields a
command' c descr p =
    OA.command c $ info (p <**> helper) $ mconcat [
        progDesc descr
      ]

-- TODO:  deal with cardano-shell duplication
-- | Lift the parser to an optional @Last@ type.
lastOption :: Parser a -> Parser (Last a)
lastOption parser = Last <$> optional parser

-- | General @Last@ auto option from @Read@ instance.
lastAutoOption :: Read a => Mod OptionFields a -> Parser (Last a)
lastAutoOption args = lastOption (option auto args)

lastIntOption :: Mod OptionFields Int -> Parser (Last Int)
lastIntOption = lastAutoOption

lastDoubleOption :: Mod OptionFields Double -> Parser (Last Double)
lastDoubleOption = lastAutoOption

lastBoolOption :: Mod OptionFields Bool -> Parser (Last Bool)
lastBoolOption = lastAutoOption

lastWordOption :: Mod OptionFields Word -> Parser (Last Word)
lastWordOption = lastAutoOption

lastTextListOption :: Mod OptionFields [Text] -> Parser (Last [Text])
lastTextListOption = lastAutoOption

lastStrOption :: IsString a => Mod OptionFields a -> Parser (Last a)
lastStrOption args = Last <$> optional (strOption args)

lastFlag :: a -> a -> Mod FlagFields a -> Parser (Last a)
lastFlag def act opts  = Last <$> optional (flag def act opts)

-- | Mandatory versions of option parsers.
--   Use these for the cases when presets don't define a default value
--   for a particular field -- i.e. when the field is set to 'mempty'.
lastStrOptionM :: IsString a => Mod OptionFields a -> Parser (Last a)
lastStrOptionM args = Last . Just <$> strOption args
