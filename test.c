int main() {
  int a = 3000;
  int b = 4000;

  while(a < b){
	a = a + 500;
  }

  digitalWrite(13, HIGH);
  delay(a);
  digitalWrite(13, LOW);
  delay(b);

  return 0;
}
