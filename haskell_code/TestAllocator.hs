-- |
--  Summary: An automated test module for Allocator.hs. Runs a series of tests
--           and creates a pass/fail result report with a summary count.
--
--  Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
--  Date: April 9, 2026

module TestAllocator where

import Allocator
import Variable ()
import InterferenceGraph
import Control.Exception (try, SomeException)  -- for error handling in tests

