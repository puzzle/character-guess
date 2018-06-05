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
    { remaining : List Record
    , current : Record
    , guesses : List Record
    , correct : List Record
    , wrong : List Record
    , endpoint : String
    , seed : Random.Seed
    , guess : Maybe Record
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { remaining = []
            , current = Api.empty
            , guesses = []
            , correct = []
            , wrong = []
            , endpoint = "people"
            , seed = Random.initialSeed 1
            , guess = Nothing
            }
    in
        ( model, Cmd.batch [ loadRecords model.endpoint, generateSeed ] )



---- UPDATE ----


type Msg
    = RecordsRecieved (Result Http.Error (List Record))
    | FetchRecords String
    | NewSeed Int
    | Guess Record
    | Next Record Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecordsRecieved (Ok records) ->
            nextGuess model records

        RecordsRecieved (Err err) ->
            Debug.crash "Error:" err

        FetchRecords endpoint ->
            ( { model | endpoint = endpoint }, loadRecords endpoint )

        NewSeed newSeed ->
            ( { model | seed = Random.initialSeed newSeed }, Cmd.none )

        Guess record ->
            let
                correct =
                    record == model.current

                delay =
                    if correct then
                        300
                    else
                        1000
            in
                ( { model | guess = Just record }, Delay.after delay Time.millisecond (Next record correct) )

        Next record correctGuessed ->
            if correctGuessed == True then
                let
                    remaining =
                        List.Extra.remove record model.remaining
                in
                    nextGuess { model | correct = record :: model.correct, remaining = remaining, guess = Nothing } remaining
            else
                nextGuess { model | wrong = record :: model.wrong, guess = Nothing } model.remaining


generateSeed : Cmd Msg
generateSeed =
    Random.generate NewSeed Random.Int.anyInt


shuffle : Random.Seed -> List Record -> ( List Record, Random.Seed )
shuffle seed records =
    Random.step (Random.List.shuffle records) seed


nextGuess : Model -> List Record -> ( Model, Cmd Msg )
nextGuess model records =
    let
        ( shuffled, newSeed ) =
            shuffle model.seed records

        current =
            shuffled |> List.head |> Maybe.withDefault Api.empty

        ( guesses, nextSeed ) =
            shuffled |> List.take 3 |> shuffle newSeed
    in
        ( { model
            | remaining = shuffled
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
        , viewStatusBar model.remaining model.correct model.wrong
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


viewStatusBar : List Record -> List Record -> List Record -> Html Msg
viewStatusBar all corrects wrongs =
    div [ class "container" ]
        [ text ("Correct: " ++ toString ((List.length corrects)))
        , text (" Wrong: " ++ toString ((List.length wrongs)))
        , text (" turns: " ++ toString ((List.length corrects + List.length wrongs)))
        , text (" remaining: " ++ toString ((List.length all)))
        ]


viewGuess : Model -> Html Msg
viewGuess model =
    div []
        [ div [ class "container grid-lg" ] [ viewImage model.current ]
        , div [ class "container grid-lg" ] (viewGuesses model)
        ]


viewGuesses : Model -> List (Html Msg)
viewGuesses model =
    model.guesses
        |> List.map (viewButton model.guess model.current)


viewImage : Record -> Html Msg
viewImage record =
    figure [ class "column" ]
        [ img [ src record.image ] []
        ]


viewButton : Maybe Record -> Record -> Record -> Html Msg
viewButton maybeGuess current record =
    let
        btnClass =
            case maybeGuess of
                Nothing ->
                    ""

                Just guess ->
                    if current == record && guess == current then
                        "btn-success"
                    else if guess == record then
                        "btn-error"
                    else if current == record then
                        "btn-success"
                    else
                        ""
    in
        button [ onClick (Guess record), class ("btn column col-3 col-sm-12 " ++ btnClass) ] [ text record.name ]



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
