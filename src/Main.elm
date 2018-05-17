module Main exposing (..)

import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src, class)
import Api exposing (Record, getRecords)
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecordsRecieved (Ok records) ->
            ( { model | records = records }, Cmd.none )

        RecordsRecieved (Err err) ->
            Debug.crash "Error:" err

        _ ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text ("Accesing " ++ model.endpoint) ]
        , viewRecords model.records
        ]


viewRecords : List Record -> Html Msg
viewRecords records =
    List.map viewRecord records
        |> div [ class "container" ]


viewRecord : Record -> Html Msg
viewRecord record =
    div []
        [ text record.name
        , img [ src record.image ] []
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
