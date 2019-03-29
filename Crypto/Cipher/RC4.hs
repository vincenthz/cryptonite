-- |
-- Module      : Crypto.Cipher.RC4
-- License     : BSD-style
-- Maintainer  : Vincent Hanquez <vincent@snarc.org>
-- Stability   : stable
-- Portability : Good
--
-- Simple implementation of the RC4 stream cipher.
-- http://en.wikipedia.org/wiki/RC4
--
-- Initial FFI implementation by Peter White <peter@janrain.com>
--
-- Reorganized and simplified to have an opaque context.
--
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Crypto.Cipher.RC4
    ( initialize
    , combine
    , generate
    , State
    ) where

import           Data.Word
import           Foreign.Ptr
import           Crypto.Internal.ByteArray (ScrubbedBytes, ByteArray, ByteArrayAccess)
import qualified Crypto.Internal.ByteArray as B

import           Crypto.Internal.Compat
import           Crypto.Internal.Imports

-- | The encryption state for RC4
newtype State = State ScrubbedBytes
    deriving (ByteArrayAccess,NFData)

-- | C Call for initializing the encryptor
foreign import ccall unsafe "cryptonite_rc4.h cryptonite_rc4_init"
    c_rc4_init :: Ptr Word8 -- ^ The rc4 key
               -> Word32    -- ^ The key length
               -> Ptr State -- ^ The context
               -> IO ()

foreign import ccall unsafe "cryptonite_rc4.h cryptonite_rc4_combine"
    c_rc4_combine :: Ptr State      -- ^ Pointer to the permutation
                  -> Ptr Word8      -- ^ Pointer to the clear text
                  -> Word32         -- ^ Length of the clear text
                  -> Ptr Word8      -- ^ Output buffer
                  -> IO ()

-- | RC4 context initialization.
--
-- Seed the context with an initial key. The key size needs to be
-- adequate otherwise security takes a hit.
initialize :: ByteArrayAccess key
           => key   -- ^ The key
           -> State -- ^ The RC4 context with the key mixed in
initialize key = unsafeDoIO $ do
    st <- B.alloc 264 $ \stPtr ->
        B.withByteArray key $ \keyPtr -> c_rc4_init keyPtr (fromIntegral $ B.length key) (castPtr stPtr)
    return $ State st

-- | Generate the next len bytes of the RC4 stream without combining
-- it to anything.
generate :: ByteArray ba => State -> Int -> (State, ba)
generate ctx len = combine ctx (B.zero len)

-- | RC4 xor combination of the RC4 stream with an input
combine :: ByteArray ba
        => State               -- ^ RC4 context
        -> ba                  -- ^ Input
        -> (State, ba)         -- ^ New rc4 context, and the output
combine (State prevSt) clearText = unsafeDoIO $
    B.allocRet len            $ \outptr ->
    B.withByteArray clearText $ \clearPtr -> do
        st <- B.copy prevSt $ \stPtr ->
                c_rc4_combine (castPtr stPtr) clearPtr (fromIntegral len) outptr
        return $! State st
    --return $! (State st, B.PS outfptr 0 len)
  where len = B.length clearText
