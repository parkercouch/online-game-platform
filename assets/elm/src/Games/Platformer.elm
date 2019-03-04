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


type Direction
    = Left
    | Right


type GameState
    = StartScreen
    | Playing
    | Success
    | GameOver


type alias Model =
    { characterDirection : Direction
    , characterPositionX : Int
    , characterPositionY : Int
    , gameState : GameState
    , itemPositionX : Int
    , itemPositionY : Int
    , itemsCollected : Int
    , playerScore : Int
    , timeRemaining : Int
    , gameplays : List Gameplay
    }


initialModel : Model
initialModel =
    { characterDirection = Right
    , characterPositionX = 50
    , characterPositionY = 300
    , gameState = StartScreen
    , itemPositionX = 500
    , itemPositionY = 300
    , itemsCollected = 0
    , playerScore = 0
    , timeRemaining = 10
    , gameplays = []
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )



-- UPDATE


type Msg
    = BroadcastScore Encode.Value
    | CountdownTimer Time.Posix
    | GameLoop Float
    | IncrementScore Int
    | KeyDown String
    | ReceiveScoreFromPhoenix Encode.Value
    | SetNewItemPositionX Int
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        BroadcastScore value ->
            ( model, broadcastScore value )

        CountdownTimer time ->
            if model.gameState == Playing && model.timeRemaining > 0 then
                ( { model | timeRemaining = model.timeRemaining - 1 }, Cmd.none )

            else
                ( model, Cmd.none )

        GameLoop time ->
            if characterFoundItem model then
                ( { model
                    | itemsCollected = model.itemsCollected + 1
                    , playerScore = model.playerScore + 100
                  }
                , Random.generate SetNewItemPositionX (Random.int 50 500)
                )

            else if model.itemsCollected >= 10 then
                ( { model | gameState = Success }, Cmd.none )

            else if model.itemsCollected < 10 && model.timeRemaining == 0 then
                ( { model | gameState = GameOver }, Cmd.none )

            else
                ( model, Cmd.none )

        IncrementScore value ->
            ( { model | playerScore = model.playerScore + value }, Cmd.none )

        KeyDown key ->
            case key of
                "ArrowLeft" ->
                    if model.gameState == Playing then
                        ( { model
                            | characterDirection = Left
                            , characterPositionX = model.characterPositionX - 15
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                "ArrowRight" ->
                    if model.gameState == Playing then
                        ( { model
                            | characterDirection = Right
                            , characterPositionX = model.characterPositionX + 15
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                " " ->
                    if model.gameState /= Playing then
                        ( { model
                            | characterDirection = Right
                            , characterPositionX = 50
                            , itemsCollected = 0
                            , gameState = Playing
                            , playerScore = 0
                            , timeRemaining = 10
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ReceiveScoreFromPhoenix incomingJsonData ->
            case Decode.decodeValue decodeGameplay incomingJsonData of
                Ok gameplay ->
                    Debug.log "Successfully received score data."
                        ( { model | gameplays = gameplay :: model.gameplays }, Cmd.none )

                Err message ->
                    Debug.log ("Error receiving score data: " ++ Debug.toString message)
                        ( model, Cmd.none )

        SetNewItemPositionX newPositionX ->
            ( { model | itemPositionX = newPositionX }, Cmd.none )


characterFoundItem : Model -> Bool
characterFoundItem model =
    let
        approximateItemLowerBound =
            model.itemPositionX - 35

        approximateItemUpperBound =
            model.itemPositionX

        approximateItemRange =
            List.range approximateItemLowerBound approximateItemUpperBound
    in
    List.member model.characterPositionX approximateItemRange



-- PORTS


port broadcastScore : Encode.Value -> Cmd msg


port receiveScoreFromPhoenix : (Encode.Value -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onKeyDown (Decode.map KeyDown keyDecoder)
        , Browser.Events.onAnimationFrameDelta GameLoop
        , receiveScoreFromPhoenix ReceiveScoreFromPhoenix
        , Time.every 1000 CountdownTimer
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div [ Html.Attributes.class "container" ]
        [ viewGame model
        , p [] [ Html.text (String.fromInt model.playerScore) ]
        , button [ onClick (IncrementScore 5) ] [ Html.text "+5" ]
        , viewBroadcastScoreButton model
        , viewGameplaysIndex model
        ]


viewGame : Model -> Svg Msg
viewGame model =
    svg [ version "1.1", width "600", height "400" ]
        (viewGameState model)


viewGameState : Model -> List (Svg Msg)
viewGameState model =
    case model.gameState of
        StartScreen ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewStartScreenText
            ]

        Playing ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewGameScore model
            , viewItemsCollected model
            , viewGameTime model
            ]

        Success ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewSuccessScreenText
            ]

        GameOver ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewGameOverScreenText
            ]


viewGameWindow : Svg Msg
viewGameWindow =
    rect
        [ width "600"
        , height "400"
        , fill "none"
        , stroke "black"
        ]
        []


viewGameSky : Svg Msg
viewGameSky =
    rect
        [ x "0"
        , y "0"
        , width "600"
        , height "300"
        , fill "#4b7cfb"
        ]
        []


viewGameGround : Svg Msg
viewGameGround =
    rect
        [ x "0"
        , y "300"
        , width "600"
        , height "100"
        , fill "green"
        ]
        []


viewCharacter : Model -> Svg Msg
viewCharacter model =
    let
        characterImage =
            case model.characterDirection of
                Left ->
                    "/images/character-left.gif"

                Right ->
                    "/images/character-right.gif"
    in
    image
        [ xlinkHref characterImage
        , x (String.fromInt model.characterPositionX)
        , y (String.fromInt model.characterPositionY)
        , width "50"
        , height "50"
        ]
        []


viewItem : Model -> Svg Msg
viewItem model =
    image
        [ xlinkHref "/images/coin.svg"
        , x (String.fromInt model.itemPositionX)
        , y (String.fromInt model.itemPositionY)
        , width "20"
        , height "20"
        ]
        []


viewItemsCollected : Model -> Svg Msg
viewItemsCollected model =
    let
        currentItemCount =
            model.itemsCollected
                |> String.fromInt
                |> String.padLeft 3 '0'
    in
    Svg.svg []
        [ image
            [ xlinkHref "/images/coin.svg"
            , x "275"
            , y "18"
            , width "15"
            , height "15"
            ]
            []
        , viewGameText 300 30 ("x " ++ currentItemCount)
        ]


viewGameScore : Model -> Svg Msg
viewGameScore model =
    let
        currentScore =
            model.playerScore
                |> String.fromInt
                |> String.padLeft 5 '0'
    in
    Svg.svg []
        [ viewGameText 25 25 "SCORE"
        , viewGameText 25 40 currentScore
        ]


viewGameText : Int -> Int -> String -> Svg Msg
viewGameText positionX positionY str =
    Svg.text_
        [ x (String.fromInt positionX)
        , y (String.fromInt positionY)
        , fontFamily "Courier"
        , fontSize "16"
        ]
        [ Svg.text str ]


viewGameTime : Model -> Svg Msg
viewGameTime model =
    let
        currentTime =
            model.timeRemaining
                |> String.fromInt
                |> String.padLeft 4 '0'
    in
    Svg.svg []
        [ viewGameText 525 25 "TIME"
        , viewGameText 525 40 currentTime
        ]


viewStartScreenText : Svg Msg
viewStartScreenText =
    Svg.svg []
        [ viewGameText 140 160 "Collect ten coins in ten seconds!"
        , viewGameText 140 180 "Press the SPACE BAR key to start."
        ]


viewSuccessScreenText : Svg Msg
viewSuccessScreenText =
    Svg.svg []
        [ viewGameText 260 160 "Success!"
        , viewGameText 140 180 "Press the SPACE BAR to restart."
        ]


viewGameOverScreenText : Svg Msg
viewGameOverScreenText =
    Svg.svg []
        [ viewGameText 260 160 "Game Over"
        , viewGameText 140 180 "Press the SPACE BAR to restart."
        ]


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



---- DECODERS ----


decodeGameplay : Decode.Decoder Gameplay
decodeGameplay =
    Decode.map Gameplay
        (Decode.field "player_score" Decode.int)


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string
