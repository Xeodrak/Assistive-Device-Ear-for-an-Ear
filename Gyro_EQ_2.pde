//-----------Sound Library Funcitons
import processing.sound.*;  
SqrOsc sqr;
SoundFile file, file2, file3;
BandPass bandPass1, bandPass2, bandPass3;

//-----------OSC Library Functions (link processing and python)
import oscP5.*;
import netP5.*;
OscP5 oscP5; // enables later code to send a message to initiate data exchange from python
OscP5 oscP52; // could could send a different message to python if needed
NetAddress myRemoteLocation;


//Variables for adusting volume levels
String rawData; 
float[] gyroData; 
float[] buttonData;

//2 variables to determine what screen to display
int buttonPress;
int goToScreen;

//to prevent repeat button input for 500 milliseconds
int timeNow = 0;
int timeDelay = 500;

//to help swap between home and instruction screens every 4s
int fourSecTimer;
int toggleHome = 0;

//import background images for different screens in userflow
PImage equalizer; 
PImage homeScreen;
PImage instructionScreen;

//New fonts for interface screens
PFont latoBold;
PFont minionProMedium;

void setup() {
  size(720, 360);
  frameRate(25);
  background(255);
  equalizer = loadImage("Equalizer.jpg");
  homeScreen = loadImage("homeScreen.png");
  instructionScreen = loadImage("instructionsScreen.png");


  //Plays single tone at max volume. Without it, the RPi selects the highest level 
  //(bass/mid/trebel) and dynamically play it back at 100% volume.
  sqr = new SqrOsc(this);
  sqr.play();


  //initializing music files. 3 instances of the same song are needed because bandPass can only be applied once to a music track
  file = new SoundFile(this, "Queen & David Bowie - Under Pressure (Classic Queen Mix) (128  kbps).wav");
  file.loop();
  file2 = new SoundFile(this, "Queen & David Bowie - Under Pressure (Classic Queen Mix) (128  kbps).wav");
  file2.loop();
  file3 = new SoundFile(this, "Queen & David Bowie - Under Pressure (Classic Queen Mix) (128  kbps).wav");
  file3.loop();
  //these bandPasses will adjust the bass, mid, and trebel respectively
  bandPass1 = new BandPass(this);
  bandPass2 = new BandPass(this);
  bandPass3 = new BandPass(this);
  bandPass1.process(file);
  bandPass2.process(file2);
  bandPass3.process(file3);

  //Channel through which processing will communicate with python
  oscP5 = new OscP5(this, 1234);   
  oscP52 = new OscP5(this, 1234); 
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);

  //These 4 lines write a message which will be sent to python
  OscMessage myMessage = new OscMessage("/miklo");
  myMessage.add("1st lol");
  myMessage.add("2nd lol");
  myMessage.add("3rd lol");

  //Sends the above messages to python. When they are 
  //received, python begins sending the gyro's data to processing
  oscP5.send(myMessage, myRemoteLocation);
  print("message sent");

  //write and send a 2nd message to python. 
  //python begins sending buttonPress data in this channel
  OscMessage buttonMessage = new OscMessage("/miklokey");
  buttonMessage.add("1st haha");
  oscP52.send(buttonMessage, myRemoteLocation);
  print("sending message key");

  //to seperate pitch, roll, and yaw data from python into 3 sepereate variables
  gyroData = new float[3];
  buttonData = new float[4];

  //Initialize both fonts
  latoBold = createFont("Lato-Bold.ttf", 36);
  minionProMedium = createFont("MinionPro-Medium.otf", 20);
}


