use Assert.{fail, assertEq, assertErr}
use Util.Json.{JObject, JString}
use Util.Json.JsonError
use Util.Json.FromJson.fromJson
use Util.Json.ToJson.toJson
use Task.StatusSelf


@Test
def statusSelf_Json_encodeDecode_NotPlanned(): Unit \ Assert =
  encodeDecode(StatusSelf.NotPlanned)

@Test
def statusSelf_Json_encodeDecode_Later(): Unit \ Assert =
  encodeDecode(StatusSelf.Later)

@Test
def statusSelf_Json_encodeDecode_Done(): Unit \ Assert =
  encodeDecode(StatusSelf.Done)

@Test
def statusSelf_fromJson_whenInvalidType_shouldFail(): Unit \ Assert =
  let j = JObject(Map#{"$type" => JString("Invalid"), "value" => JString("Done")});
  let result: Result[JsonError, StatusSelf] = fromJson(j);
  assertErr(result)

@Test
def statusSelf_fromJson_whenInvalidValue_shouldFail(): Unit \ Assert =
  let j = JObject(Map#{"$type" => JString("StatusSelf"), "value" => JString("ApparentlyInvalidValue")});
  let result: Result[JsonError, StatusSelf] = fromJson(j);
  assertErr(result)

def encodeDecode(s: StatusSelf): Unit \ Assert =
  use ToString.toString;
  use Util.Json.JsonError;

  match (toJson(s) |> fromJson) {
    case Ok(result) => assertEq(expected = s, result)
    case Err(e) => fail(toString(e))
  }
