module WelcomeView (view) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


view : Signal.Address () -> Html
view address = 
    div [] 
        [ h1 [] [text "Welcome!"]
        , ul [] 
             [ li [ onClick address (), class "button1" ] [ text "Start" ]
             ]
        ]
