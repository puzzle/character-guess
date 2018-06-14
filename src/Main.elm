module Main exposing (main)

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



---- UPDATE ----


type Msg
    = RecordsRecieved (Result Http.Error (List Record))
    | FetchRecords String
    | MakeGuess Record
    | NewSeed Int
    | MarkGuess Record


markGuess : Record -> Model -> ( Model, Float )
markGuess record model =
    if firstRecord model == [ record ] then
        ( { model | guess = Correct }, 500 )
    else
        ( { model | guess = Wrong }, 1000 )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MakeGuess record ->
            let
                ( newModel, timeout ) =
                    markGuess record model
            in
                ( newModel, Delay.after timeout Time.millisecond (MarkGuess record) )

        MarkGuess record ->
            let
                newList =
                    case model.guess of
                        Correct ->
                            List.Extra.remove record model.list

                        _ ->
                            model.list
            in
                ( { model | guess = None, list = newList }, Cmd.none )

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


nextGuess : Model -> ( Model, Cmd Msg )
nextGuess model =
    let
        ( list, nextSeed ) =
            model.list |> List.take 3 |> shuffle model.seed
    in
        ( { model | candidates = list, seed = nextSeed }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ viewNavBar model.endpoint
        , viewStatusBar model.list
        , viewGuess model
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
        [ a [ (onClick <| FetchRecords endpoint), (href "#") ] [ text endpoint ] ]


viewStatusBar : List Record -> Html Msg
viewStatusBar list =
    div [ class "container" ]
        [ text ("Remainig: " ++ toString ((List.length list)))
        ]


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
