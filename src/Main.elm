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


---- MODEL ----


type alias Model =
    { list : List Record
    , candidates : List Record
    , guess : Guess
    , endpoint : String
    , seed : Random.Seed
    , appState : AppState
    }


type AppState
    = Loading
    | Loaded
    | Failed Http.Error


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
            , appState = Loading
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
                    shuffle model.seed list
            in
                nextGuess
                    { model
                        | list = List.take 5 shuffled
                        , seed = nextSeed
                        , appState = Loaded
                    }

        RecordsRecieved (Err err) ->
            ( { model | appState = Failed err }, Cmd.none )

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
            case model.appState of
                Loading ->
                    [ viewLoading model ]

                Loaded ->
                    if (List.isEmpty model.list) then
                        [ viewRestart model.endpoint ]
                    else
                        [ viewStatusBar model.list
                        , viewGuess model
                        ]

                Failed err ->
                    [ viewError model err ]
    in
        div [] (viewNavBar model.endpoint :: children)


viewLoading : a -> Html msg
viewLoading model =
    div []
        [ div [ class "loading loading-lg" ] []
        , Html.h3 [] [ text "Loading" ]
        ]


viewError : Model -> Http.Error -> Html Msg
viewError model error =
    div [ class "center-screen" ]
        [ h1 [] [ text "Network error. Check your internet connection!" ]
        , button
            [ class "btn btn-lg btn-primary"
            , (onClick <| FetchRecords model.endpoint)
            , href "#"
            ]
            [ text "Retry..." ]
        ]


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
        [ div [ class "container grid-lg" ] (List.map (viewImage model.endpoint) <| (firstRecord model))
        , div [ class "container grid-lg" ] (List.map (viewButton model) model.candidates)
        ]


viewImage : String -> Record -> Html Msg
viewImage  endpoint record =
    figure [ class "column" ]
        [ img [ src (Api.url ++ endpoint ++ "/images/" ++  record.image) ] []
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
