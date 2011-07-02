/*
 This sketch emulates our TV remote control devices to provide a
 one-button operation for switching between different input sources
 in our case Tivo, AppleTV and a DVD player.
 
 The sketch is customized for our particular set-up of
 devices and their behavior. For instance, DVD "play" also powers
 up the device, which is something we are making use of in some cases.
 
 The HW includes five buttons: TV, APPLE, DVD POWER-ON, POWER-OFF
 
 These buttons are SPDT, which means that they close or open two
 separate circuits. In 'rest' state, they connect their respective
 Arduino pin to Gd. If, for instance, 'TV' is pressed, this 
 A) powers up the Arduino and B) disconnects pin 7 from Ground.
 
 So, the sketch will start up (due to A) run through Setup and
 find pin 7 high (due to B) and then go into the IRsending 
 required for switching the video & audio sources to TV-viewing.
 
 The Power On button is just a power switch for the Arduino, so if we
 run through the sketch without finding any of the other pins
 being 'high',  this is interpreted as "Power On".
 
 The user, of course, needs to press the button until all the IR
 actions are completed, or else Arduino loses power. A LED lits up
 when the sketch reaches the end of its processing, after which the process
 goes remains in the loop with no further actions.
 
 This sketch makes use of the great IRremote library,
 Copyright 2009 Ken Shirriff
 See http://arcfn.com/2009/08/multi-protocol-infrared-remote-library.html
 
 The IR-CODES were researched using the example sketches provided
 with the IRremote library.
 
 More details about this at http://arduinostuff.jimdo.com/
  */


//Set up the IR library 
//IR-Led connects to pin 3 - this is defined in the library
#include <IRremote.h>
IRsend irsend;


//Pins
#define TVBUTTON 7    //Pin 7 = Switch to TV
#define APPLEBUTTON 6 //Pin 6 = Switch to Apple
#define DVDBUTTON 8   //Pin 8 = Switch to DVD
#define POWEROFF 9    //Pin 9 = POWER OFF
#define POWERON 88    //nothing but POWER button is pressed
#define ledpin 12     //LED
int whichButton;


//*** SETUP
void setup()
{
  // Set up pins
  pinMode(TVBUTTON, INPUT);     
  digitalWrite(TVBUTTON, HIGH);  

  pinMode(APPLEBUTTON, INPUT);     
  digitalWrite(APPLEBUTTON, HIGH);  

  pinMode(DVDBUTTON, INPUT);     
  digitalWrite(DVDBUTTON, HIGH);

  pinMode(POWEROFF, INPUT);     
  digitalWrite(POWEROFF, HIGH);

  // LED on pin 12
  pinMode(ledpin, OUTPUT);     
  digitalWrite(ledpin, LOW);


  // Here's the action:
  //    1) Check which button is pressed   
  //    2) Send IR signals  
  //    3) Indicate 'done' with LED
  checkButton(); 
  sendIR();
  digitalWrite(ledpin, HIGH);  
  
}
void loop() {
  // Stay here forever- we do the IR-ing only once
}



// **************
// CHECKBUTTON
//  
// Check which button is being pressed
// No button means 'power on'
// We did not bother with the "more than 1 button" cases

void checkButton (){
  whichButton = POWERON;   
  if (digitalRead(TVBUTTON) == HIGH) {
    whichButton = TVBUTTON;
  }
  if (digitalRead(APPLEBUTTON) == HIGH) {
    whichButton = APPLEBUTTON;
  }
  if (digitalRead(DVDBUTTON) == HIGH) {
    whichButton = DVDBUTTON;
  }
  if (digitalRead(POWEROFF) == HIGH) {
    whichButton = POWEROFF;
  }
}


// **************
// SENDIR
// 
// Based on which button was pressed, one of five functions is 
// called. Function names are self-explanatory.

