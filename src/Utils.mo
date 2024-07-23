import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Nat32 "mo:base/Nat32";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Int64 "mo:base/Int64";
import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Types "Types";
import TypesICRC7 "/icrc7/types";
import TypesICRC1 "/icrc1/Types";


module Utils {


    public func get2BytesBlob() : async Blob {
    let fullBlob = await Random.blob();
    // Convert the Blob to an array of bytes
    let byteArray = Iter.toArray<Nat8>(fullBlob.vals());
    // Extract the first 2 bytes
    let twoBytes = Array.tabulate<Nat8>(2, func(i) {
        byteArray[i];
    });
    // Convert the array back to a Blob
    Blob.fromArray(twoBytes)
    };

    public func nat64ToHex(value: Nat64): Text {
        // Convert Nat64 to hexadecimal
        let hexChars: [Char] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
        var hex = "";
        var tempValue = value;
        for (i in Iter.range(0, 15)) { // Nat64 fits into 16 hex chars
            let nibble = tempValue & 0xF;
            hex := Text.fromChar(hexChars[Nat64.toNat(nibble)]) # hex;
            tempValue := tempValue >> 4;
        };
        return hex;
    };

    public func arrayToHex(array: [Nat8]): Text {
        let hexChars: [Char] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
        var hex = "";
        for (i in Iter.range(0, array.size() - 1)) {
            let byte = array[i];
            hex #= Text.fromChar(hexChars[Nat8.toNat(byte >> 4)]) # Text.fromChar(hexChars[Nat8.toNat(byte & 0x0F)]);
        };
        return hex;
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

    public func natToBytes(n: Nat): [Nat8] {
        var bytes = Buffer.Buffer<Nat8>(0);
        var num = n;
        while (num > 0) {
            bytes.add(Nat8.fromNat(num % 256));
            num := num / 256;
        };
        return Buffer.toArray(bytes);
    };

    public func _floatSort(a : Float, b : Float) : Float {
        if (a < b) {
        return -1;
        } else if (a > b) {
        return 1;
        } else {
        return 0;
        };
    };

    public func _natHash(a: Nat): Hash.Hash {
        let byteArray = natToBytes(a);
        var hash: Hash.Hash = 0;
        for (i in Iter.range(0, byteArray.size() - 1)) {
            hash := (hash * 31 + Nat32.fromNat(Nat8.toNat(byteArray[i])));
        };
        return hash;
    };

    public func _natEqual(a : Nat, b : Nat) : Bool {
        return a == b;
    };

    public func shuffleArray(arr: [Nat]): async [Nat] {
        let len = Array.size<Nat>(arr);
        var shuffled = Array.thaw<Nat>(arr);
        var i = len;
        while (i > 1) {
            i -= 1;
            let randomBytes = await Random.blob();
            let randomValue = Blob.toArray(randomBytes)[0];
            let j = Nat8.toNat(randomValue) % (i + 1);
            let temp = shuffled[i];
            shuffled[i] := shuffled[j];
            shuffled[j] := temp;
        };
        return Array.freeze<Nat>(shuffled);
    };

    public func calculateLevel(xp: Nat) : Nat {
        // Assuming each level requires twice as much XP as the previous one, starting with 100 XP for level 2.
        let baseXP: Nat = 100;
        var level: Nat = 1;
        var requiredXP: Nat = baseXP;

        // Increase level as long as XP meets or exceeds the required XP for the next level.
        while (xp >= requiredXP) {
            level := level + 1;
            requiredXP := requiredXP * 2;
        };

        return level;
    };

    public func arrayContains<T>(array: [T], value: T, eq: (T, T) -> Bool): Bool {
        for (element in array.vals()) {
            if (eq(element, value)) {
                return true;
            };
        };
        return false;
    };

  // NFT Metadata
    public func initDeck(): [(Text, Nat, Nat, Nat)] {
            return [
                ("Blackbird", 30, 120, 3),
                ("Predator", 20, 140, 2),
                ("Warhawk", 30, 180, 4),
                ("Tigershark", 10, 100, 1),
                ("Devastator", 20, 120, 2),
                ("Pulverizer", 10, 180, 3),
                ("Barracuda", 20, 140, 2),
                ("Farragut", 10, 220, 4)
            ];
    };

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

    public func getChestMetadata(rarity : Nat) : [(Text, TypesICRC7.Metadata)] {
        let _baseMetadata : [(Text, TypesICRC7.Metadata)] = [
            ("rarity", #Nat(rarity))
        ];
        return _baseMetadata;
    };

    // Function to get rarity from metadata
    public func getRarityFromMetadata(metadata: [(Text, TypesICRC7.Metadata)]): Nat {
        for ((key, value) in metadata.vals()) {
            if (key == "rarity") {
                return switch (value) {
                    case (#Nat(rarity)) rarity;
                    case (_) 1;
                };
            };
        };
        return 1;
    };

    // Function to get token amounts based on rarity
    public func getTokensAmount(rarity: Nat): (Nat, Nat) {
        var factor: Nat = 1;
        if (rarity <= 5) {
            factor := Nat.pow(2, rarity - 1);
        } else if (rarity <= 10) {
            factor := Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, rarity - 6), Nat.pow(2, rarity - 6)));
        } else if (rarity <= 15) {
            factor := Nat.mul(Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, 5), Nat.pow(2, 5))), Nat.div(Nat.pow(5, rarity - 11), Nat.pow(4, rarity - 11)));
        } else if (rarity <= 20) {
            factor := Nat.mul(Nat.mul(Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, 5), Nat.pow(2, 5))), Nat.div(Nat.pow(5, 5), Nat.pow(4, 5))), Nat.div(Nat.pow(11, rarity - 16), Nat.pow(10, rarity - 16)));
        } else {
            factor := Nat.mul(Nat.mul(Nat.mul(Nat.mul(Nat.pow(2, 5), Nat.div(Nat.pow(3, 5), Nat.pow(2, 5))), Nat.div(Nat.pow(5, 5), Nat.pow(4, 5))), Nat.div(Nat.pow(11, 5), Nat.pow(10, 5))), Nat.div(Nat.pow(21, rarity - 21), Nat.pow(20, rarity - 21)));
        };
        let shardsAmount = Nat.mul(12, factor);
        let fluxAmount = Nat.mul(4, factor);
        return (shardsAmount, fluxAmount);
    };

    // Function to get NFT level from metadata
    public func getNFTLevel(metadata: [(Text, TypesICRC7.Metadata)]): Nat {
        for ((key, value) in metadata.vals()) {
            if (key == "basic_stats") {
                let basicStatsArray = switch (value) {
                    case (#MetadataArray(arr)) arr;
                    case (_) [];
                };
                for ((bKey, bValue) in basicStatsArray.vals()) {
                    if (bKey == "level") {
                        let level = switch (bValue) {
                            case (#Nat(level)) level;
                            case (_) 0;
                        };
                        Debug.print("Level found: " # Nat.toText(level));
                        return level;
                    };
                };
            };
        };
        Debug.print("No level found, defaulting to 0");
        return 0;
    };

    // Function to calculate the upgrade cost based on level
    public func calculateCost(level: Nat): Nat {
        var cost: Nat = 9;
        for (i in Iter.range(2, level)) {
            cost := cost + (Nat.div(cost, 3)); // Increase cost by ~33%
        };
        return cost;
    };

    // Function to update basic stats
    public func updateBasicStats(basicStats: TypesICRC7.Metadata): TypesICRC7.Metadata {
        let _data: TypesICRC7.Metadata = switch (basicStats) {
            case (#Nat(_)) basicStats;
            case (#Text(_)) basicStats;
            case (#Blob(_)) basicStats;
            case (#Int(_)) basicStats;
            case (#MetadataArray(_a)) {
                var _newArray = Buffer.Buffer<(Text, TypesICRC7.Metadata)>(_a.size());
                for (_md in _a.vals()) {
                    let _mdKey: Text = _md.0;
                    let _mdValue: TypesICRC7.Metadata = _md.1;
                    switch (_mdKey) {
                        case "level" {
                            let _level: Nat = switch (_mdValue) {
                                case (#Nat(level)) level + 1;
                                case (_) 0;
                            };
                            let _newLevelMetadata: TypesICRC7.Metadata = #Nat(_level);
                            _newArray.add(("level", _newLevelMetadata));
                        };
                        case "health" {
                            let _health: Float = switch (_mdValue) {
                                case (#Int(health)) Float.fromInt64(Int64.fromInt(health)) / 100;
                                case (_) 0;
                            };
                            let _newHealth: Float = _health * 1.1 * 100;
                            let _newHealthMetadata: TypesICRC7.Metadata = #Int(Int64.toInt(Float.toInt64(_newHealth)));
                            _newArray.add(("health", _newHealthMetadata));
                        };
                        case "damage" {
                            let _damage: Float = switch (_mdValue) {
                                case (#Int(damage)) Float.fromInt64(Int64.fromInt(damage)) / 100;
                                case (_) 0;
                            };
                            let _newDamage: Float = _damage * 1.1 * 100;
                            let _newDamageMetadata: TypesICRC7.Metadata = #Int(Int64.toInt(Float.toInt64(_newDamage)));
                            _newArray.add(("damage", _newDamageMetadata));
                        };
                        case (_) {
                            _newArray.add((_mdKey, _mdValue));
                        };
                    };
                };
                return #MetadataArray(Buffer.toArray(_newArray));
            };
        };
        return _data;
    };

    // Function to upgrade advanced attributes
    public func upgradeAdvancedAttributes(_nft_level: Nat, currentValue: TypesICRC7.Metadata): TypesICRC7.Metadata {
        let _data: TypesICRC7.Metadata = switch(currentValue) {
            case (#Nat(_)) {
                currentValue;
            };
            case (#Text(_)) {
                currentValue;
            };
            case (#Blob(_)) {
                currentValue;
            };
            case (#Int(_)) {
                currentValue;
            };
            case (#MetadataArray(_a)) {
                var _newArray = Buffer.Buffer<(Text, TypesICRC7.Metadata)>(_a.size());
                for (_md in _a.vals()) {
                    let _mdKey: Text = _md.0;
                    let _mdValue: TypesICRC7.Metadata = _md.1;
                    switch(_mdKey) {
                        case ("shield_capacity") {
                            switch(_mdValue) {
                                case (#Nat(shield_capacity)) {
                                    let _newShieldCapacity: Nat = shield_capacity + 1;
                                    let _newShieldCapacityMetadata: TypesICRC7.Metadata = #Nat(_newShieldCapacity);
                                    _newArray.add(("shield_capacity", _newShieldCapacityMetadata));
                                };
                                case (#Text(_)) {};
                                case (#Blob(_)) {};
                                case (#Int(shield_capacity)) {
                                    let _newShieldCapacity: Int = shield_capacity + 1;
                                    let _newShieldCapacityMetadata: TypesICRC7.Metadata = #Int(_newShieldCapacity);
                                    _newArray.add(("shield_capacity", _newShieldCapacityMetadata));
                                };
                                case (#MetadataArray(_)) {};
                            };
                        };
                        case (_) {
                            _newArray.add((_mdKey, _mdValue));
                        };
                    };
                };
                return #MetadataArray(Buffer.toArray(_newArray));
            };
        };
        return _data;
    };


    // Results

    // Function to handle minting errors
    public func handleMintError(token: Text, error: TypesICRC1.TransferError): Text {
        switch (error) {
            case (#Duplicate(_d)) {
                return "{\"token\":\"" # token # "\", \"error\":true, \"message\":\"Chest open failed: " # token # " mint failed: Duplicate\"}";
            };
            case (#GenericError(_g)) {
                return "{\"token\":\"" # token # "\", \"error\":true, \"message\":\"Chest open failed: " # token # " mint failed: GenericError: " # _g.message # "\"}";
            };
            case (#CreatedInFuture(_cif)) {
                return "{\"token\":\"" # token # "\", \"error\":true, \"message\":\"Chest open failed: " # token # " mint failed: CreatedInFuture\"}";
            };
            case (#BadFee(_bf)) {
                return "{\"token\":\"" # token # "\", \"error\":true, \"message\":\"Chest open failed: " # token # " mint failed: BadFee\"}";
            };
            case (#BadBurn(_bb)) {
                return "{\"token\":\"" # token # "\", \"error\":true, \"message\":\"Chest open failed: " # token # " mint failed: BadBurn\"}";
            };
            case (_) {
                return "{\"token\":\"" # token # "\", \"error\":true, \"message\":\"Chest open failed: " # token # " mint failed: Other error\"}";
            };
        }
    };

    // Function to handle chest errors
    public func handleChestError(error: TypesICRC7.TransferError): Text {
        switch (error) {
            case (#GenericError(_g)) {
                return "{\"error\":true, \"message\":\"Chest open failed: GenericError: " # _g.message # "\"}";
            };
            case (#CreatedInFuture(_cif)) {
                return "{\"error\":true, \"message\":\"Chest open failed: CreatedInFuture\"}";
            };
            case (#Duplicate(_d)) {
                return "{\"error\":true, \"message\":\"Chest open failed: Duplicate\"}";
            };
            case (#TemporarilyUnavailable(_tu)) {
                return "{\"error\":true, \"message\":\"Chest open failed: TemporarilyUnavailable\"}";
            };
            case (#TooOld) {
                return "{\"error\":true, \"message\":\"Chest open failed: TooOld\"}";
            };
            case (#Unauthorized(_u)) {
                return "{\"error\":true, \"message\":\"Chest open failed: Unauthorized\"}";
            };
        }
    };

    // Missions Utils
    public func selectRandomRewardPool(rewardPools: [Types.RewardPool], blob: Blob): Types.RewardPool {
        let size: Nat8 = Nat8.fromNat(rewardPools.size() - 1);
        let random = Random.Finite(blob);
        let index = switch (random.range(size)) {
            case (?i) i;
            case null 0; // Default to 0 if range generation fails
        };
        return rewardPools[index];
    };

    public func calculateRewardAmount(minAmount: Nat, maxAmount: Nat, blob: Blob): Nat {
        let range: Nat = maxAmount - minAmount;
        let randomValue = switch (Random.Finite(blob).range(Nat8.fromNat(range))) {
            case (?v) v;
            case null 0;
        };
        return minAmount + randomValue;
    };

    public func getRandomMissionOption(options: [Types.MissionOption], blob: Blob): Types.MissionOption {
        let size: Nat8 = Nat8.fromNat(options.size() - 1);
        let index: Nat = Random.rangeFrom(size, blob);
        return options[index];
    };

    public func logMissionResults(results: [(Bool, Text, Nat)], missionType: Text): async () {
        for ((success, message, id) in results.vals()) {
            Debug.print("[logMissionResults] " # missionType # " Mission ID: " # Nat.toText(id) # " - Success: " # Bool.toText(success) # " - Message: " # message);
        }
    };
};
