import Html exposing (..)
import Signal
import Task exposing (..)
import Http

import FlashCardList
import Service

type alias Model = 
    { title: String
    , flashcardList: FlashCardList.Model
    }

type Action 
    = Reset
    | Start
    | LoadList String (List (String, String))
    | FlashCardListAction FlashCardList.Action


init : Model
init = 
    { title = ""
    , flashcardList = FlashCardList.init []
    }

update : Action -> Model -> Model
update action model =
    case action of
        Reset -> init
        Start -> init
        LoadList title words ->
            { title = title
            , flashcardList = FlashCardList.init words
            }
        FlashCardListAction act -> { model | flashcardList <- FlashCardList.update act model.flashcardList }


view : Signal.Address Action -> Model -> Html
view address model = FlashCardList.view (Signal.forwardTo address FlashCardListAction) model.flashcardList

word2tuple : Service.Word -> (String, String)
word2tuple word = (word.word, word.definition)

sendLoadAction vocalist = 
    let act = LoadList vocalist.title (List.map word2tuple vocalist.words)
    in Signal.send actions.address act

port loadVocalist : Signal (Task Http.Error ())
port loadVocalist = Signal.map 
                        (\guid -> Service.getVocalist guid `andThen` sendLoadAction) 
                        (Signal.constant "1b42147b-4f6c-4e68-9d50-a6188d9e4fb3")

-- static
actions : Signal.Mailbox Action
actions = Signal.mailbox Reset

model : Signal Model
model = Signal.foldp update init actions.signal

main : Signal Html
main = Signal.map (view actions.address) model
