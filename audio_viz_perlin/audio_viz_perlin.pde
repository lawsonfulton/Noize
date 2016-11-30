import controlP5.*;
import processing.sound.*;

ControlP5 cp5;

PGraphics pg;
PGraphics trails;

SoundFile file;
AudioIn audIn;

Amplitude amp;
float smoothFactor = 0.01;
float ampSmooth = 0;

FFT fft;
AudioDevice device;
// Define how many FFT bands we want
int bands = 1024;
int scale = 5;
float r_width;
float[] sum = new float[bands];
float fft_smooth_factor = 0.25;

int frame_n = 0;

float masterNoiseScale = 1;

int n_arms = bands / 4; // ONly take upper half
int trail_count = bands / 4;
int loopCount = 4;
float gain = 1;
float trailRadius = 1;
float fade_rate = 0.05;
float pathNoiseScale = 0.002 * masterNoiseScale;
float morphNoiseScale = 0.05 * masterNoiseScale;
float colourNoiseScale = 0.4;
float intensity = 1;
float speed = 0.025;
float lineRadius = 15.0;

float [] oldx = new float[n_arms];
float [] oldy = new float[n_arms];

float [] theta = new float[n_arms];

float [] rest_length = new float[n_arms];
float [] r = new float[n_arms];

float [] armx = new float[n_arms];
float [] army = new float[n_arms];

void setup() {
  //size(800, 800);
  fullScreen();

  surface.setResizable(true);
  
  //file = new SoundFile(this, sketchPath("") + "If You Want (Original Mix).mp3");
  //file.play();
  
  // Create an Input stream which is routed into the Amplitude analyzer
  audIn = new AudioIn(this, 0);
  audIn.start();
  
  //for (int i = 0; i < bands; i++) {
  //  sum[i] = 0;
  //}
  //r_width = width/float(bands);
  fft = new FFT(this, bands);
  fft.input(audIn);

  
  pg = createGraphics(width, height);
  trails = createGraphics(width, height);
  
  trails.beginDraw();
  trails.background(0);
  trails.endDraw();
  
  noStroke();
  cp5 = new ControlP5(this);
  cp5.addSlider("pathNoiseScale")
     .setPosition(10 ,10)
     .setRange(0,0.005);
  cp5.addSlider("morphNoiseScale")
     .setPosition(10 ,40)
     .setRange(0,0.05);
  cp5.addSlider("colourNoiseScale")
     .setPosition(10 ,70)
     .setRange(0,1);
  cp5.addSlider("fade_rate")
     .setPosition(10 ,100)
     .setRange(0,0.2);
  cp5.addSlider("speed")
     .setPosition(10 ,130)
     .setRange(0,0.05);
  cp5.addSlider("trailRadius")
     .setPosition(10,160)
     .setRange(0,2);
  cp5.addSlider("loopCount")
     .setPosition(10,190)
     .setRange(1,8);
  cp5.addSlider("gain")
     .setPosition(10,220)
     .setRange(0,10);
  cp5.addSlider("lineRadius")
     .setPosition(10,250)
     .setRange(1,50);

  for(int i = 0; i < n_arms; i++) {
    oldx[i] = width/2;
    oldy[i] = height/2;
    
    theta[i] = 2 * PI * (((float)i) / ((float)n_arms));
    
    rest_length[i] = width/1.5;
    r[i] = rest_length[i]; //arm length
  }
}


void draw() {
  fft.analyze();
  
  float maxAmp = 0;
  for (int i = 0; i < bands; i++) {
    // Smooth the FFT data by smoothing factor
    sum[i] += min((fft.spectrum[i] * gain - sum[i]) * fft_smooth_factor, 1);
    maxAmp = max(sum[i], maxAmp);
    // Draw the rects with a scale factor
    //rect( i*r_width, height, r_width, -sum[i]*height*scale );
  }
  
  float ampScale = 1 + maxAmp * 5;
  float morphAmpScale = ampScale / 2;
  for(int i = 0; i < n_arms; i++) {
    float fftScale = 1.0 + sum[i] * 10;
    armx[i] = cos(theta[i]) * r[i] * fftScale;
    army[i] = sin(theta[i])* r[i] * fftScale;
    
    //Noise is symmetric so need offset
    float offset = 100;
    float noiseVal = noise(offset + armx[i]*pathNoiseScale, offset + army[i]*pathNoiseScale, theta[0] * morphNoiseScale * morphAmpScale );
    r[i] = noiseVal * rest_length[i] * intensity; 
  }           
  
  pg.beginDraw();
  pg.background(0,0,0,0);
  
  pg.strokeWeight(2);
  pg.stroke(0,100,255);
  //pg.line(width/2, height/2, armx, army);
  pg.endDraw();
  
  trails.beginDraw();
  trails.noStroke();
  trails.fill(0,0,0,fade_rate * 255);
  trails.rect(0,0,width,height);
  trails.strokeWeight(lineRadius);
  float colourAmpScale = ampScale / 15;
  float r = noise(theta[0] * colourNoiseScale * colourAmpScale) * 255;
  float g = noise(theta[0] * colourNoiseScale * colourAmpScale +1000) * 255;
  float b = noise(theta[0] * colourNoiseScale * colourAmpScale +2000 ) * 255;
  trails.stroke(r,g,b);
  if (frame_n > 2) {
    //for(int i = 0; i < trail_count; i++) {
    //  trails.line(width/2 + oldx[i], height/2 + oldy[i],width/2 + armx[i], height/2 + army[i]);
    //}
    
    float innerScale = 0.5;
    for(int j = 1; j <= loopCount; j++) {
      for(int i = 0; i < trail_count; i++) {
        trails.line(
          width/2 + trailRadius * oldx[i] * innerScale * j,
          height/2 + trailRadius * oldy[i] * innerScale * j,
          width/2 + trailRadius * armx[i] * innerScale * j,
          height/2 + trailRadius * army[i] * innerScale * j
        );
      }
    }
  }
  
  trails.endDraw();
  
  for(int i = 0; i < n_arms; i++) {
    theta[i] += speed;
  
    oldx[i] = armx[i];
    oldy[i] = army[i];
  }
  
  frame_n++;
  
  image(trails, 0, 0); 
  image(pg, 0, 0);
}