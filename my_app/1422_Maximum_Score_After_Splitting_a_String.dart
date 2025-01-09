int maxScore(String s) {
  int totalOnes = s.split('').where((char) => char == '1').length;
  int leftZero = 0;
  int maxScore = 0;

  for (int i = 0; i < s.length - 1; i++) {
    if (s[i] == '0'){
      leftZero++;
    } else {
      totalOnes--;
    }

    maxScore = maxScore > (leftZero + totalOnes) ? maxScore : (leftZero + totalOnes);
  }

  return maxScore;
}

void main() {
  String s = '011101';
  print(maxScore(s));
}