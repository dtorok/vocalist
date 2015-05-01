module FlashCard (Model, Action, init, update, view) where

import Html exposing (..)
import Html.Events exposing (..)
import Signal

type State = WordOnly | WordAndDefinition

type alias Model = 
    { word: String
    , definition: String
    , state: State
    }

type Action = ShowDefinition | HideDefinition

init : (String, String) -> Model
init (word, definition) = 
    { word = word
    , definition = definition
    , state = WordOnly
    }

update : Action -> Model -> Model
update action model = 
    case action of
        ShowDefinition -> { model | state <- WordAndDefinition }
        HideDefinition -> { model | state <- WordOnly }

view : Signal.Address Action -> Model -> Html
view address model = 
    case model.state of
        WordOnly -> 
            div [] 
                [ div [] [ text model.word ]
                , button [ onClick address ShowDefinition ] [ text "Show the definition" ]
                ]
        WordAndDefinition ->
            div []
                [ div [] [ text model.word ]
                , div [] [ text model.definition ]
                , button [ onClick address HideDefinition ] [ text "Hide the definition" ]
                ]

viewText : String -> Html
viewText name = div [] [ text name ]
