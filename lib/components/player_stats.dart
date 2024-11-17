class PlayerStats {
  int exp = 0;
  int level = 1;
  int expToNextLevel = 100;

  void addExp(int amount) {
    exp += amount;
    if (exp >= expToNextLevel) {
      level++;
      exp -= expToNextLevel;
      expToNextLevel =
          (expToNextLevel * 1.5).toInt(); // Zwiększ wymaganą ilość EXP
      print("Level up! You are now level $level");
      // Pokaż ekran wyboru wieży
    }
  }
}
