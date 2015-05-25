import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Task exposing (Task, andThen)

import Service
import ListView
import FlashCardsView

type View 
    = Welcome
    | ListView
    | FlashCardsView

type alias Model = 
    {
        view: View,
        listViewModel: ListView.Model,
        flashCardsModel: FlashCardsView.Model
    }

type Action
    = Reset
    | ShowList
    | ShowFlashards String
    | ListViewAction ListView.Action
    | FlashCardsViewAction FlashCardsView.Action

type alias Context =
    { actions: Signal.Mailbox Action
    , callbackShowFlashcards: Signal.Mailbox String
    }

init : Model
init = 
    { view = Welcome 
    , listViewModel = ListView.init 
    , flashCardsModel = FlashCardsView.init "" }

update : Action -> Model -> Model
update action bigmodel = 
    case action of
        Reset -> bigmodel

        ShowList -> 
            { bigmodel | view <- ListView
                       , listViewModel <- ListView.init }

        ShowFlashards guid -> 
            { bigmodel | view <- FlashCardsView
                       , flashCardsModel <- FlashCardsView.init guid }

        ListViewAction act -> 
            { bigmodel | listViewModel <- ListView.update act bigmodel.listViewModel }

        FlashCardsViewAction act -> 
            { bigmodel | flashCardsModel <- FlashCardsView.update act bigmodel.flashCardsModel }

view : Context -> Model -> Html
view context model = 
    div [ class "content" ] 
        [ node "link" [ rel "stylesheet", href "stylesheets/iphone.css" ] []
        , node "link" [ rel "stylesheet", href "stylesheets/main.css" ] []
        , viewContent context model ]

viewContent : Context -> Model -> Html
viewContent context model =
    case model.view of
        Welcome -> div [] 
                       [ h1 [] [text "Welcome!"]
                       , ul [] 
                            [ li [ onClick context.actions.address ShowList, class "button1" ] [ text "start" ]
                            ]
                       ]

        ListView -> 
            ListView.view 
                (Signal.forwardTo context.actions.address ListViewAction)
                context.callbackShowFlashcards.address
                model.listViewModel

        FlashCardsView -> 
            FlashCardsView.view 
                (Signal.forwardTo context.actions.address FlashCardsViewAction) 
                model.flashCardsModel

-- static
context : Context
context = 
    { actions = Signal.mailbox Reset
    , callbackShowFlashcards = Signal.mailbox "" }

model : Signal Model
model = 
    Signal.foldp update init <|
        Signal.merge 
            context.actions.signal
            (Signal.map ShowFlashards context.callbackShowFlashcards.signal)
    

httpLoaderBroadcast : Signal.Address Action -> Model -> Task Http.Error ()
httpLoaderBroadcast address bigmodel = 
    case bigmodel.view of
        Welcome -> Task.succeed ()

        ListView -> ListView.httpLoader 
                                bigmodel.listViewModel 
                                (Signal.forwardTo address ListViewAction)

        FlashCardsView -> FlashCardsView.httpLoader 
                                bigmodel.flashCardsModel 
                                (Signal.forwardTo address FlashCardsViewAction)

port httpLoader : Signal (Task Http.Error ())
port httpLoader = Signal.map (httpLoaderBroadcast context.actions.address) model

main : Signal Html
main = Signal.map (view context) model
