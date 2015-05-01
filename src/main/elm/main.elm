import Html exposing (..)
import Signal

import FlashCard

type alias Model = 
    { flashcard: FlashCard.Model
    }

type Action 
    = ShowFlashCard String String
    | FlashCardAction FlashCard.Action


init : Model
init = 
    { flashcard = FlashCard.init ("word", "definition")
    }

update : Action -> Model -> Model
update action model =
    case action of
        ShowFlashCard word definition -> { model | flashcard <- FlashCard.init (word, definition) }
        FlashCardAction act -> { model | flashcard <- FlashCard.update act model.flashcard }

view : Signal.Address Action -> Model -> Html
view address model = FlashCard.view (Signal.forwardTo address FlashCardAction) model.flashcard

actions : Signal.Mailbox Action
actions = Signal.mailbox (ShowFlashCard "word" "definition")

model : Signal Model
model = Signal.foldp update init actions.signal

main : Signal Html
main = Signal.map (view actions.address) model
