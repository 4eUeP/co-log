{- |
Copyright:  (c) 2018-2020 Kowainik
SPDX-License-Identifier: MPL-2.0
Maintainer: Kowainik <xrom.xkov@gmail.com>

Logging actions for various text types.
-}

module Colog.Actions
       ( -- * 'ByteString' actions
         logByteStringStdout
       , logByteStringStderr
       , logByteStringHandle
       , withLogByteStringFile

         -- * 'Text' actions
       , logTextStdout
       , logTextStderr
       , logTextHandle
       , withLogTextFile

         -- * 'Message' actions
         -- $msg
       , simpleMessageAction
       , richMessageAction
       , withLogMessageFile
       , withLogRichMessageFile
       ) where

import Control.Monad.IO.Class (MonadIO (..))
import Data.Semigroup ((<>))
import Data.Text.Encoding (encodeUtf8)
import System.IO (Handle, IOMode (AppendMode), stderr, withFile)

import Colog.Core.Action (LogAction (..), cmap, cmapM, (>$<))
import Colog.Core.IO (logFlush)
import Colog.Message (Message, defaultFieldMap, fmtMessage, fmtRichMessageDefault,
                      upgradeMessageAction)

import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

----------------------------------------------------------------------------
-- ByteString
----------------------------------------------------------------------------

{- | Action that prints 'BS.ByteString' to stdout.
This action does not flush the output buffer.
If buffering mode is block buffering, the effect of this action can be delayed.
-}
logByteStringStdout :: MonadIO m => LogAction m BS.ByteString
logByteStringStdout = LogAction $ liftIO . BS8.putStrLn
{-# INLINE logByteStringStdout #-}
{-# SPECIALIZE logByteStringStdout :: LogAction IO BS.ByteString #-}

{- | Action that prints 'BS.ByteString' to stderr.
This action does not flush the output buffer.
If buffering mode is block buffering, the effect of this action can be delayed.
-}
logByteStringStderr :: MonadIO m => LogAction m BS.ByteString
logByteStringStderr = logByteStringHandle stderr
{-# INLINE logByteStringStderr #-}
{-# SPECIALIZE logByteStringStderr :: LogAction IO BS.ByteString #-}

{- | Action that prints 'BS.ByteString' to 'Handle'.
This action does not flush the output buffer.
If buffering mode is block buffering, the effect of this action can be delayed.
-}
logByteStringHandle :: MonadIO m => Handle -> LogAction m BS.ByteString
logByteStringHandle handle = LogAction $ liftIO . BS8.hPutStrLn handle
{-# INLINE logByteStringHandle #-}
{-# SPECIALIZE logByteStringHandle :: Handle -> LogAction IO BS.ByteString #-}

{- | Action that prints 'BS.ByteString' to file. See
'Colog.Core.IO.withLogStringFile' for details.
-}
withLogByteStringFile :: MonadIO m => FilePath -> (LogAction m BS.ByteString -> IO r) -> IO r
withLogByteStringFile path action = withFile path AppendMode $ \handle ->
  action (logByteStringHandle handle <> logFlush handle)
{-# INLINE withLogByteStringFile #-}
{-# SPECIALIZE withLogByteStringFile :: FilePath -> (LogAction IO BS.ByteString -> IO r) -> IO r #-}

----------------------------------------------------------------------------
-- Text
----------------------------------------------------------------------------

{- | Action that prints 'T.Text' to stdout.
This action does not flush the output buffer.
If buffering mode is block buffering, the effect of this action can be delayed.
-}
logTextStdout :: MonadIO m => LogAction m T.Text
logTextStdout = LogAction $ liftIO . TIO.putStrLn
{-# INLINE logTextStdout #-}
{-# SPECIALIZE logTextStdout :: LogAction IO T.Text #-}

{- | Action that prints 'T.Text' to stderr.
This action does not flush the output buffer.
If buffering mode is block buffering, the effect of this action can be delayed.
-}
logTextStderr :: MonadIO m => LogAction m T.Text
logTextStderr = logTextHandle stderr
{-# INLINE logTextStderr #-}
{-# SPECIALIZE logTextStderr :: LogAction IO T.Text #-}

{- | Action that prints 'T.Text' to 'Handle'.
This action does not flush the output buffer.
If buffering mode is block buffering, the effect of this action can be delayed.
-}
logTextHandle :: MonadIO m => Handle -> LogAction m T.Text
logTextHandle handle = LogAction $ liftIO . TIO.hPutStrLn handle
{-# INLINE logTextHandle #-}
{-# SPECIALIZE logTextHandle :: Handle -> LogAction IO T.Text #-}

{- | Action that prints 'T.Text' to file. See
'Colog.Core.IO.withLogStringFile' for details.
-}
withLogTextFile :: MonadIO m => FilePath -> (LogAction m T.Text -> IO r) -> IO r
withLogTextFile path action = withFile path AppendMode $ \handle ->
  action (logTextHandle handle <> logFlush handle)
{-# INLINE withLogTextFile #-}
{-# SPECIALIZE withLogTextFile :: FilePath -> (LogAction IO T.Text -> IO r) -> IO r #-}

----------------------------------------------------------------------------
-- Message
----------------------------------------------------------------------------

{- $msg
Default logging actions to make the usage with 'Message's easier.
-}

{- | Action that prints 'Message' to 'stdout'. -}
simpleMessageAction :: MonadIO m => LogAction m Message
simpleMessageAction = encodeUtf8 . fmtMessage >$< logByteStringStdout
{-# INLINE simpleMessageAction #-}
{-# SPECIALIZE simpleMessageAction :: LogAction IO Message #-}

{- | Action that prints 'Message' to file. See
'Colog.Core.IO.withLogStringFile' for details.
-}
withLogMessageFile
  :: MonadIO m
  => FilePath
  -> (LogAction m Message -> IO r)
  -> IO r
withLogMessageFile path action = withFile path AppendMode $ \handle ->
  action $ cmap fmtMessage (logTextHandle handle) <> logFlush handle
{-# INLINE withLogMessageFile #-}
{-# SPECIALIZE withLogMessageFile :: FilePath -> (LogAction IO Message -> IO r) -> IO r #-}

{- | Action that constructs 'Colog.Message.RichMessage' and prints formatted
'Message' for it to 'stdout'.
-}
richMessageAction :: MonadIO m => LogAction m Message
richMessageAction = upgradeMessageAction defaultFieldMap $
    cmapM (fmap encodeUtf8 . fmtRichMessageDefault) logByteStringStdout
{-# INLINE richMessageAction #-}
{-# SPECIALIZE richMessageAction :: LogAction IO Message #-}

{- | Action that constructs 'Colog.Message.RichMessage' and prints formatted
'Message' for it to file. See 'Colog.Core.IO.withLogStringFile' for details.
-}
withLogRichMessageFile
  :: MonadIO m
  => FilePath
  -> (LogAction m Message -> IO r)
  -> IO r
withLogRichMessageFile path action = withFile path AppendMode $ \handle ->
  action . upgradeMessageAction defaultFieldMap $
    cmapM fmtRichMessageDefault (logTextHandle handle) <> logFlush handle
{-# INLINE withLogRichMessageFile #-}
{-# SPECIALIZE withLogRichMessageFile :: FilePath -> (LogAction IO Message -> IO r) -> IO r #-}