void sendIR(){
  switch (whichButton){
  case POWERON:
    {
      turnontv();
      break;
    }
  case POWEROFF:
    {
      turneverythingoff();
      break;
    }
  case TVBUTTON:
    {
      switchtotv();
      break;
    }
  case APPLEBUTTON:
    {
      switchtoapple();
      break;
    }
  case DVDBUTTON:
    {
      switchtodvd();
      break;
    }
  }
}


// **************
// TURNONTV
// TURNEVERYTHINGOFF
// SWITCHTOTV
// SWITCHTOAPPLE
// SWITCHTODVD
//
// Here are the "action lists" for the respective operations.
// The actions, delays etc are adjusted to the various quirks of our 
// particular equipment. Function names are quite self-explanatory.


// *******
void turnontv(){
  // We want 'power on' to start up normal TV viewing 
  //
  TVpower();
  SoundFromTivo();
  //our TV does not accept input signals 
  // until a few seconds after power on, so wait 4 sec.
  delay (4000);    
  VideoFromTivo();
}


// *******
void turneverythingoff(){
  // We want this action to lead to a state with everything turned
  // off, regardless of what state the respective equipment is in.
  
  // *** Starting with the DVD player:
  //     It's probably 'off' but we don't know that, so we make sure 
  //     it's 'on' first and then we power-toggle to 'off'.
  //     Our DVD happens to power up at "play", so we're using that 
  //     to get in sync before the toggle to 'off'.
  DVDplay();
  delay (200);
  DVDpower();      // ... and here DVD turns off

  // *** The Apple TV is next
  // 'menu' wakes up the device if it isn't awake alredy
  AppleMenu();     
  delay (200);
  AppleSleep();    //... and here Apple TV turns off


  // *** Now, the TV
  // But before we turn the TV off, let's set vieing mode to 'TV'
  // so that everything is set up next time we power on the
  // TV just using the normal Tivo remote. 
  switchtotv();    // Set to "TV" as prep for power on next time. 
  
  // Now, turn the TV and the receiver off. It's actually just a 
  // 'toggle', but it is safe to assume that the TV and Receiver
  // indeed were on, so this is OK
  delay (200);
  TVpower();       //... and here the TV turns off
  
  
  // *** The Receiver is turned off 
  Audiopower();    
}


// *******
void switchtotv(){
  // Not much to comment on here. 
  // Sound video should come from the Tivo box. 
  SoundFromTivo();
  VideoFromTivo();
}

// *******
void switchtoapple(){
  // In addition to switching sound and video, we also wake up
  // the Apple TV with a 'menu' signal.
  AppleMenu();     
  SoundFromApple();
  VideoFromApple();
}


// *******
void switchtodvd(){
  // In addition to switching sound and video, we also wake up
  // the DVD with a 'play' signal. But, since that obviously
  // starts playing the DVD, we follow up with 'pause'
  DVDplay();
  SoundFromDvd();
  VideoFromDvd();
  DVDpause();
}


//****************************************************
// The actual IR-sending below
//****************************************************


//****************************************************
// ORDERS TO RECEIVER
// The Onkyo receiver understands IR signals in the NEC format. 
// Of course, which particular codes to send depend on how 
// things are connected to the Receiver. 
//
// We need the following IR orders: 
//     Selection of audio source (3 versions)
//     Power Toggle
//
void SoundFromTivo(){
  for (int i = 0; i<3; i++){
    irsend.sendNEC(0x4BB6B04F, 32);
  }
}


// ****
void SoundFromDvd (){
  for (int i = 0; i<3; i++){
    irsend.sendNEC(0x4BB6F00F, 32);
  }
}


// ****
void SoundFromApple (){
  for (int i = 0; i<3; i++){
    irsend.sendNEC(0x4B3631CE, 32);
  }
}

// ****
void Audiopower(){
  // Receiver power toggle
  for (int i = 0; i<3; i++){
    irsend.sendNEC(0x4B36D32C, 32);
  }
}


