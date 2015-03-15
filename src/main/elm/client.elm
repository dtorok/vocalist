import Http
import Json.Decode (..)
import Text (..)
import Signal (..)
import Debug
import Result
import List

-- types
type alias Word = {word: String, definition: String}
type alias VocalistShort = { guid: String, title: String }
type alias Vocalist = { guid: String, title: String, words: List Word }

-- decoders
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

-- getters
getVocalistShortlist : Signal (Result String (List VocalistShort))
getVocalistShortlist = 
    let sResult = httpGet <| constant "http://localhost:8080/api/v1/vocalists/"
    in (parseResult decodeVocalistShortList) <~ sResult

getVocalist : Signal String -> Signal (Result String Vocalist)
getVocalist sGuid = 
    let makeUrl = (\ guid -> "http://localhost:8080/api/v1/vocalists/" ++ guid ++ "/")
        sUrl = makeUrl <~ sGuid
        sResult = httpGet sUrl
    in (parseResult decodeVocalist) <~ sResult

-- helpers
isWaiting : Http.Response a -> Bool
isWaiting r = case r of
    Http.Waiting -> True
    _            -> False

result2response : Http.Response a -> Result String a
result2response response = case response of
   Http.Success r -> Ok r
   Http.Failure _ msg -> Err msg
   Http.Waiting -> Err "" -- ick...

httpGet : Signal String -> Signal (Result String String)
httpGet sUrl = 
    let response = Http.sendGet sUrl
    in result2response <~ (dropIf isWaiting Http.Waiting response)

parseResult : Decoder a -> Result String String -> Result String a
parseResult decoder result = case result of
    Err msg -> Err msg
    Ok json -> decodeString decoder json


-------------------
------------- TESTS
-------------------
-- vocalistHTTP -> 

