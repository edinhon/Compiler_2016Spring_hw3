int main(){
int a = 5000;
a = 1 + 2 * 3;
int b = 1000;
if(!(a || b)){
	a = 1000;
}
else {
	a = 2000;
}
b = 3;
digitalWrite(13, HIGH);
delay(a);
digitalWrite(13, LOW);
delay(a);
return 0;
}
