module ListView (Model, Action, init, initWithList, update, view, httpLoader) where

import Signal
import Html exposing (..)
import Html.Events exposing (..)
import Http exposing (Error)
import Task exposing (Task, andThen)

import Service exposing (VocalistShort)

type alias Model =
    { vocalists : Maybe (List VocalistShort)
    }

type Action
    = Reset
    | LoadList (List VocalistShort)

init : Model
init = 
    { vocalists = Nothing }

initWithList : List VocalistShort -> Model
initWithList vocalists = 
    { vocalists = Just vocalists
    }

update : Action -> Model -> Model
update action model = 
    case action of
        Reset -> model
        LoadList list -> initWithList list

view : Signal.Address Action -> Signal.Address String -> Model -> Html
view address callbackAddress model =
    case model.vocalists of
        Nothing -> 
            div [] [ text "Loading..."]
        Just list -> 
            div []
                [ ul [] (List.map (viewListItem callbackAddress) list)
                ]

viewListItem : Signal.Address String -> VocalistShort -> Html
viewListItem callbackAddress vocalist = li [onClick callbackAddress vocalist.guid] [ text vocalist.title ]

httpLoader : Model -> Signal.Address Action -> Task Http.Error ()
httpLoader model address = 
    case model.vocalists of
        Nothing -> Service.getVocalistShortlist 
                            `andThen` \list -> Signal.send address (LoadList list)
        Just _ -> Task.succeed ()
