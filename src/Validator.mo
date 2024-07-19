module Validator {
  public func validateGame(timeInSeconds: Float, score: Float) : (Bool, Text) {
      let maxScoreRate: Float = 550000.0 / (5.0 * 60.0);
      let maxPlausibleScore: Float = maxScoreRate * timeInSeconds;
      let isScoreValid: Bool = score <= maxPlausibleScore;

      if (isScoreValid) {
          return (true, "Game is valid");
      } else {
          return (false, "Score is not valid");
      }
  };
}