module FlashCardList (Model, Action, init, update, view) where

import Html exposing (..)
import Html.Events exposing (..)
import Signal

import FlashCard

type alias Model = 
    { flashcards: List FlashCard.Model
    , index: Int
    }

type Action 
    = Reset
    | ShowNext
    | ShowPrev
    | FlashCardAction FlashCard.Action

at : List a -> Int -> Maybe a
at xs n = List.head ( List.drop n xs )

init : List (String, String) -> Model
init words = 
    { flashcards = List.map FlashCard.init words
    , index = 0
    }

updateCardIfCurrent : FlashCard.Model -> FlashCard.Action -> FlashCard.Model -> FlashCard.Model
updateCardIfCurrent current act model =
    if current == model
        then FlashCard.update act model
        else model

update : Action -> Model -> Model
update action model =
    case action of
        Reset -> { model | index <- 0 }
        ShowNext -> { model | index <- min (model.index + 1) ((List.length model.flashcards) - 1) }
        ShowPrev -> { model | index <- max (model.index - 1) 0 }
        FlashCardAction act -> 
            let current = (model.flashcards `at` model.index)
            in case current of
                Nothing -> model
                Just curr -> { model | flashcards <- List.map (updateCardIfCurrent curr act ) model.flashcards }

view : Signal.Address Action -> Model -> Html
view address model = 
    let current = (model.flashcards `at` model.index)
    in case current of
        Nothing -> div [] [text ("No list set yet")]
        Just flashcard -> viewFlashCard address flashcard

viewFlashCard : Signal.Address Action -> FlashCard.Model -> Html
viewFlashCard address model =
    div []
        [ FlashCard.view (Signal.forwardTo address FlashCardAction) model
        , button [ onClick address ShowPrev ] [ text " prev << " ]
        , button [ onClick address ShowNext ] [ text " >> next " ]
        ]

actions : Signal.Mailbox Action
actions = Signal.mailbox Reset

model : Signal Model
model = Signal.foldp update (init [("a", "b")]) actions.signal

main : Signal Html
main = Signal.map (view actions.address) model
