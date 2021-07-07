
{-# LANGUAGE CPP, PatternSynonyms, ViewPatterns #-}
module HieDb.Compat (
    nodeInfo'
    , Unit
    , unitString
    , stringToUnit
    , moduleUnit
    , unhelpfulSpanFS
    -- * Types re-exports
    , ModuleName
    , mkModuleName
    , moduleName
    , moduleNameString
    , Fingerprint
    , unpackFS
    , readHexFingerprint
    , getFileHash
    , NameSpace
    , OccName
    , mkOccName
    , nameOccName
    , occNameSpace
    , occNameString
    , mkVarOccFS
    , Name
    , nameSrcSpan
    , NameCacheUpdater(..)
    , NameCache
    , nsNames
    , initNameCache
    , lookupOrigNameCache
    , Module
    , mkModule
    , nameModule_maybe
    , nameModule
    , varName
    , isVarNameSpace
    , dataName
    , isDataConNameSpace
    , tcClsName
    , isTcClsNameSpace
    , tvName
    , isTvNameSpace
    , flLabel
    -- * Dynflags re-exports
    , DynFlags
    , defaultDynFlags
    , LlvmConfig(..)
    -- * AvailInfo
    , Avail.AvailInfo
    , pattern AvailName
    , pattern AvailFL
    , pattern AvailTC
    , flSelector
    -- * SrcSpan
    , SrcSpan(..)
    , RealSrcSpan
    , mkRealSrcLoc
    , mkRealSrcSpan
    , srcSpanStartLine
    , srcSpanStartCol
    , srcSpanEndLine
    , srcSpanEndCol
    , mkSplitUniqSupply
    -- * Systools
    , initSysTools
    -- * Hie Types
    , HiePath
    , hiePathToFS
    -- * Outputable
    , (<+>)
    , ppr
    , showSDoc
    , hang
    , text
    -- * FastString
    , FastString
    -- * IFace
    , IfaceType
    , IfaceTyCon(..)
) where

import Compat.HieTypes

#if __GLASGOW_HASKELL__ >= 900
import GHC.Data.FastString as FS
import GHC.Driver.Session
import GHC.Iface.Env
import GHC.Iface.Type
import GHC.SysTools
import qualified GHC.Types.Avail as Avail
import GHC.Types.FieldLabel
import GHC.Types.Name
import GHC.Types.Name.Cache
import GHC.Types.Unique.Supply
import GHC.Unit.Types
import GHC.Unit.Module.Name
import GHC.Utils.Fingerprint
#if __GLASGOW_HASKELL__ >= 902
import GHC.Driver.Ppr (showSDoc)
import GHC.Utils.Outputable (ppr, (<+>), hang, text)
#else
import GHC.Utils.Outputable (showSDoc, ppr, (<+>), hang, text)
#endif
#else
import DynFlags
import FastString
import Fingerprint
import FieldLabel
import Module
import Name
import NameCache
import Outputable (showSDoc, ppr, (<+>), hang, text)
import IfaceEnv (NameCacheUpdater(..))
import IfaceType
import UniqSupply
import SrcLoc
import SysTools
import qualified Avail
#endif

#if __GLASGOW_HASKELL__ >= 900
import GHC.Types.SrcLoc
import Compat.HieUtils

import qualified Data.Map as M
import qualified Data.Set as S


-- nodeInfo' :: Ord a => HieAST a -> NodeInfo a
nodeInfo' :: HieAST TypeIndex -> NodeInfo TypeIndex
nodeInfo' = M.foldl' combineNodeInfo' emptyNodeInfo . getSourcedNodeInfo . sourcedNodeInfo

combineNodeInfo' :: Ord a => NodeInfo a -> NodeInfo a -> NodeInfo a
(NodeInfo as ai ad) `combineNodeInfo'` (NodeInfo bs bi bd) =
  NodeInfo (S.union as bs) (mergeSorted ai bi) (M.unionWith (<>) ad bd)
  where
    mergeSorted :: Ord a => [a] -> [a] -> [a]
    mergeSorted la@(a:as) lb@(b:bs) = case compare a b of
                                        LT -> a : mergeSorted as lb
                                        EQ -> a : mergeSorted as bs
                                        GT -> b : mergeSorted la bs
    mergeSorted as [] = as
    mergeSorted [] bs = bs
#else
import qualified FastString as FS

nodeInfo' :: HieAST TypeIndex -> NodeInfo TypeIndex
nodeInfo' = nodeInfo
type Unit = UnitId
unitString :: Unit -> String
unitString = unitIdString
stringToUnit :: String -> Unit
stringToUnit = stringToUnitId
moduleUnit :: Module -> Unit
moduleUnit = moduleUnitId
unhelpfulSpanFS :: FS.FastString -> FS.FastString
unhelpfulSpanFS = id
#endif

#if __GLASGOW_HASKELL__ < 902
type HiePath = FastString
#endif

hiePathToFS :: HiePath -> FastString
#if __GLASGOW_HASKELL__ >= 902
hiePathToFS (LexicalFastString fs) = fs
#else
hiePathToFS fs = fs
#endif

{-# COMPLETE AvailTC, AvailName, AvailFL #-}

pattern AvailTC :: Name -> [Name] -> [FieldLabel] -> Avail.AvailInfo
#if __GLASGOW_HASKELL__ >= 902
pattern AvailTC n names pieces <- Avail.AvailTC n ((\gres -> foldr (\gre (names, pieces) -> case gre of
      Avail.NormalGreName name -> (name: names, pieces)
      Avail.FieldGreName label -> (names, label:pieces)) ([], []) gres) -> (names, pieces))
#else
pattern AvailTC n names pieces <- Avail.AvailTC n names pieces
#endif

pattern AvailName :: Name -> Avail.AvailInfo
#if __GLASGOW_HASKELL__ >= 902
pattern AvailName n <- Avail.Avail (Avail.NormalGreName n)
#else
pattern AvailName n <- Avail.Avail n
#endif

pattern AvailFL :: FieldLabel -> Avail.AvailInfo
#if __GLASGOW_HASKELL__ >= 902
pattern AvailFL fl <- Avail.Avail (Avail.FieldGreName fl)
#else
-- pattern synonym that is never populated
pattern AvailFL x <- Avail.Avail ((\_ -> (True, undefined)) -> (False, x))
#endif