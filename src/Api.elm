module Api
    exposing
        ( Record
        , getRecords
        , empty
        , url
        )

import Http
import Json.Decode as Decode


type alias Record =
    { name : String
    , image : String
    }


url : String
url =
    ""


empty : Record
empty =
    { name = "Tux"
    , image = "https://www.gnu.org/graphics/babies/BabyTux.pngs"
    }


getRecords : String -> Http.Request (List Record)
getRecords path =
    let
        resource =
            url ++ path ++ "/list.json"
    in
        Http.get resource (decodeRecords path)


decodeRecords : String -> Decode.Decoder (List Record)
decodeRecords path =
    Decode.list (decodeRecord path)


decodeImage : String -> Decode.Decoder String
decodeImage path =
    Decode.string
        |> Decode.andThen
            (\image -> Decode.succeed (image))


decodeRecord : String -> Decode.Decoder Record
decodeRecord path =
    Decode.map2 Record
        (Decode.field "name" Decode.string)
        (Decode.field "image" (decodeImage path))
