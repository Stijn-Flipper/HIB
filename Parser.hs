{--
 - Parser.hs
 - Functional parser for Battleship, based upon the description on Graham
 - Hutton's 'Programming in Haskell', Cambridge University Press, 2007.
 -
 - Copyright (C) 2014 Stijn Wouters
 -
 - This program is free software: you can redistribute it and/or modify
 - it under the terms of the GNU General Public License as published by
 - the Free Software Foundation, either version 3 of the License, or
 - (at your option) any later version.
 -
 - This program is distributed in the hope that it will be useful,
 - but WITHOUT ANY WARRANTY; without even the implied warranty of
 - MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 - GNU General Public License for more details.
 -
 - You should have received a copy of the GNU General Public License
 - along with this program.  If not, see <http://www.gnu.org/licenses/>.
 -
 - Last modified: 08 April 2014.
 - By: Stijn Wouters.
 -}
module Parser where

import Assets
import Data.Char (isSpace, isDigit)

{--
 - The implementation of the parser is slightly different from the parser
 - described on Graham Hutton's book, since this won't work anymore on the
 - modern Haskell version. Graham Hutton has already published an updated
 - version of his Parser Library, which can be found at
 - http://www.cs.nott.ac.uk/~gmh/bib.html#pearl
 -
 - I've based upon this library to implement a parser specific for the
 - Battleship game.
 -}

-- The parser type
newtype Parser a    =   Parser ( String -> [(a,String)] )

instance Monad Parser where
    return v    =   Parser (\input -> [(v,input)])
    p >>= f     =   Parser (\input -> case parse p input of
                                []          -> []
                                [(v,out)]   -> parse (f v) out)

-- The three basic parsers
parse               ::  Parser a -> String -> [(a,String)]
parse (Parser p)    =   p
{--
 - Behavior:
 -
 -      > parse (return 1) "abc"
 -      [(1, "abc")]
 -}

item    ::  Parser Char
item    =   Parser (\input -> case input of
                        ""      -> []
                        (x:xs)  -> [(x,xs)])
{--
 - Behavior:
 -
 -      > parse item "abc"
 -      [('a', "bc")]
 -      > parse item ""
 -      []
 -}

failure ::  Parser a
failure =   Parser (\input -> [])
{--
 - Behavior:
 -
 -      > parse failure "abc"
 -      []
 -}

-- Check whether an item satisfy to a condition
satisfy         ::  (Char -> Bool) -> Parser Char
satisfy check   =   do
                        c <- item;
                        if check c then return c else failure;

-- Define choice operator
(+++)   ::  Parser a -> Parser a -> Parser a
p +++ q =   Parser (\input -> case parse p input of
                        []          -> parse q input
                        [(v,out)]   -> [(v,out)])

-- Check for zero, one, or more occurences satisfying a given condition ('star'
-- comes from the UNIX regex * operator, which has the same meaning).
star    ::  Parser a -> Parser [a]
star p  =   plus p +++ return []

-- Check for one or more occurences satisfying a given condition ('plus' comes
-- from the UNIX regex + operator, which has the same meaning).
plus    ::  Parser a -> Parser [a]
plus p  =   do
                x   <- p;
                xs  <- star p;
                return (x:xs);

-- Spacing parser (for skipping spaces)
space   ::  Parser ()
space   =   do
                star (satisfy isSpace);
                return ();

-- Integer parser
integer ::  Parser Integer
integer =   do
                xs <- plus (satisfy isDigit);
                return (read xs);   -- implicitly convert to Integer

-- Token parser
token   ::  Parser a -> Parser a
token p =   do
                space;              -- space before token
                v <- p;
                space;              -- space after token
                return v;

-- Symbol parser
symbol      ::  Char -> Parser Char
symbol s    =   token (satisfy (== s))

-- Point parser
point   ::  Parser Point
point   =   do
                symbol '(';
                x <- integer;
                symbol ',';
                y <- integer;
                symbol ')';
                return (x, y);

-- Points parser (at least one points must be given)
points  ::  Parser [Point]
points  =   do
                p       <- point;
                ps      <- star ( do symbol ';'; point; );
                return (p:ps);
