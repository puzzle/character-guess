module Main exposing (main)

import Html exposing (Html, text, div, h1, img, figure, figcaption, ul, li, a, button)
import Html.Attributes exposing (src, class, href, classList)
import Html.Events exposing (onClick)
import Api exposing (Record, getRecords)
import Http
import Random
import Random.Int
import Random.List
import Task
import Time


---- MODEL ----


type alias Model =
    { records : List Record
    , current : Record
    , guesses : List Record
    , correct : List Record
    , endpoint : String
    , seed : Random.Seed
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { records = []
            , current = Api.empty
            , guesses = []
            , correct = []
            , endpoint = "people"
            , seed = Random.initialSeed 1
            }
    in
        ( model, Cmd.batch [ loadRecords model.endpoint, generateSeed ] )



---- UPDATE ----


type Msg
    = RecordsRecieved (Result Http.Error (List Record))
    | FetchRecords String
    | NewSeed Int
    | Guess Record
    | NewGuess


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecordsRecieved (Ok records) ->
            nextModel model records

        RecordsRecieved (Err err) ->
            Debug.crash "Error:" err

        FetchRecords endpoint ->
            ( { model | endpoint = endpoint }, loadRecords endpoint )

        NewSeed newSeed ->
            ( { model | seed = Random.initialSeed newSeed }, Cmd.none )

        Guess record ->
            if record == model.current then
                update NewGuess { model | correct = record :: model.correct }
            else
                ( model, Cmd.none )

        NewGuess ->
            nextModel model model.records


generateSeed : Cmd Msg
generateSeed =
    Random.generate NewSeed Random.Int.anyInt


shuffle : Random.Seed -> List Record -> ( List Record, Random.Seed )
shuffle seed records =
    Random.step (Random.List.shuffle records) seed


nextModel : Model -> List Record -> ( Model, Cmd Msg )
nextModel model records =
    let
        ( shuffled, newSeed ) =
            shuffle model.seed records

        current =
            shuffled |> List.head |> Maybe.withDefault Api.empty

        ( guesses, nextSeed ) =
            shuffled |> List.take 3 |> shuffle newSeed
    in
        ( { model
            | records = shuffled
            , seed = nextSeed
            , guesses = guesses
            , current = current
          }
        , Cmd.none
        )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ viewNavBar model.endpoint
        , viewStatusBar model.correct
        , viewGuess model.current model.guesses
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
viewStatusBar records =
    div [ class "container" ] [ text ("Correct: " ++ toString ((List.length records))) ]


viewGuess : Record -> List Record -> Html Msg
viewGuess current guesses =
    div [ class "container" ]
        [ viewImage current
        , viewGuesses guesses
        ]


viewGuesses : List Record -> Html Msg
viewGuesses records =
    records
        |> List.map viewButton
        |> div [ class "container" ]


viewImage : Record -> Html Msg
viewImage record =
    figure [ class "column", class "col-3" ]
        [ img [ src record.image ] []
        ]


viewButton : Record -> Html Msg
viewButton record =
    button [ onClick (Guess record) ] [ text record.name ]



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
