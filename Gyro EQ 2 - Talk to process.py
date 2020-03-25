import argparse
import random
import time

from pythonosc import osc_message_builder
from pythonosc import udp_client
from pythonosc import osc_server
from pythonosc import dispatcher

from sense_hat import SenseHat
sense = SenseHat()



# Local server that python and processing talk using
client = udp_client.SimpleUDPClient("127.0.0.1", 1234)

# loop sends gyro data to processing. It is activated by receiving 4 messages
#these messages are: "/miklo", "1st lol", "2nd lol", "3rd lol" 
buttonPress = 0

def sendvalues(unused_addr, message1, message2, message3):

  #print(unused_addr,"OSC ID'et")
  #print(message1,"første message")
  #print(message2,"anden message")
  #print(message2,"tredje message")
    buttonPress = 0
    while True:
  #for x in range(1000000):
        o = sense.get_gyroscope()
        pitch = o['pitch']
        yaw = o['yaw']
        roll = o['roll']

        pitch=(pitch)
    #if (pitch < 0):
     #   pitch = 
        if (pitch > 100):
           pitch = abs(pitch-360)
        if (pitch > 90):
            pitch = 90
    #print (pitch)
    
        roll=(roll)
        if (roll > 100):
            roll = abs(roll-360)
        if (roll > 90):
            roll = 90
    #print(roll)
    
        yaw=(yaw)
        if (yaw > 170):
            yaw = abs(yaw-360)
        if (yaw > 170):
            yaw = 170
    #print(yaw)
    
    #collects number of times the button was pressed

        for event in sense.stick.get_events():
            if event.action == "pressed":
                buttonPress = 1
                print(buttonPress)
            #time.sleep(0.3)     #these 2 lines prevent
            #buttonPress = 0     #holding the button from causing repeat inputs
            if event.action == "released":
                buttonPress = 0
                print(buttonPress)
    
        client.send_message("/mousepressed", "{},{},{},{}".format(pitch, roll, yaw, buttonPress))
        time.sleep(0.001)
    #if x == 100000000:
     # break


#def sendothervalues(unused_addr, message1):


    #buttonPress = 0

   # while True:
  #print(unused_addr,"OSC ID'et")
  #print(message1,"første message")
    #collects number of times the button was pressed
       # for event in sense.stick.get_events():
            #if event.action == "pressed":
             #   buttonPress = 1
              #  print(buttonPress)
            #if event.action == "released":
             #   buttonPress = 0
              #  print(buttonPress)
    
        #client.send_message("/keypresses", "{}".format(buttonPress))
        #time.sleep(0.1)
  #client.send_message("/keypressed", "vuf")

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("--ip", default="127.0.0.1",
      help="The ip of the OSC server")
  parser.add_argument("--port", type=int, default=5005,
      help="The port the OSC server is listening on")
  args = parser.parse_args()

  dispatcher = dispatcher.Dispatcher()

  # when processing receives either /miklo or /miklokey from processing,
  # it activates functions which send data constantly
  dispatcher.map("/miklo",sendvalues)
  #dispatcher.map("/miklokey",sendothervalues)

  
  server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), dispatcher)

  print("Serving on {}".format(server.server_address))
  server.serve_forever()
