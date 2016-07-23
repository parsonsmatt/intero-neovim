module Lib
    ( someFunc
    , foo
    , repl
    ) where

import Data.Char (toUpper)

someFunc :: IO ()
someFunc = do
    repl
    print "asdf"
    repl

foo :: String -> Int
foo = (* bar) . length
  where
    bar = 2

repl :: IO b
repl = do
    putStr "Enter a thing:"
    x <- getLine
    putStr (fmap toUpper x)
    repl
