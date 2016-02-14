import themidibus.*;
import javax.sound.midi.MidiMessage; 
import java.util.Map;

MidiBus keyboard;
HashMap<Integer, Integer> MidiKeys = new HashMap<Integer, Integer>();
int midi_note, midi_press, current_beat, last_beat, beats, note, draw_beat, indicator_position, increment, start_beat, end_beat, reset_count;
float frame_rate, page_width_border, page_height_border, vertical_spacing, horizontal_spacing, rect_width, rect_height, radius, frame_multiplier;
float beatbox_x, beatbox_y, indicator_x, indicator_y, indicator_w, indicator_h;
color beat_color_on, beat_color_off, background_color, beat_indicator_color;
boolean record_flag, reset_flag, clear_flag;
boolean [][] beat_boxes;

/*********** Configuration Parameters **************/
int midi_device = 0;  // default for Oxygen8
int desiredBPM = 140;  // set beat per minute rate
int midi_inputs = 15;  // 15 piano keys (15 rows)
int measures = 2;      // # of measures
int beat_length = 16;  // 8th or 16th notes
int screen = 2;        // display sketch on this screen

void setup() {
  //fullScreen(screen);  // The size() and fullScreen() methods cannot both be used in the same program, just choose one. 
  size(960, 540);
  init();
  background(background_color);
  frameRate(frame_rate*frame_multiplier);
  MidiBus.list();
  keyboard = new MidiBus(this, midi_device, 0);
  reset();
  println(frame_rate*frame_multiplier);
}  // end setup()

void draw() {
  increment++;
  indicator_position = increment%(int)frame_multiplier;
  if (reset_flag) reset();
  else if (record_flag) {
    eraseBeatIndicator();
    if (indicator_position==0) {
      current_beat = (current_beat+1)%beats;
    } // increment beat count    
    record();
    drawBeatIndicator(indicator_position);
  }  // end else if
}  // end draw()

void record() {
  if (current_beat > (beats-2)) {
    start_beat = beats-2;
    end_beat = start_beat+1;
  } else if (indicator_position == 0) {
    start_beat = last_beat;
  } else {
    start_beat = current_beat;
  }

  end_beat = start_beat+1;
  eraseBeat(start_beat);  
  eraseBeat(end_beat);
  for (draw_beat = start_beat; draw_beat <= end_beat; draw_beat++) {    // only draws the current and previous column
    beatbox_x = page_width_border+draw_beat*(rect_width+horizontal_spacing);
    for (note = 0; note < midi_inputs; note++) {    
      beatbox_y = page_height_border+note*(rect_height+vertical_spacing);
      if (beat_boxes[note][draw_beat]) {
        fill(beat_color_on);
      }         // if beat box on, set fill to on color
      else fill(beat_color_off);                               // else, set fill to off color     
      rect(beatbox_x, beatbox_y, rect_width, rect_height, radius);    // draw beat boxes as rectangles
    }  // end for
  }  // end for
  last_beat = start_beat;
}

void drawBeatIndicator(int position) {
  indicator_x = (page_width_border+current_beat*(rect_width+horizontal_spacing)-1)+((rect_width+horizontal_spacing)*(position/frame_multiplier));
  indicator_y = page_height_border-2;
  indicator_w = rect_width+2;
  indicator_h = height-(2*page_height_border)+4;
  noStroke(); 
  fill(beat_indicator_color);
  rect(indicator_x, indicator_y, indicator_w, indicator_h, radius);
}  // end updateBeatIndicator()

void eraseBeatIndicator() {
  noStroke(); 
  fill(background_color);
  rect(indicator_x, indicator_y, indicator_w, indicator_h, radius);
}

void reset() {
  clearScreen();
  if (record_flag && reset_flag) {
    current_beat = indicator_position = increment = 0;
  } else if (clear_flag && (reset_count == 2)) {
    current_beat = indicator_position = increment = 0;
    clearBeatBoxes();
    reset_count = 0;
  }
  for (note = 0; note < midi_inputs; note++) {
    for (draw_beat = 0; draw_beat < beats; draw_beat++) {
      if (beat_boxes[note][draw_beat]) {
        fill(beat_color_on);
      }         // if beat box on, set fill to on color
      else fill(beat_color_off);                               // else, set fill to off color
      rect(page_width_border+draw_beat*(rect_width+horizontal_spacing), page_height_border+note*(rect_height+vertical_spacing), rect_width, rect_height, radius);    // draw beat boxes as rectangles
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
      case 49:  // C3 Sharp for Record
        record_flag = reset_flag = true;
        clear_flag = false;
        reset_count = 0;
        break;
      case 54:  // F3 Sharp for Reset
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
  draw_beat = note = 0;
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

  page_width_border = page_height_border = 3;
  horizontal_spacing = floor(0.1*((width-(2*page_width_border))/((float)beats)));  // minimum horizontal spacing
  vertical_spacing = floor(0.1*((height-(2*page_height_border))/((float)midi_inputs)));  // minimum horizontal spacing
  rect_width = (width-(2*page_width_border)-((beats-1)*horizontal_spacing))/((float)beats);
  rect_height = (height-(2*page_height_border)-((midi_inputs-1)*vertical_spacing))/((float)midi_inputs);
  radius = 5;
  beat_color_on = color(0, 129, 196);
  beat_color_off = color(10);
  beat_indicator_color = color(255, 0, 0, 50);
  background_color = color(0);
  current_beat = last_beat = indicator_position = increment = reset_count = 0;
  frame_multiplier = 10;  // do not exceed
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

void eraseBeat(int beat) {
  fill(background_color);
  rect(page_width_border+beat*(rect_width+horizontal_spacing)-1, page_height_border-2, rect_width+2, height-(2*page_height_border)+4, radius);    // draw beat boxes as rectangles
}

void clearScreen() {
  background(background_color);
}

int mod(int a, int m) {
  return ((a%m)+m)%m;
}