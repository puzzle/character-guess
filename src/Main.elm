module Main exposing (main)

import Html exposing (Html, text, div, h1, img, figure, figcaption, ul, li, a)
import Html.Attributes exposing (src, class, href, classList)
import Html.Events exposing (onClick)
import Api exposing (Record, getRecords)
import List.Extra exposing (groupsOf)
import Http
import Random
import Random.Int
import Random.List


---- MODEL ----


type alias Model =
    { records : List Record
    , endpoint : String
    , seed : Random.Seed
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { records = []
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecordsRecieved (Ok records) ->
            let
                ( shuffled, newSeed ) =
                    shuffle model.seed records
            in
                ( { model | records = shuffled, seed = newSeed }, Cmd.none )

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
shuffle seed records =
    Random.step (Random.List.shuffle records) seed



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ viewNavBar model.endpoint
        , viewRecords model.records
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


viewRecords : List Record -> Html Msg
viewRecords records =
    List.map viewRecord records
        |> groupsOf 3
        |> List.map (\items -> div [ class "columns" ] items)
        |> div [ class "container" ]


viewRecord : Record -> Html Msg
viewRecord record =
    figure [ class "column", class "col-3" ]
        [ img [ src record.image ] []
        , figcaption [] [ text record.name ]
        ]



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