void draw() {

  //------Parses python import data into 3 variables:--------------------------------------
  //---------------pitch, roll, yaw,----------------------------------------------------
  if ((rawData != null)&&(goToScreen!=2)) {
    //raw gyro data received as a string "pitchValue, rollValue, yawValue, buttonPressNumber"
    gyroData = float(split(rawData, ','));        //splits raw data into 4 different int variables
  } 
  println(gyroData[0], gyroData[1], gyroData[2]);

  //----------Parse buttonPress data from python into an array------------------------------
  //-------that still opperates when the gyroData array is disabled----------------------
  if (rawData != null) {
    buttonData = float(split(rawData, ','));
    //println(buttonData[3]);
  }


  //----------Produces value between 0 and 2 to determine which screen to go to--------------------------------
  if ((int(buttonData[3]) == 1) && (millis() >= timeNow + timeDelay)) {  //increment up screen value if button is pushed later that 0.5s since last button press
    goToScreen = (goToScreen + 1)%3; 
    timeNow = millis(); //starts a new 0.5s delay
    println(goToScreen);
  }
  //println (goToScreen); //For debugging

  //Increases a variable by 1 every 4 seconds
  //allows screens to alternate back and forth between 2 sets of content
  fourSecTimer = int(millis()%4000);
  if ((fourSecTimer <= 350) && (millis() >= timeNow + timeDelay)) {
    toggleHome++;
    timeNow = millis();
  }

  //---------------Home Screen---------------------------------------------------------------------------------
  if (goToScreen==0) {
    //when fourSecTimer is an EVEN number, show home screen
    if (toggleHome%2 == 0) {
      background(map(gyroData[0], 90, 0, 200, 255), map(gyroData[1], 90, 0, 200, 255), map(gyroData[2], 170, 0, 200, 255));
      image(homeScreen, 0, 0);
    }
    //when fourSecTimer is an ODD number, show instructions
    if (toggleHome%2 == 1) {
      background(map(gyroData[0], 90, 0, 200, 255), map(gyroData[1], 90, 0, 200, 255), map(gyroData[2], 170, 0, 200, 255));
      image(instructionScreen, 0, 0);
    }
  }

  //----------Audio levels-adjusting screen---------------------------------------------------------------------------------
  if (goToScreen==1) {
    background(map(gyroData[0], 90, 0, 200, 255), map(gyroData[1], 90, 0, 200, 255), map(gyroData[2], 170, 0, 200, 255));
    image(equalizer, 0, 0);
    rect( 144, map(gyroData[0], 90, 0, 57, 268), 38, 20, 3);
    rect( 329, map(gyroData[1], 90, 0, 57, 268), 38, 20, 3);
    rect( 522, map(gyroData[2], 170, 0, 57, 268), 38, 20, 3);
  }


  //-----------Final Results Screens--------------------------------------------------------------------------------------------------
  if (goToScreen==2) {
    background(map(gyroData[0], 90, 0, 200, 255), map(gyroData[1], 90, 0, 200, 255), map(gyroData[2], 170, 0, 200, 255));

    //End screen for users who set bass high ---------
    if ((gyroData[0] >= 80) && (gyroData[1] <= 70) && (gyroData[2] <= 140)) {
      textAlign(CENTER, BOTTOM);
      fill(74, 74, 74);
      textFont(minionProMedium);
      text("[Press for Home Screen]", width/2, 350);
      if (toggleHome%2 == 0) {
        textFont(latoBold);      
        text("Bass Booster", width/2, 135);
        textFont(minionProMedium);
        text("You're a", width/2, 85);
        text("you like a big beat that you", width/2, 195);
        text("can feel in your chest.", width/2, 225);
        file.amp(0.5);
      }

      //when fourSecTimer is an ODD number, show instructions
      if (toggleHome%2 == 1) {
        textFont(minionProMedium);
        text("The same settings will won't", width/2, 195);
        text("feel as loud in 10 years", width/2, 225);
      }
    }
    //End screen for high treble ---------
    if ((gyroData[0] <= 70) && (gyroData[1] <= 70) && (gyroData[2] >= 155)) {
      textAlign(CENTER, BOTTOM);
      fill(74, 74, 74);
      textFont(minionProMedium);
      text("[Press for Home Screen]", width/2, 350);

      //show this page when fourSecTimer is even
      if (toggleHome%2 == 0) {
        textFont(latoBold);      
        text("Tin Ear", width/2, 135);
        textFont(minionProMedium);
        text("You're a", width/2, 85);
        text("People rarely boost high sounds.", width/2, 195);
        //file3.amp(0.5);
      }

      //when fourSecTimer is an ODD number, show this page
      if (toggleHome%2 == 1) {
        textFont(minionProMedium);
        text("You may have hearing loss in this range.", width/2, 225);
      }
    }

    //End screen for medium levels across the board ---------
    if ((gyroData[0] <= 70) && (gyroData[1] <= 70) && (gyroData[2] <= 140)) {
      textAlign(CENTER, BOTTOM);
      fill(74, 74, 74);
      textFont(minionProMedium);
      text("[Press for Home Screen]", width/2, 350);
      textFont(latoBold);      
      text("Music Lover", width/2, 135);
      textFont(minionProMedium);
      text("You're a", width/2, 85);
      text("You like to hear a balanced song,", width/2, 195);
      text("played at a safe volume.", width/2, 225);
      //file3.amp(0.5);
    }
  }



  //-------------------Sound---------------------------------------
  //plays an inaudible tone at max volume
  sqr.amp(1);
  sqr.freq(23000);
  sqr.pan(0);

  //------------------Equalizer-----------------------------------

  float bass = map(gyroData[0], 0, 90, 0.02, 1);

  bandPass1.bw(250);
  bandPass1.freq(280);
  file.amp(bass);


  float mid = map(gyroData[1], 0, 90, 0.02, 1);

  bandPass2.bw(1750);
  bandPass2.freq(2250);
  file2.amp(mid);

  float treb = map(gyroData[2], 0, 170, 0.02, 1);

  bandPass3.bw(8000);
  bandPass3.freq(12000);
  file3.amp(treb);
}



//--------------------Receive Gyro and Button Data from Python---------------------------------------------
void oscEvent(OscMessage theOscMessage) {
  rawData = theOscMessage.get(0).stringValue();
  //if (theOscMessage.checkAddrPattern("/keypressed")==true) {
  //rawButton = theOscMessage.get(0).intValue();
  //println(rawButton);
  //}
}
