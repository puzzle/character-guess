module Delay exposing (after)

import Time exposing (Time)
import Process
import Task


{-| Delays an update (with a message) by a given amount of time
after 500 millisecond DelayedMsg
-}
after : Float -> Time -> msg -> Cmd msg
after time unit msg =
    after_ (time * unit) msg


{-| Private: internal version of after,
used to collect total time in sequence
-}
after_ : Time -> msg -> Cmd msg
after_ time msg =
    Process.sleep time
        |> Task.map (always msg)
        |> Task.perform identity
