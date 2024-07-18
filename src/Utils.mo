import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Nat32 "mo:base/Nat32";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import TypesICRC7 "/icrc7/types"


module {
public func natToBytes(n: Nat): [Nat8] {
    var bytes = Buffer.Buffer<Nat8>(0);
    var num = n;
    while (num > 0) {
        bytes.add(Nat8.fromNat(num % 256));
        num := num / 256;
    };
    return Buffer.toArray(bytes);
  };

  public func _natHash(a: Nat): Hash.Hash {
    let byteArray = natToBytes(a);
    var hash: Hash.Hash = 0;
    for (i in Iter.range(0, byteArray.size() - 1)) {
        hash := (hash * 31 + Nat32.fromNat(Nat8.toNat(byteArray[i])));
    };
    return hash;
  };

  public func generateUUID64() : async Nat {
      let randomBytes = await Random.blob();
      var uuid : Nat = 0;
      let byteArray = Blob.toArray(randomBytes);
      for (i in Iter.range(0, 7)) {
          uuid := Nat.add(Nat.bitshiftLeft(uuid, 8), Nat8.toNat(byteArray[i]));
      };
      uuid := uuid % 2147483647;
      return uuid;
  };

  // NFT Metadata
  public func getBaseMetadata(rarity : Nat, unit_id : Nat) : [(Text, TypesICRC7.Metadata)] {
        let _basicStats : TypesICRC7.MetadataArray = [
            ("level", #Nat(1)),
            ("health", #Int(100)),
            ("damage", #Int(10))
        ];
        let _general : TypesICRC7.MetadataArray = [
            ("unit_id", #Nat(unit_id)),
            ("class", #Text("Warrior")),
            ("rarity", #Nat(rarity)),
            ("faction", #Text("Cosmicrafts")),
            ("name", #Text("Cosmicrafts NFT")),
            ("description", #Text("Cosmicrafts NFT")),
            ("icon", #Nat(1)),
            ("skins", #Text("[{skin_id: 1, skin_name: 'Default', skin_description: 'Default Skin', skin_icon: 'url_to_canister', skin_rarity: 1]"))
        ];
        let _skills : TypesICRC7.MetadataArray = [
            ("shield_capacity", #Int(1)),
            ("impairment_resistance", #Int(1)),
            ("slow", #Int(1)),
            ("weaken", #Int(1)),
            ("stun", #Int(1)),
            ("disarm", #Int(1)),
            ("silence", #Int(1)),
            ("armor", #Int(1)),
            ("armor_penetration", #Int(1)),
            ("attack_speed", #Int(1)),
        ];
        let _skins : TypesICRC7.MetadataArray = [
            ("1", #MetadataArray([
                ("skin_id", #Nat(1)),
                ("skin_name", #Text("Default")),
                ("skin_description", #Text("Default Skin")),
                ("skin_icon", #Text("url_to_canister")),
                ("skin_rarity", #Nat(1))
              ]
            ))
        ];
        let _baseMetadata : [(Text, TypesICRC7.Metadata)] = [
            ("basic_stats", #MetadataArray(_basicStats)),
            ("general", #MetadataArray(_general)),
            ("skills", #MetadataArray(_skills)),
            ("skins", #MetadataArray(_skins)),
        ];
        return _baseMetadata;
    };

    public func getBaseMetadataWithAttributes(rarity: Nat, unit_id: Nat, name: Text, damage: Nat, hp: Nat) : [(Text, TypesICRC7.Metadata)] {
        let baseMetadata = getBaseMetadata(rarity, unit_id);

        var updatedMetadataBuffer = Buffer.Buffer<(Text, TypesICRC7.Metadata)>(baseMetadata.size());

        for ((key, value) in baseMetadata.vals()) {
            switch (key) {
                case ("general") {
                    let generalArray = switch (value) {
                        case (#MetadataArray(arr)) arr;
                        case (_) [];
                    };
                    var newGeneralArray = Buffer.Buffer<(Text, TypesICRC7.Metadata)>(generalArray.size());
                    for ((gKey, gValue) in generalArray.vals()) {
                        switch (gKey) {
                            case "name" newGeneralArray.add((gKey, #Text(name)));
                            case "description" newGeneralArray.add((gKey, #Text(name # " NFT")));
                            case _ newGeneralArray.add((gKey, gValue));
                        };
                    };
                    updatedMetadataBuffer.add((key, #MetadataArray(Buffer.toArray(newGeneralArray))));
                };
                case ("basic_stats") {
                    let basicStatsArray = switch (value) {
                        case (#MetadataArray(arr)) arr;
                        case (_) [];
                    };
                    var newBasicStatsArray = Buffer.Buffer<(Text, TypesICRC7.Metadata)>(basicStatsArray.size());
                    for ((bKey, bValue) in basicStatsArray.vals()) {
                        switch (bKey) {
                            case "health" newBasicStatsArray.add((bKey, #Int(hp)));
                            case "damage" newBasicStatsArray.add((bKey, #Int(damage)));
                            case _ newBasicStatsArray.add((bKey, bValue));
                        };
                    };
                    updatedMetadataBuffer.add((key, #MetadataArray(Buffer.toArray(newBasicStatsArray))));
                };
                case _ updatedMetadataBuffer.add((key, value));
            };
        };
        return Buffer.toArray(updatedMetadataBuffer);
    };
};
