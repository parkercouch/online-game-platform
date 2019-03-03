port module Games.Platformer exposing (main)

import Browser
import Browser.Events
import Html exposing (Html, a, button, div, h1, h2, h3, img, li, p, strong, text, ul)
import Html.Attributes exposing (class, href, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Time



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Gameplay =
    { playerScore : Int
    }


type alias Model =
    { playerScore : Int
    , gameplays : List Gameplay
    }


initialModel : Model
initialModel =
    { playerScore = 0
    , gameplays = []
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )



-- UPDATE


type Msg
    = NoOp
    | BroadcastScore Encode.Value
    | IncrementScore Int
    | ReceiveScoreFromPhoenix Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        BroadcastScore value ->
            ( model, broadcastScore value )

        IncrementScore value ->
            ( { model | playerScore = model.playerScore + value }, Cmd.none )

        ReceiveScoreFromPhoenix incomingJsonData ->
            case Decode.decodeValue decodeGameplay incomingJsonData of
                Ok gameplay ->
                    Debug.log "Successfully received score data."
                        ( { model | gameplays = gameplay :: model.gameplays }, Cmd.none )

                Err message ->
                    Debug.log ("Error receiving score data: " ++ Debug.toString message)
                        ( model, Cmd.none )



-- PORTS


port broadcastScore : Encode.Value -> Cmd msg


port receiveScoreFromPhoenix : (Encode.Value -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveScoreFromPhoenix ReceiveScoreFromPhoenix
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div [ Html.Attributes.class "container" ]
        [ viewGame
        , p [] [ Html.text (String.fromInt model.playerScore) ]
        , button [ onClick (IncrementScore 5) ] [ Html.text "+5" ]
        , viewBroadcastScoreButton model
        , viewGameplaysIndex model
        ]


viewGame : Svg Msg
viewGame =
    svg [ version "1.1", width "600", height "400" ]
        [ viewGameWindow ]


viewGameWindow : Svg Msg
viewGameWindow =
    rect
        [ width "600"
        , height "400"
        , fill "none"
        , stroke "black"
        ]
        []


viewBroadcastScoreButton : Model -> Html Msg
viewBroadcastScoreButton model =
    let
        broadcastEvent =
            model.playerScore
                |> Encode.int
                |> BroadcastScore
                |> onClick
    in
    button
        [ broadcastEvent
        , Html.Attributes.class "button"
        ]
        [ Html.text "Broadcast Score Over Socket" ]


viewGameplaysIndex : Model -> Html Msg
viewGameplaysIndex model =
    if List.isEmpty model.gameplays then
        div [] []

    else
        div [ Html.Attributes.class "gameplays-index container" ]
            [ h2 [] [ Html.text "Player Scores" ]
            , viewGameplaysList model.gameplays
            ]


viewGameplaysList : List Gameplay -> Html Msg
viewGameplaysList gameplays =
    ul [ Html.Attributes.class "gameplays-list" ]
        (List.map viewGameplayItem gameplays)


viewGameplayItem : Gameplay -> Html Msg
viewGameplayItem gameplay =
    li [ Html.Attributes.class "gameplay-item" ]
        [ Html.text ("Player Score: " ++ String.fromInt gameplay.playerScore) ]


decodeGameplay : Decode.Decoder Gameplay
decodeGameplay =
    Decode.map Gameplay
        (Decode.field "player_score" Decode.int)
