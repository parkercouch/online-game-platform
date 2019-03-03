port module Games.Siam exposing (Board, Bullpen, Coord, Direction(..), Model, Msg(..), Piece(..), Player(..), boardSize, coordToIndex, indexToCoord, init, main, update, view)

import Browser
import Browser.Events
import Html exposing (Html, button, div, h1, h2, img, p, text)
import Html.Attributes exposing (classList, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Tachyons exposing (classes)
import Tachyons.Classes as T



---- MODEL ----


type alias Model =
    { currentPlayer : Player
    , targeted : Maybe Int
    , selected : Maybe Int
    , board : Board
    , winner : Maybe Player
    , clicked : Int
    , stateTest : State
    }


type alias State =
    { turn : String
    }


type alias Board =
    List Piece


type Piece
    = Empty
    | Mountain
    | Elephant Direction
    | Rhino Direction


type Direction
    = Up
    | Down
    | Left
    | Right


type alias Coord =
    ( Int, Int )


type Player
    = ElephantPlayer
    | RhinoPlayer


type alias Bullpen =
    { elephant : Int
    , rhino : Int
    }


boardSize : Int
boardSize =
    5


coordToIndex : Coord -> Int
coordToIndex ( x, y ) =
    (x - 1) * boardSize + (y - 1)


indexToCoord : Int -> Coord
indexToCoord index =
    let
        x =
            index // 5 + 1

        y =
            modBy 5 index + 1
    in
    ( x, y )


init : ( Model, Cmd Msg )
init =
    ( { currentPlayer = ElephantPlayer
      , targeted = Nothing
      , selected = Nothing
      , board = startingBoard
      , winner = Nothing
      , clicked = -1
      , stateTest = { turn = "None" }
      }
    , Cmd.none
    )


startingBoard : Board
startingBoard =
    [ Elephant Left
    , Empty
    , Empty
    , Empty
    , Empty
    , Elephant Up
    , Empty
    , Mountain
    , Empty
    , Rhino Down
    , Empty
    , Empty
    , Mountain
    , Empty
    , Empty
    , Empty
    , Empty
    , Mountain
    , Empty
    , Empty
    , Empty
    , Empty
    , Empty
    , Empty
    , Empty
    ]



---- PORTS ----


port requestState : String -> Cmd msg


port receiveState : (Encode.Value -> msg) -> Sub msg



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveState ReceiveState
        ]



---- UPDATE ----


type Msg
    = NoOp
    | Click Int
    | ReceiveState Encode.Value
    | RequestState


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Click index ->
            ( { model | selected = Just index }, Cmd.none )

        RequestState ->
            ( model, requestState "requesting state" )

        ReceiveState incomingJsonData ->
            case Decode.decodeValue decodeState incomingJsonData of
                Ok turn ->
                    Debug.log "Successfully received state data."
                        ( { model | stateTest = turn }, Cmd.none )

                Err message ->
                    Debug.log ("Error receiving state data: " ++ Debug.toString message)
                        ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 [ classes [ T.red ] ] [ text "Siam" ]
        , viewBoard model
        , h2 [] [ text (String.fromInt model.clicked) ]
        , button [ onClick RequestState ] [ text "Get State" ]
        , h2 [] [ text "Current Player:" ]
        , p [] [ text model.stateTest.turn ]
        ]


viewBoard : Model -> Html Msg
viewBoard model =
    let
        toDivModified =
            toDiv model.selected model.targeted

        pieces =
            model.board
                |> List.map pieceToGraphic
                |> List.indexedMap toDivModified
    in
    div [ classes [ T.center, T.ba, T.h5, T.w5, T.flex, T.flex_column_reverse, T.flex_wrap ] ] pieces



-- toDiv : Int -> String -> Html Msg
-- toDiv index s =


toDiv : Maybe Int -> Maybe Int -> Int -> String -> Html Msg
toDiv maybeSelected maybeTargeted index s =
    let
        selected =
            Maybe.withDefault -1 maybeSelected == index

        targeted =
            Maybe.withDefault -1 maybeTargeted == index
    in
    div
        [ classes
            [ T.dib
            , T.ba
            , "h_s"
            , "w_s"
            , T.ma0
            , T.pa0
            , T.flex
            , T.justify_center
            , T.items_center
            ]
        , onClick (Click index)
        , classList [ ( T.bg_purple, selected ), ( T.bg_green, targeted ) ]
        ]
        [ h1 [ classes [ T.f4, T.ma0, T.pa0, T.pointer ], onClick (Click index) ] [ text s ]
        ]


pieceToGraphic : Piece -> String
pieceToGraphic piece =
    case piece of
        Empty ->
            "  "

        Mountain ->
            "⛰️"

        Elephant direction ->
            "🐘" ++ directionToGraphic direction

        Rhino direction ->
            "\u{1F98F}" ++ directionToGraphic direction


directionToGraphic : Direction -> String
directionToGraphic direction =
    case direction of
        Up ->
            "⬆️"

        Down ->
            "⬇️"

        Left ->
            "⬅️"

        Right ->
            "➡️"



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }


decodeState : Decode.Decoder State
decodeState =
    Decode.map State
        (Decode.field "turn" Decode.string)