//****************************************************
// ORDERS TO TV
// The sendPanasonic function is not in the original IRremote library.
// We are using a modified IRremote, with this function added
// More details about this at http://arduinostuff.jimdo.com/
//
// We need the following IR orders: 
//     Select Input
//     Set video source (3 versions)
//     Power Toggle
//
// Video input selection consists of two orders: 1) 'select input'
// and 2), the actual setting of video source. 
// Our Panasonic is a little stingy, so we are sending each order three times.
// Of course, which particular codes to send depend on how things
// are connected to the TV. 
//
void VideoFromTivo (){
  for (int i = 0; i<3; i++){
    // Select Input
    irsend.sendPanasonic(0x40040100, 0xA0A10000, 48);
  }
  delay (500);
  for (int i = 0; i<3; i++){
    // Input = Tivo
    irsend.sendPanasonic(0x40040100, 0x28290000, 48);
  }
}


// ****
void VideoFromDvd (){
  for (int i = 0; i<3; i++){
    // Select Input
    irsend.sendPanasonic(0x40040100, 0xA0A10000, 48);
  }
  delay (500);
  for (int i = 0; i<3; i++){
    // Input = DVD
    irsend.sendPanasonic(0x40040100, 0xA8A90000, 48);
  }
}


// ****
void VideoFromApple (){
  for (int i = 0; i<3; i++){
    // Select Input
    irsend.sendPanasonic(0x40040100, 0xA0A10000, 48);
  }
  delay (500);
  for (int i = 0; i<3; i++){
    // Input = Apple TV
    irsend.sendPanasonic(0x40040100, 0xC8C90000, 48);
  }
}

// ****
void TVpower(){
  // TV power toggle
  for (int i = 0; i<3; i++){
    irsend.sendPanasonic(0x40040100, 0xBCBD0000, 48);
  }
}


//****************************************************
// ORDERS TO DVD
// The sendSamsung function is not in the original IRremote library.
// We are using a modified IRremote, with this function added
// More details about this at http://arduinostuff.jimdo.com/
//
// We need the following IR orders: 
//     Play
//     Pause
//     Power Toggle
//
// Pause is the same as Play, actually, but we separate them for clarity.
//
void DVDplay(){
  // DVD play or pause
  irsend.sendSamsung(0x6604CFC1, 0x7E200000, 42);
}


// ****
void DVDpause(){
  // DVD play or pause
  irsend.sendSamsung(0x6604CFC1, 0x7E200000, 42);
}


// ****
void DVDpower(){
  // DVD power toggle
  for (int i = 0; i<3; i++){
    irsend.sendSamsung(0x6604CFE2, 0x5D800000, 42);
  }
}


//****************************************************
// ORDERS TO APPLE TV
// The Apple TV understands IR signals in the NEC format. 
//
// We need the following IR orders: 
//     Menu
//     Right Arrow
//     Down Arrow
//     Select
//
// The Arrows and the Select are only used to put the
// device to sleep, i.e. for "blind" navigation to the
// Sleep Now menu selection
//
void AppleMenu (){
  // Apple TV 'menu' signal
    irsend.sendNEC(0x77E14060, 32);
}

// ****
void AppleSleep (){
  //we have to up-up-up-up Menu,
  for (int x = 0;x<6;x++){
    irsend.sendNEC(0x77E14060, 32);  //Menu
  }
  //then right-right-right-right Arrow
  for (int x = 0;x<6;x++){
    irsend.sendNEC(0x77E1E060, 32);  //Right
  }
  //then down-down-down-down Arrow
  for (int x = 0;x<6;x++){
    irsend.sendNEC(0x77E1B060, 32);  //Down
  }
  //we should now be at "Sleep now" regardless of what was 
  // going on. 'Select' puts Apple TV to sleep
  for (int i = 0; i<3; i++){
    irsend.sendNEC(0x77E1BA60, 32);  //Select
  }
}
