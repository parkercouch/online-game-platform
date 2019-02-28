module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h1, li, p, strong, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )



-- MODEL


type alias Model =
    { gamesList : List Game
    , displayGamesList : Bool
    }


type alias Game =
    { title : String
    , description : String
    }


initialModel : Model
initialModel =
    { gamesList =
        [ { title = "Platform Game", description = "Platform game example." }
        , { title = "Adventure Game", description = "Adventure game example." }
        ]
    , displayGamesList = True
    }



-- UPDATE


type Msg
    = DisplayGamesList
    | HideGamesList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DisplayGamesList ->
            ( { model | displayGamesList = True }, Cmd.none )

        HideGamesList ->
            ( { model | displayGamesList = False }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    let
        maybeGameList =
            if model.displayGamesList then
                gamesIndex model.gamesList

            else
                div [] []
    in
    div []
        [ h1 [ class "games-section" ] [ text "Games" ]
        , button [ class "button", onClick DisplayGamesList ] [ text "Display Games List" ]
        , button [ class "button", onClick HideGamesList ] [ text "Hide Games List" ]
        , maybeGameList
        ]


gamesIndex : List Game -> Html msg
gamesIndex gameTitles =
    div [ class "games-index" ] [ gamesList gameTitles ]


gamesList : List Game -> Html msg
gamesList games =
    ul [ class "games-list" ] (List.map gamesListItem games)


gamesListItem : Game -> Html msg
gamesListItem game =
    li [ class "game-item" ]
        [ strong [] [ text game.title ]
        , p [] [ text game.description ]
        ]
