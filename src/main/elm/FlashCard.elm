module FlashCard (Model, Action, init, update, view) where

import Html exposing (..)
import Html.Events exposing (..)
import Signal

type State = ShowOnlyOne | ShowBoth
type Method = WordFirst | DefinitionFirst

type alias Model = 
    { word: String
    , definition: String
    , state: State
    , method: Method
    }

type Action = ShowOther | HideOther | ChangeOrder

init : (String, String) -> Model
init (word, definition) = 
    { word = word
    , definition = definition
    , state = ShowOnlyOne
    , method = DefinitionFirst
    }

update : Action -> Model -> Model
update action model = 
    case action of
        ShowOther -> { model | state <- ShowBoth }
        HideOther -> { model | state <- ShowOnlyOne }
        ChangeOrder -> { model | method <- if model.method == DefinitionFirst then WordFirst else DefinitionFirst }

view : Signal.Address Action -> Model -> Html
view address model = 
    case model.method of
        WordFirst -> viewCard address model model.word model.definition
        DefinitionFirst -> viewCard address model model.definition model.word

viewCard : Signal.Address Action -> Model -> String -> String -> Html
viewCard address model a b = 
    case model.state of
        ShowOnlyOne -> 
            div [] 
                [ div [] [ h3 [] [ text a ]]
                , button [ onClick address ShowOther ] [ text "Show the solution" ]
                , button [ onClick address ChangeOrder ] [ text "Practice the other one" ]
                ]
        ShowBoth ->
            div []
                [ div [] [ h3 [] [ text a ]]
                , div [] [ h3 [] [ text b ]]
                , button [ onClick address HideOther ] [ text "Hide the solution" ]
                , button [ onClick address ChangeOrder ] [ text "Practice the other one" ]
                ]

viewText : String -> Html
viewText name = div [] [ text name ]
