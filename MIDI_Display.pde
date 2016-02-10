import themidibus.*;
import javax.sound.midi.MidiMessage; 
import java.util.Map;

MidiBus keyboard;
HashMap<Integer, Integer> MidiKeys = new HashMap<Integer, Integer>();
int midi_note, midi_press, current_beat, beats, note, beat, indicator_position, increment, begin_draw, reset_count;
float frame_rate, width_border, height_border, vertical_spacing, horizontal_spacing, side_length, radius, frame_multipler;
float beatbox_x, beatbox_y, indicator_x, indicator_y, indicator_w, indicator_h;
color beat_color_on, beat_color_off, background_color, beat_indicator_color;
boolean record_flag, reset_flag, clear_flag;
boolean [][] beat_boxes;

/*********** Configuration Parameters **************/
int midi_device = 0;  // default for Oxygen8
int desiredBPM = 90;  // set beat per minute rate
int midi_inputs = 15;  // 15 piano keys (15 rows)
int measures = 2;      // # of measures
int beat_length = 16;  // 16th notes
int screen = 1;        // display sketch on this screen

void setup() {
  fullScreen(screen);  // The size() and fullScreen() methods cannot both be used in the same program, just choose one. 
  //size(960, 540);
  init();
  background(background_color);
  frameRate(frame_rate*frame_multipler);
  MidiBus.list();
  keyboard = new MidiBus(this, midi_device, 0);
  reset();
  println(frame_rate*frame_multipler);
}  // end setup()

void draw() {
  // println(frameRate);
  increment++;
  indicator_position = increment%(int)frame_multipler;
  if (reset_flag) reset();
  else if (record_flag) {
    eraseBeatIndicator();
    if (indicator_position==0) current_beat = (current_beat+1)%beats; // increment beat count    
    record();
    drawBeatIndicator(indicator_position);
  }  // end else if
}  // end draw()

void record() {
  if (current_beat == 0) begin_draw = 0;
  else begin_draw = (current_beat-1);
  for (beat = begin_draw; beat <= current_beat; beat++) {    // only draws the current and previous column
    beatbox_x = width_border+beat*(side_length+horizontal_spacing)+side_length/2;
    for (note = 0; note < midi_inputs; note++) {    
      beatbox_y = height_border+note*(side_length+vertical_spacing)+side_length/2;
      if (beat_boxes[note][beat]) {
        fill(beat_color_on);
      }         // if beat box on, set fill to on color
      else fill(beat_color_off);                               // else, set fill to off color     
      ellipse(beatbox_x, beatbox_y, side_length, side_length);    // draw beat boxes as circles
    }  // end for
  }  // end for
}

void drawBeatIndicator(int position) {
  indicator_x = (width_border+current_beat*(side_length+horizontal_spacing)-1)+((side_length+horizontal_spacing)*(position/frame_multipler));
  indicator_y = height_border-2;
  indicator_w = side_length+2;
  indicator_h = height-(2*height_border)+4;
  fill(beat_indicator_color);
  rect(indicator_x, indicator_y, indicator_w, indicator_h, radius);
}  // end updateBeatIndicator()

void eraseBeatIndicator() {
  fill(0);
  rect(indicator_x, indicator_y, indicator_w, indicator_h, radius);
}

void reset() {
  clearScreen();
  if (record_flag && reset_flag)
    current_beat = indicator_position = increment = 0;

  else if (clear_flag && (reset_count == 2)) {
    current_beat = indicator_position = increment = 0;
    clearBeatBoxes();
    reset_count = 0;
  }

  for (note = 0; note < midi_inputs; note++) {
    for (beat = 0; beat < beats; beat++) {
      if (beat_boxes[note][beat]) {
        fill(beat_color_on);
      }         // if beat box on, set fill to on color
      else fill(beat_color_off);                               // else, set fill to off color
      ellipse(width_border+beat*(side_length+horizontal_spacing)+side_length/2, height_border+note*(side_length+vertical_spacing)+side_length/2, side_length, side_length);    // draw beat boxes as circles
    }  // end for
  }  // end for

  drawBeatIndicator(indicator_position);
  reset_flag = false;
}

void midiMessage(MidiMessage message) { 
  if (message.getMessage().length > 2) {                            // if valid data
    midi_note = (int)(message.getMessage()[1] & 0xFF);
    midi_press = (int)(message.getMessage()[2] & 0xFF);

    if (midi_press > 0) {                                           // if an "on" note
      if (MidiKeys.containsKey(midi_note)) {                        // if valid key pressed
        if (record_flag)
          beat_boxes[MidiKeys.get(midi_note)][current_beat] = true;
      }  // end if
      switch(midi_note) {
      case 49:  // C3 Sharp       
        record_flag = reset_flag = true;
        clear_flag = false;
        reset_count = 0;
        break;
      case 54:  // F3 Sharp
        ++reset_count;
        record_flag = false;
        reset_flag = clear_flag = true;        
        break;
      default:  // invalid key
        break;
      }  // end switch
    }  // end if
  }  // end if
}  // end midiMessage()

void init() {
  beats = measures * beat_length;  // # of beats displayed
  frame_rate = bpmToFrameRate(desiredBPM);
  beat = note = 0;
  beat_boxes = new boolean[midi_inputs][beats];

  // Put piano key-index position pairs in the HashMap
  MidiKeys.put(48, 14);  // C3
  MidiKeys.put(50, 13);
  MidiKeys.put(52, 12);   
  MidiKeys.put(53, 11);  
  MidiKeys.put(55, 10);  
  MidiKeys.put(57, 9);  
  MidiKeys.put(59, 8); 
  MidiKeys.put(60, 7);   // C4  
  MidiKeys.put(62, 6);   
  MidiKeys.put(64, 5); 
  MidiKeys.put(65, 4); 
  MidiKeys.put(67, 3); 
  MidiKeys.put(69, 2);  
  MidiKeys.put(71, 1);   
  MidiKeys.put(72, 0);  // C5

  width_border = height_border = 3;
  horizontal_spacing = floor(0.07*((width-(2*width_border))/((float)beats)));  // minimum horizontal spacing
  side_length = (width-(2*width_border)-((beats-1)*horizontal_spacing))/((float)beats);
  vertical_spacing = (height-(2*height_border)-(midi_inputs*side_length))/(midi_inputs-1);
  radius = 0;
  beat_color_on = color(0, 129, 196);
  beat_color_off = color(10);
  beat_indicator_color = color(50, 0, 0, 255);
  background_color = color(0);
  current_beat = indicator_position = increment = reset_count = 0;
  frame_multipler = 5;  // do not exceed
  reset_flag = record_flag = clear_flag = false;

  clearBeatBoxes();
}

float bpmToFrameRate(int bpm) {  
  return 1/(4/(beat_length*(bpm/60.0)));  // assumes 4/4 signature
}

void clearBeatBoxes() {
  for (int row = 0; row < midi_inputs; row++) {
    for (int col = 0; col < beats; col++) {
      beat_boxes[row][col] = false;
    }
  }
}

void clearScreen() {
  stroke(background_color); 
  fill(background_color);
  rect(0, 0, width, height);
}

int mod(int a, int m) {
  return ((a%m)+m)%m;
}