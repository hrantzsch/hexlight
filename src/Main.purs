module Main where

import Prelude hiding (div)

import CSS (backgroundColor, color, display, em, height, inlineBlock, margin, marginLeft, pct, px, width)
import CSS.Color (black, fromHexString, luminance, white)
import CSS.TextAlign (center, textAlign)
import Control.Monad.Eff (Eff)
import DOM (DOM)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String.Regex (match, regex)
import Data.String.Regex.Flags (global)
import Data.Traversable (for_, sequence, traverse)
import Pux (EffModel, CoreEffects, start)
import Pux.DOM.Events (DOMEvent, onChange, targetValue)
import Pux.DOM.HTML (HTML)
import Pux.DOM.HTML.Attributes (style)
import Pux.Renderer.React (renderToDOM)
import Text.Smolder.HTML (div, h2, textarea, span)
import Text.Smolder.Markup (text, (!), (#!))

data Event = InputChange DOMEvent

type State = { input :: String }

matchInput :: String -> Maybe (Array (Maybe String))
matchInput input = case regex "#[0-9a-fA-F]{6}" global of
    Right rx -> match rx input
    Left _ -> Nothing

showColors :: Array String -> HTML Event
showColors colors =
    div ! style do width (80.0 # pct)
        $ for_ colors \c -> do
            case fromHexString c of
                Nothing -> text "error"
                Just col -> do
                    span ! style do display inlineBlock
                                    margin  (4.0 # px) (4.0 # px) (4.0 # px) (4.0 # px)
                                    textAlign center
                                    width (7.0 # em)
                                    backgroundColor col
                                    color (if luminance col > 0.179 then black else white)
                         $ text c

init :: State
init = { input: "" }

foldp :: Event -> State -> EffModel State Event (dom :: DOM)
foldp (InputChange ev) s =
    { state: s { input = targetValue ev }
    , effects: []
    }

view :: State -> HTML Event
view state =
    div ! style do marginLeft (5.0 # pct)
        $ do
        h2 $ text "paste text and code here"
        div do
            textarea ! style do
                               width (80.0 # pct)
                               height (6.0 # em)
                     #! onChange InputChange
                     $ text ""
            case (traverse join $ sequence (matchInput state.input)) of
                Nothing -> div $ span $ text "no colors found"
                Just colors -> do
                    showColors colors

main :: Eff (CoreEffects (dom :: DOM)) Unit
main = do
    app <- start { initialState: init
                 , view
                 , foldp
                 , inputs: []
                 }
    renderToDOM "#app" app.markup app.input
