module FlashCardsView (Model, Action, init, update, view, httpLoader) where

import Html exposing (..)
import Html.Events exposing (..)
import Http exposing (Error)
import Signal
import Service exposing (Vocalist, Word)
import Task exposing (Task, andThen)

import FlashCard

type alias Model = 
    { guid: String
    , title: String
    , flashcards: List FlashCard.Model
    , index: Int
    }

type Action 
    = Reset
    | LoadList Vocalist
    | ShowNext
    | ShowPrev
    | FlashCardAction FlashCard.Action

at : List a -> Int -> Maybe a
at xs n = List.head ( List.drop n xs )

init : String -> Model
init guid = 
    { guid = guid
    , title = ""
    , flashcards = []
    , index = -1 }

initWithList : List (String, String) -> Model
initWithList words = 
    { guid = ""
    , title = ""
    , flashcards = List.map FlashCard.init words
    , index = 0 }

initWithVocalist : Vocalist -> Model
initWithVocalist vocalist = 
    { guid = vocalist.guid
    , title = vocalist.title
    , flashcards = List.map word2flashcard vocalist.words
    , index = 0 }

word2flashcard : Word -> FlashCard.Model
word2flashcard word = FlashCard.init (word.word, word.definition)

updateCardIfCurrent : FlashCard.Model -> FlashCard.Action -> FlashCard.Model -> FlashCard.Model
updateCardIfCurrent current act model =
    if current == model
        then FlashCard.update act model
        else model

update : Action -> Model -> Model
update action model =
    case action of
        Reset -> { model | index <- 0 }
        LoadList vocalist -> initWithVocalist vocalist
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
        Nothing -> 
            div [] [text ("Loading...")]

        Just flashcard -> 
            div [] [ h1 [] [ text model.title ]
                   , viewFlashCard address flashcard ]

viewFlashCard : Signal.Address Action -> FlashCard.Model -> Html
viewFlashCard address model =
    div []
        [ FlashCard.view (Signal.forwardTo address FlashCardAction) model
        , button [ onClick address ShowPrev ] [ text " prev << " ]
        , button [ onClick address ShowNext ] [ text " >> next " ]
        ]

httpLoader : Model -> Signal.Address Action -> Task Http.Error ()
httpLoader model address = 
    case model.flashcards of
        [] -> Service.getVocalist model.guid
                            `andThen` \list -> Signal.send address (LoadList list)
        _ -> Task.succeed ()
    --case model.guid of
    --    "" -> Task.succeed ()
    --    guid -> Service.getVocalist guid
    --                        `andThen` \list -> Signal.send address (LoadList list)

--actions : Signal.Mailbox Action
--actions = Signal.mailbox Reset

--model : Signal Model
--model = Signal.foldp update (initWithList [("a", "b")]) actions.signal

--main : Signal Html
--main = Signal.map (view actions.address) model
