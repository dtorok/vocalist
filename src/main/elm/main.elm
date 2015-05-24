import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Task exposing (Task, andThen)

import Service
import ListView
import FlashCardListView

type View 
    = Welcome
    | ListView ListView.Model 
    | FlashCardListView FlashCardListView.Model

type alias Model = 
    {
        view: View
    }

type Action
    = Reset
    | ShowList
    | ShowFlashards String
    | ListViewAction ListView.Action
    | FlashCardViewAction FlashCardListView.Action
-- (List Service.VocalistShort)

type alias Context =
    { actions: Signal.Mailbox Action
    , callbackListItemSelected: Signal.Mailbox String
    }

init : Model
init = 
    { view = Welcome }

update : Action -> Model -> Model
update action bigmodel = 
    case action of
        Reset -> bigmodel
        --ShowList list -> { model | view <- ListView (ListView.initWithList list) }
        ShowList -> { bigmodel | view <- ListView (ListView.init) }
        ShowFlashards guid -> {bigmodel | view <- FlashCardListView (FlashCardListView.init guid) }
        ListViewAction act -> 
            case bigmodel.view of
                ListView model -> { bigmodel | view <- ListView <| ListView.update act model }
                otherwise -> bigmodel
        FlashCardViewAction act -> 
            case bigmodel.view of
                FlashCardListView model -> { bigmodel | view <- FlashCardListView <| FlashCardListView.update act model }
                otherwise -> bigmodel

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
        ListView model -> 
            ListView.view 
                (Signal.forwardTo context.actions.address ListViewAction)
                context.callbackListItemSelected.address
                model
        FlashCardListView model -> 
            FlashCardListView.view 
                (Signal.forwardTo context.actions.address FlashCardViewAction) 
                model

-- static
context : Context
context = 
    { actions = Signal.mailbox Reset
    , callbackListItemSelected = Signal.mailbox ""
    }

model : Signal Model
model = Signal.foldp update init (
        Signal.merge 
        context.actions.signal
        (Signal.map ShowFlashards context.callbackListItemSelected.signal)
    )

httpLoaderBroadcast : Signal.Address Action -> Model -> Task Http.Error ()
httpLoaderBroadcast address bigmodel = 
    case bigmodel.view of
        Welcome -> Task.succeed ()
        ListView model -> ListView.httpLoader model (Signal.forwardTo address ListViewAction)
        FlashCardListView model -> FlashCardListView.httpLoader model (Signal.forwardTo address FlashCardViewAction)

port httpLoader : Signal (Task Http.Error ())
port httpLoader = Signal.map (httpLoaderBroadcast context.actions.address) model

--port loadShortList : Task Http.Error ()
--port loadShortList = Service.getVocalistShortlist 
--                        `andThen` \list -> Signal.send actions.address (ShowList list)

main : Signal Html
main = Signal.map (view context) model
