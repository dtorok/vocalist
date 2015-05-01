import Html exposing (..)
import Signal

import FlashCardList

type alias Model = 
    { flashcardList: FlashCardList.Model
    }

type Action 
    = Reset
    | FlashCardListAction FlashCardList.Action


init : Model
init = 
    { flashcardList = FlashCardList.init [("1", "11"), ("2", "22"), ("3", "33")]
    }

update : Action -> Model -> Model
update action model =
    case action of
        Reset -> init
        FlashCardListAction act -> { model | flashcardList <- FlashCardList.update act model.flashcardList }

view : Signal.Address Action -> Model -> Html
view address model = FlashCardList.view (Signal.forwardTo address FlashCardListAction) model.flashcardList


-- static
actions : Signal.Mailbox Action
actions = Signal.mailbox Reset

model : Signal Model
model = Signal.foldp update init actions.signal

main : Signal Html
main = Signal.map (view actions.address) model
