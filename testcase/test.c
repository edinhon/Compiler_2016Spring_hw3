int main() {
  int a = 4000;
  int b = 4000;
  int i = 0;
while(i < 4){

  digitalWrite(13, HIGH);
  delay(a);
  digitalWrite(13, LOW);
  delay(b);

  a = a/2;
  b = b/2;
  i = i+1;
}
  return 0;
}
