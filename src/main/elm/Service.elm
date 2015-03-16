module Service (
    Word, VocalistShort, Vocalist, 
    getVocalistShortlist, getVocalist) where

import Http
import Json.Decode (..)
import Signal (..)


--------
-- API
--------
type alias Word = {word: String, definition: String}
type alias VocalistShort = { guid: String, title: String }
type alias Vocalist = { guid: String, title: String, words: List Word }

getVocalistShortlist : Signal (Result String (List VocalistShort))
getVocalistShortlist = 
    let sResult = httpGet "[]" (constant "http://localhost:8080/api/v1/vocalists/")
    in (parseResult decodeVocalistShortList) <~ sResult

getVocalist : Signal String -> Signal (Result String Vocalist)
getVocalist sGuid = 
    let makeUrl = (\ guid -> "http://localhost:8080/api/v1/vocalists/" ++ guid ++ "/")
        sUrl = makeUrl <~ sGuid
        sResult = httpGet "{}" sUrl
    in (parseResult decodeVocalist) <~ sResult


-------------
-- decoders
-------------
decodeWord : Decoder Word
decodeWord =
    object2 Word
        ("word" := string)
        ("definition" := string)

decodeVocalistShortList : Decoder (List VocalistShort)
decodeVocalistShortList = 
    list <| object2 VocalistShort
        ("guid" := string)
        ("title" := string)

decodeVocalist : Decoder Vocalist
decodeVocalist = 
    object3 Vocalist
        ("guid" := string)
        ("title" := string)
        ("words" := list decodeWord)        


------------
-- helpers
------------
isWaiting : Http.Response a -> Bool
isWaiting r = case r of
    Http.Waiting -> True
    _            -> False

result2response : a -> Http.Response a -> Result String a
result2response defaultValue response = case response of
   Http.Success r -> Ok r
   Http.Failure _ msg -> Err msg
   Http.Waiting -> Ok defaultValue

httpGet : String -> Signal String -> Signal (Result String String)
httpGet defaultValue sUrl = 
    let response = Http.sendGet sUrl
    in (result2response defaultValue) <~ response

parseResult : Decoder a -> Result String String -> Result String a
parseResult decoder result = case result of
    Err msg -> Err msg
    Ok json -> decodeString decoder json
