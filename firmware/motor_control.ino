#define IN1 5
#define IN2 6
#define IN3 7
#define IN4 8
#define ENA 9
#define ENB 10

void setup() {
  Serial.begin(57600);
  pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT); pinMode(ENB, OUTPUT);
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);
}

void loop() {
  if (Serial.available() >= 2) {
    int left_raw  = Serial.read();
    int right_raw = Serial.read();
    float left_limit  = 1.5;
    float right_limit = 1.5;
    if (left_raw > 130) {
      digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
      analogWrite(ENA, constrain((int)((left_raw - 127) * left_limit), 0, 255));
    } else if (left_raw < 124) {
      digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
      analogWrite(ENA, constrain((int)((127 - left_raw) * left_limit), 0, 255));
    } else {
      digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
      analogWrite(ENA, 0);
    }
    if (right_raw > 130) {
      digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
      analogWrite(ENB, constrain((int)((right_raw - 127) * right_limit), 0, 255));
    } else if (right_raw < 124) {
      digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
      analogWrite(ENB, constrain((int)((127 - right_raw) * right_limit), 0, 255));
    } else {
      digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
      analogWrite(ENB, 0);
    }
  }
}
