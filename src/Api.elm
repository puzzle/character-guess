module Api
    exposing
        ( Record
        , getRecords
        )

import Http
import Json.Decode as Decode


type alias Record =
    { name : String
    , image : String
    }


getRecords : String -> Http.Request (List Record)
getRecords path =
    Http.get ("/" ++ path ++ "/list.json") (decodeRecords path)


decodeRecords : String -> Decode.Decoder (List Record)
decodeRecords path =
    Decode.list (decodeRecord path)


decodeImage : String -> Decode.Decoder String
decodeImage path =
    Decode.string
        |> Decode.andThen
            (\image -> Decode.succeed (path ++ "/images/" ++ image))


decodeRecord : String -> Decode.Decoder Record
decodeRecord path =
    Decode.map2 Record
        (Decode.field "name" Decode.string)
        (Decode.field "image" (decodeImage path))
