import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Nat32 "mo:base/Nat32";

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
};