testVocalistShortList = "[{\"guid\":\"1b42147b-4f6c-4e68-9d50-a6188d9e4fb3\",\"title\":\"For the win\"},{\"guid\":\"dc045413-ecd7-45b7-a3ec-2c4f6b042730\",\"title\":\"Body parts idioms\"},{\"guid\":\"eddf9bc9-89ef-4774-b656-b4d1c61da3ce\",\"title\":\"Body Parts\"},{\"guid\":\"9b9c6cc6-2930-4c48-a7e1-73a51a9c6b66\",\"title\":\"Tenses\"}]"
testVocalist = "{\"words\":[{\"word\":\"Tenet\",\"definition\":\"elv; dogma\"},{\"word\":\"Tangible\",\"definition\":\"kézzelfogható; igazi; tapintható\"},{\"word\":\"derogatory\",\"definition\":\"méltatlan; lekicsinylő\"},{\"word\":\"moniker\",\"definition\":\"becenév; elnevezés\"},{\"word\":\"To ferret sg out\",\"definition\":\"Kifürkész vmit\"},{\"word\":\"daunting\",\"definition\":\"ijesztő; csüggesztő\"},{\"word\":\"imagery\",\"definition\":\"ábrázolás; hasonlat\"},{\"word\":\"interesting imagery\",\"definition\":\"érdekes gondolat\"},{\"word\":\"overhead imagery\",\"definition\":\"műholdfelvétel\"},{\"word\":\"to appraise sg\",\"definition\":\"felmér vmit; végigmér vmit; értékel vmit\"},{\"word\":\"of that ilk\",\"definition\":\"hasonszőrű; afféle, affajta\"},{\"word\":\"full-blown\",\"definition\":\"kész; teljes értékű; kifejlett\"},{\"word\":\"substantial\",\"definition\":\"jómódú\"},{\"word\":\"substantial\",\"definition\":\"kiadós; lényeges; szilárd; alapos\"},{\"word\":\"novelty\",\"definition\":\"újdonság, újszerűség\"},{\"word\":\"incorporating\",\"definition\":\"beépített; tartalmaz\"},{\"word\":\"mundane\",\"definition\":\"földi; evilági; világias\"},{\"word\":\"I ask your indulgence\",\"definition\":\"türelmedet kérném\"},{\"word\":\"assault and battery\",\"definition\":\"súlyos testi sértés\"},{\"word\":\"jurisdiction\",\"definition\":\"joghatóság; törvénykezés; igazságszolgáltatás\"},{\"word\":\"to vanquish your rivals\",\"definition\":\"legyűri/legyőzi az ellenfeleit\"},{\"word\":\"subtle\",\"definition\":\"hajszálnyi; kényes; finom\"},{\"word\":\"a broad variety of sg\",\"definition\":\"széles választéka vminek\"},{\"word\":\"ineffable\",\"definition\":\"kifejezhetetlen; elmondhatatlan; kimondhatatlan\"},{\"word\":\"arbitrary\",\"definition\":\"önkényes; tetszőleges; tetszés szerinti\"},{\"word\":\"penchant for sg\",\"definition\":\"előszeretet; hajlam vmire\"},{\"word\":\"to lounge\",\"definition\":\"henyél; lebzsel; kószál\"},{\"word\":\"lounge chair\",\"definition\":\"fotel\"},{\"word\":\"tremendously\",\"definition\":\"rettenetesen; hallatlanul; roppantul\"},{\"word\":\"aficionado\",\"definition\":\"rajongó; szurkoló\"},{\"word\":\"infamous\",\"definition\":\"rossz hírű; gyalázatos; becstelen\"},{\"word\":\"anticipation\",\"definition\":\"előérzet; megérzés; várakozás\"},{\"word\":\"demotion\",\"definition\":\"lefokozás\"},{\"word\":\"inherently\",\"definition\":\"benne rejlően; vele járóan; alapvetően\"},{\"word\":\"thwarted rage\",\"definition\":\"tehetetlen düh\"},{\"word\":\"to be thwarted\",\"definition\":\"elgáncsolják; akadályozzák; kudarcot vall\"},{\"word\":\"innate\",\"definition\":\"zsigeri; ösztönös; vele született\"},{\"word\":\"innate gift\",\"definition\":\"istenadta tehetség\"},{\"word\":\"to be in command of your life\",\"definition\":\"maga irányítja az életét\"},{\"word\":\"To each his own\",\"definition\":\"Ki-ki a magáét; kinek a pap, kinek a papné\"},{\"word\":\"to excel at sg\",\"definition\":\"kitűnik vmiben; kimagaslik vmiben\"},{\"word\":\"contingent\",\"definition\":\"feltételes; esetleges\"},{\"word\":\"to perceive\",\"definition\":\"érzékel; észlel; megérez; rájön\"},{\"word\":\"thus\",\"definition\":\"eképpen; ennél fogva\"},{\"word\":\"guild\",\"definition\":\"céh; liga\"},{\"word\":\"death appealed to him\",\"definition\":\"vonzódott a halálhoz\"},{\"word\":\"eye-appealing\",\"definition\":\"tetszetős; vonzó\"},{\"word\":\"to brag\",\"definition\":\"henceg; kérkedik; dicsekszik\"}],\"guid\":\"1b42147b-4f6c-4e68-9d50-a6188d9e4fb3\",\"title\":\"For the win\"}"

tostr : Http.Response String -> String
tostr resp = case resp of
   Http.Success s -> "Done: " ++ s
   Http.Waiting   -> "Waiting..."
   Http.Failure _ msg -> "Error: " ++ msg


testJSONDecode : String
testJSONDecode = 
    case (decodeString decodeVocalist testVocalist) of
        Err _ -> "ERROR"
        Ok v -> case v.words of
            [] -> ""
            (w::ws) -> w.definition

testComm : Signal String
testComm = 
    let f r = case r of
            Err msg -> msg
            Ok (l::ls) -> l.guid
        f' r = case r of
            Err msg -> msg
            Ok v -> v.title
    in f' <~ (getVocalist (f <~ getVocalistShortlist))
--main : Signal Element
--main = txt <~ (Http.sendGet (constant "http://localhost:8080/api/v1/vocalists/"))


main = plainText <~ testComm
