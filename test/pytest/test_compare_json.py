import json

def load_json(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)

def test_output_matches_golden():
    generated = load_json("../../bin/output.json")
    golden = load_json("../golden/golden.json")
    print("JSONs match:", generated == golden)
    assert generated == golden, "Generated JSON does not match golden reference"
