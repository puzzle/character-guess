module Tests exposing (..)

import Test exposing (..)
import Main exposing (nextGuess, Guess, Model)
import Api exposing (Record)
import Expect
import Random


create : String -> Record
create name =
    { name = name, image = name ++ ".png" }


defaultRecords =
    [ create "Luke"
    , create "Han"
    , create "Leia"
    , create "C3PO"
    , create "R2D2"
    ]


generateModel : Model
generateModel =
    { list = defaultRecords
    , candidates = []
    , guess = Main.None
    , endpoint = ""
    , seed = Random.initialSeed 1
    }


all : Test
all =
    describe "nextGuess"
        [ test "picks 3 random candidates from list" <|
            \_ ->
                nextGuess generateModel
                    |> Tuple.first
                    |> .candidates
                    |> List.map .name
                    |> Expect.equal [ "Han", "Luke", "Leia" ]
        , test "generates a Cmd.none message" <|
            \_ ->
                nextGuess generateModel
                    |> Tuple.second
                    |> Expect.equal Cmd.none
        ]
