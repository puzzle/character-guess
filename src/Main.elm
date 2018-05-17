module Main exposing (..)

import Html exposing (Html, text, div, h1, img, figure, figcaption, ul, li, a)
import Html.Attributes exposing (src, class, href, classList)
import Html.Events exposing (onClick)
import Api exposing (Record, getRecords)
import List.Extra exposing (groupsOf)
import Http


---- MODEL ----


type alias Model =
    { records : List Record, endpoint : String }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { records = [], endpoint = "people" }
    in
        ( model, Cmd.batch [ loadRecords model.endpoint ] )



---- UPDATE ----


type Msg
    = NoOp
    | RecordsRecieved (Result Http.Error (List Record))
    | FetchRecords String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecordsRecieved (Ok records) ->
            ( { model | records = records }, Cmd.none )

        RecordsRecieved (Err err) ->
            Debug.crash "Error:" err

        FetchRecords endpoint ->
            ( { model | endpoint = endpoint }, loadRecords endpoint )

        _ ->
            ( model, Cmd.none )



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
