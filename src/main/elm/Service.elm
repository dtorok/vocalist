module Service (
    Word, VocalistShort, Vocalist, 
    getVocalist) where
--    getVocalistShortlist, getVocalist) where

import Http
import Json.Decode exposing (..)
import Task exposing (Task)


--------
-- API
--------
type alias Word = {word: String, definition: String}
type alias VocalistShort = { guid: String, title: String }
type alias Vocalist = { guid: String, title: String, words: List Word }

baseURL : String
baseURL = "http://localhost:8080/api/v1/vocalists/"

getVocalistShortlist : Task Http.Error (List VocalistShort)
getVocalistShortlist = Http.get decodeVocalistShortList baseURL

getVocalist : String -> Task Http.Error Vocalist
getVocalist guid = Http.get decodeVocalist (baseURL ++ guid ++ "/")

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
