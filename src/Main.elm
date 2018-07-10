module Main exposing (..)

import Html exposing (Html, text, div, h1, img, figure, figcaption, ul, li, a, button)
import Html.Attributes exposing (src, class, href, classList)
import Html.Events exposing (onClick)
import Api exposing (Record, getRecords)
import Http
import List.Extra
import Random
import Random.Int
import Random.List
import Delay
import Time
import Debug


---- MODEL ----


type alias Model =
    { list : List Record
    , candidates : List Record
    , guess : Guess
    , endpoint : String
    , seed : Random.Seed
    }


type Guess
    = None
    | Correct
    | Wrong


init : ( Model, Cmd Msg )
init =
    let
        model =
            { list = []
            , candidates = []
            , guess = None
            , endpoint = "people"
            , seed = Random.initialSeed 1
            }
    in
        ( model, Cmd.batch [ loadRecords model.endpoint, generateSeed ] )


firstRecord : Model -> List Record
firstRecord model =
    List.take 1 model.list


buttonClass : Model -> Record -> String
buttonClass model current =
    if firstRecord model == [ current ] then
        case model.guess of
            None ->
                ""

            Correct ->
                "btn-success"

            Wrong ->
                "btn-error"
    else
        ""



---- UPDATE ----


type Msg
    = RecordsRecieved (Result Http.Error (List Record))
    | FetchRecords String
    | MakeGuess Record
    | NewSeed Int
    | MarkGuess


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MakeGuess record ->
            let
                ( newModel, timeout ) =
                    markGuess record model
            in
                ( newModel, Delay.after timeout Time.millisecond MarkGuess )

        MarkGuess ->
            case model.guess of
                Correct ->
                    nextGuess model

                _ ->
                    ( { model | guess = None }, Cmd.none )

        RecordsRecieved (Ok list) ->
            let
                ( shuffled, nextSeed ) =
                    shuffle model.seed (List.take 5 list)
            in
                nextGuess { model | list = shuffled }

        RecordsRecieved (Err err) ->
            Debug.crash "Error:" err

        FetchRecords endpoint ->
            ( { model | endpoint = endpoint }, loadRecords endpoint )

        NewSeed newSeed ->
            ( { model | seed = Random.initialSeed newSeed }, Cmd.none )


generateSeed : Cmd Msg
generateSeed =
    Random.generate NewSeed Random.Int.anyInt


shuffle : Random.Seed -> List Record -> ( List Record, Random.Seed )
shuffle seed list =
    Random.step (Random.List.shuffle list) seed


markGuess : Record -> Model -> ( Model, Float )
markGuess record model =
    if firstRecord model == [ record ] then
        ( { model | guess = Correct }, 500 )
    else
        ( { model | guess = Wrong }, 1000 )


nextGuess : Model -> ( Model, Cmd Msg )
nextGuess model =
    let
        newList =
            case model.guess of
                Correct ->
                    if List.length model.list > 2 then
                        List.Extra.removeAt 0 model.list
                    else
                        []

                _ ->
                    model.list

        ( first, rest ) =
            List.Extra.splitAt 1 newList

        ( candidates, nextSeed ) =
            rest |> List.take 2 |> List.append first |> shuffle model.seed
    in
        ( { model | list = newList, candidates = candidates, seed = nextSeed, guess = None }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        children =
            if (List.isEmpty model.list) then
                [ viewRestart model.endpoint ]
            else
                [ viewStatusBar model.list
                , viewGuess model
                ]
    in
        div [] (viewNavBar model.endpoint :: children)


viewRestart : String -> Html Msg
viewRestart endpoint =
    h1 [ class "center-screen" ]
        [ button [ class "btn btn-lg btn-primary", (onClick <| FetchRecords endpoint), href "#" ]
            [ text "Restart" ]
        ]


viewNavBar : String -> Html Msg
viewNavBar activeEndpoint =
    List.map (viewNavBarItem activeEndpoint) [ "people", "starships", "vehicles" ]
        |> ul [ class "tab tab-block" ]


viewNavBarItem : String -> String -> Html Msg
viewNavBarItem activeEndpoint endpoint =
    li
        [ class "tab-item"
        , classList
            [ ( "active", activeEndpoint == endpoint )
            ]
        ]
        [ a [ (onClick <| FetchRecords endpoint), href "#" ] [ text endpoint ] ]


viewStatusBar : List Record -> Html Msg
viewStatusBar list =
    div [ class "container" ]
        [ text ("Remainig: " ++ toString ((List.length list)))
        ]


viewGuess : Model -> Html Msg
viewGuess model =
    div []
        [ div [ class "container grid-lg" ] (List.map viewImage <| firstRecord model)
        , div [ class "container grid-lg" ] (List.map (viewButton model) model.candidates)
        ]


viewImage : Record -> Html Msg
viewImage record =
    figure [ class "column" ]
        [ img [ src record.image ] []
        ]


viewButton : Model -> Record -> Html Msg
viewButton model record =
    button
        [ onClick (MakeGuess record)
        , class ("btn column col-3 col-sm-12 " ++ buttonClass model record)
        ]
        [ text record.name ]



-- HTTP --


loadRecords : String -> Cmd Msg
loadRecords endpoint =
    Http.send RecordsRecieved (Api.getRecords endpoint)



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
